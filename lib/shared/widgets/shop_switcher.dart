import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/current_shop_provider.dart';
import '../../core/providers/shop_settings_provider.dart';
import '../../core/providers/user_shops_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/products/presentation/providers/product_provider.dart';

/// Bascule entre les boutiques du patron.
///
/// **Réservé au mode Patron**, comme le bilan : un vendeur n'a aucune raison
/// de voir le stock d'une autre boutique, et encore moins d'y écrire. Tant
/// qu'un compte n'a qu'une boutique, rien ne s'affiche — il n'y a rien à
/// choisir, et un menu à une entrée n'est que du bruit.
class ShopSwitcher extends ConsumerWidget {
  const ShopSwitcher({super.key, required this.repli});

  /// Ce qu'affiche la barre quand il n'y a rien à choisir : le titre habituel.
  final Widget repli;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estPatron = ref.watch(appModeProvider).value ?? false;
    if (!estPatron) return repli;

    final boutiques = ref.watch(userShopsProvider).value ?? const <UserShop>[];
    // Rien à choisir : on garde le titre. Créer une boutique se fait dans les
    // réglages — un geste rare n'a pas sa place dans un menu qu'on ouvre tous
    // les jours pour basculer.
    if (boutiques.length < 2) return repli;

    final active = ref.watch(currentShopIdProvider).value;

    return PopupMenuButton<String>(
      tooltip: 'Boutiques',
      onSelected: (id) => _changer(context, ref, boutiques, id),
      itemBuilder: (context) => [
        for (final boutique in boutiques)
          PopupMenuItem(
            value: boutique.id,
            child: Row(
              children: [
                Icon(
                  boutique.id == active
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(boutique.name)),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              boutiques
                  .firstWhere(
                    (boutique) => boutique.id == active,
                    orElse: () => boutiques.first,
                  )
                  .name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Future<void> _changer(
    BuildContext context,
    WidgetRef ref,
    List<UserShop> boutiques,
    String id,
  ) async {
    if (id == ref.read(currentShopIdProvider).value) return;

    // On passe par le conteneur, pas par `ref` : changer de boutique
    // reconstruit la barre de titre, donc DÉTRUIT ce widget au milieu de la
    // méthode. Le `ref` d'un widget disparu lève « Cannot use ref after the
    // widget was disposed », et les invalidations suivantes ne partaient pas.
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final choisie = boutiques.firstWhere((boutique) => boutique.id == id);

    await conteneur.read(currentShopIdProvider.notifier).select(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_shop_name', choisie.name);

    // Tout ce qui dépend de la boutique repart de zéro. Oublier un seul de ces
    // providers laisserait un écran sur l'ancienne boutique — le stock d'une
    // épicerie affiché sous le nom d'une autre.
    conteneur.invalidate(shopSettingsProvider);
    conteneur.invalidate(productProvider);
    conteneur.invalidate(dashboardProvider);

    // Les données de la nouvelle boutique ne sont peut-être pas encore
    // descendues : on va les chercher tout de suite.
    unawaited(conteneur.read(syncServiceProvider).pullDataFromSupabase());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boutique : ${choisie.name}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

/// Le changement de boutique ne doit pas attendre la fin du téléchargement :
/// l'écran affiche déjà le cache local de la nouvelle boutique.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}

/// Ouvre la création d'une boutique. Vit ici parce que le sélecteur en est le
/// voisin naturel, mais s'appelle depuis les réglages : créer une boutique est
/// un geste rare, il n'a pas sa place dans un menu quotidien.
Future<void> ouvrirCreationBoutique(BuildContext context, WidgetRef ref) async {
  // Même précaution que pour la bascule : l'écran qui a ouvert la boîte peut
  // avoir disparu au moment où la création se termine.
  final conteneur = ProviderScope.containerOf(context, listen: false);
  final controleur = TextEditingController();
  final nom = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nouvelle boutique'),
      content: TextField(
        controller: controleur,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nom de la boutique',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controleur.text),
          child: const Text('Créer'),
        ),
      ],
    ),
  );
  if (nom == null || nom.trim().isEmpty) return;

  try {
    await conteneur.read(shopCreationProvider).creer(nom);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boutique « ${nom.trim()} » créée.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    }
  }
}
