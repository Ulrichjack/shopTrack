import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/providers/employees_provider.dart';
import '../../../../core/providers/shop_settings_provider.dart';
import '../../../../core/providers/user_shops_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

/// La clé qui dit quel compte utilisait ce téléphone la dernière fois.
const cleCompteMemorise = 'cached_user_id';

/// Le dernier numéro qui s'est connecté sur ce téléphone.
///
/// Sert à le pré-remplir : sur un téléphone de boutique, c'est toujours le
/// même compte qui revient, et retaper neuf chiffres à chaque ouverture n'a
/// aucun intérêt. Seul le mot de passe reste à saisir — c'est lui qui protège.
const cleDernierNumero = 'dernier_numero';

/// Tout ce qu'il faut faire une fois l'authentification réussie.
///
/// Écrit une seule fois, parce que les deux écrans l'oubliaient différemment :
/// la connexion faisait le ménage, l'inscription **rien du tout**. Un
/// commerçant qui créait un second compte sur le même téléphone gardait la
/// boutique active du compte précédent. L'application cherchait alors son rôle
/// dans une boutique qui n'était pas la sienne, ne l'y trouvait pas, et le
/// laissait en **mode vendeur sur sa propre boutique**. La base locale, elle,
/// gardait les produits et les ventes de l'autre compte.
///
/// [inscription] vaut vrai quand le compte vient d'être créé. Un compte neuf
/// n'a par définition aucune donnée locale à préserver : on nettoie sans
/// condition. À la connexion en revanche, on ne nettoie que si le compte a
/// changé — vider la base d'un commerçant hors ligne lui ferait perdre les
/// ventes que la file d'attente n'a pas encore envoyées.
Future<void> prendreEnMainLaSession(
  WidgetRef ref, {
  required bool inscription,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final actuel = Supabase.instance.client.auth.currentUser?.id;
  final precedent = prefs.getString(cleCompteMemorise);

  final autreCompte =
      inscription ||
      (actuel != null && precedent != null && precedent != actuel);

  // Premier compte ouvert sur cet appareil : rien à effacer, mais TOUT à
  // télécharger.
  //
  // Le rechargement ne se déclenchait qu'au changement de compte. Sur un
  // téléphone neuf il n'y a pas de compte précédent, donc pas de changement,
  // donc aucun téléchargement : le commerçant se connectait et trouvait une
  // application vide, avec son stock bien présent sur le serveur. Vu sur un
  // appareil vierge le 18/08/2026 — c'est-à-dire le cas de CHAQUE nouvelle
  // installation chez un client.
  final premierCompteDeCetAppareil = actuel != null && precedent == null;

  if (autreCompte) {
    // Un AUTRE compte ne doit jamais hériter des données du précédent : sur un
    // téléphone partagé, ce serait le stock d'une boutique affiché à quelqu'un
    // qui n'y a pas accès.
    await ref.read(localDbProvider).clearAllData();
    await prefs.remove(cachedShopIdKey);
    await prefs.remove('cached_shop_name');
    await prefs.remove('cached_is_owner');
  }

  // Mémorisé ICI, au moment où la session s'ouvre.
  //
  // Cette écriture vivait dans le tableau de bord — donc jamais exécutée en
  // mode inventaire, qui a son propre accueil, ni quand l'accueil n'arrivait
  // pas à s'afficher. La clé restait vide, le ménage ci-dessus comparait
  // `null` au compte courant, concluait « même compte » et ne nettoyait rien.
  // Le changement de compte passait alors totalement inaperçu.
  if (actuel != null) {
    await prefs.setString(cleCompteMemorise, actuel);
  }

  // TOUT ce qui dépend du compte doit repartir de zéro. Vider les préférences
  // ne suffit pas : un provider garde sa valeur en mémoire. Sans ces
  // invalidations, la liste des boutiques du compte PRÉCÉDENT restait chargée
  // — un vendeur héritait des boutiques de son patron, donc de son rôle.
  ref.invalidate(currentShopIdProvider);
  ref.invalidate(userShopsProvider);
  ref.invalidate(estProprietaireProvider);
  ref.invalidate(appModeProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(productProvider);
  // Le mode de la boutique aussi : il se lit depuis `cached_shop_id`, écrit
  // pendant la connexion. Sans cette invalidation, le provider gardait les
  // valeurs par défaut calculées avant que la boutique soit connue — le
  // commerçant retrouvait le mode simple et devait réactiver son module à
  // chaque connexion.
  ref.invalidate(shopSettingsProvider);

  // Il faut remplir la base AVANT d'afficher l'accueil, sinon le commerçant
  // arrive sur une app vide et croit avoir tout perdu. On attend ici, une
  // seule fois : au changement de compte, ou à la première ouverture sur cet
  // appareil.
  //
  // En revenant sur son propre compte, rien n'a été vidé : on n'attend pas,
  // l'entrée reste instantanée et marche hors ligne.
  if (autreCompte || premierCompteDeCetAppareil) {
    try {
      await ref.read(syncServiceProvider).synchronize();
    } catch (_) {
      // Hors ligne : on entre quand même. La synchro repartira au retour du
      // réseau — bloquer la connexion serait pire.
    }
  }
}
