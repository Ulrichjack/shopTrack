import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/sync/sync_service.dart';
import '../../../../shared/widgets/product_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/user_shops_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/stock_transfer_provider.dart';
import '../../../../core/providers/current_shop_provider.dart';

/// Ce qui circule entre les boutiques du patron.
///
/// Deux listes plutôt qu'une : ce qu'on a envoyé et qu'on attend de voir
/// confirmé, et ce qu'on a reçu et qu'il faut vérifier. Le geste attendu n'est
/// pas le même des deux côtés.
class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferts = ref.watch(stockTransfersProvider);
    final boutiques = ref.watch(userShopsProvider).value ?? const <UserShop>[];
    final nomDe = {for (final b in boutiques) b.id: b.name};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transferts')),
      floatingActionButton: boutiques.length < 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _ouvrirEnvoi(context, ref, boutiques),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Envoyer'),
            ),
      body: SafeArea(
        child: transferts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(humanSyncError(e), textAlign: TextAlign.center),
            ),
          ),
          data: (liste) {
            if (liste.isEmpty) {
              return const _Vide();
            }
            final aVerifier = liste
                .where((t) => !t.estEnvoi && !t.estConfirme && !t.estAnnule)
                .toList();
            final reste = liste.where((t) => !aVerifier.contains(t)).toList();

            return RefreshIndicator(
              // La liste ne lit que la base LOCALE : invalider ne redemande
              // rien au serveur. Sans ce geste, un patron qui envoie et
              // l'autre boutique qui confirme ne se voyaient jamais mis à
              // jour l'un l'autre en restant simplement sur cet écran — il
              // fallait qu'un téléchargement se déclenche PAR AILLEURS
              // (réseau qui revient, tableau de bord ouvert).
              onRefresh: () async {
                await ref.read(syncServiceProvider).synchronize();
                ref.invalidate(stockTransfersProvider);
              },
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                // Ce qui attend un geste passe en premier : c'est la seule
                // chose que le commerçant doit faire en ouvrant cet écran.
                if (aVerifier.isNotEmpty) ...[
                  const _Titre('À VÉRIFIER'),
                  for (final t in aVerifier)
                    _Ligne(entree: t, nomDe: nomDe, aVerifier: true),
                  const SizedBox(height: 24),
                ],
                const _Titre('HISTORIQUE'),
                for (final t in reste)
                  _Ligne(entree: t, nomDe: nomDe, aVerifier: false),
              ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _ouvrirEnvoi(
    BuildContext context,
    WidgetRef ref,
    List<UserShop> boutiques,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FeuilleEnvoi(boutiques: boutiques),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texte,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _Ligne extends ConsumerWidget {
  const _Ligne({
    required this.entree,
    required this.nomDe,
    required this.aVerifier,
  });

  final TransferEntry entree;
  final Map<String, String> nomDe;
  final bool aVerifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autre = nomDe[entree.autreBoutique] ?? 'Autre boutique';
    final quand = DateFormat('dd/MM').format(entree.transfer.transferredAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        // Toucher la ligne ouvre le détail — le bouton « Reçu » à droite
        // reste le raccourci rapide, les deux mènent au même geste.
        onTap: () => context.push('/transfer-detail', extra: entree),
        leading: Icon(
          entree.estAnnule
              ? Icons.block
              : (entree.estEnvoi ? Icons.north_east : Icons.south_west),
          color: entree.estAnnule
              ? Colors.grey
              : (entree.estEnvoi ? AppColors.error : AppColors.primaryDark),
        ),
        title: Text(
          entree.productName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: entree.estAnnule
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: entree.estAnnule ? Colors.grey.shade600 : null,
          ),
        ),
        subtitle: Text(
          entree.estAnnule
              ? 'Annulé · $quand'
              : '${entree.estEnvoi ? 'Vers' : 'De'} $autre · $quand'
                    '${entree.manquant > 0 ? ' · ${entree.manquant} perdu(s) en route' : ''}',
        ),
        trailing: aVerifier
            ? FilledButton(
                onPressed: () => _confirmer(context, ref),
                child: const Text('Reçu'),
              )
            : entree.estAnnule
            ? null
            : Text(
                '${entree.transfer.receivedQuantity ?? entree.transfer.quantity}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmer(BuildContext context, WidgetRef ref) async {
    // Le conteneur plutôt que `ref` : cette ligne de liste peut être
    // reconstruite pendant que la boîte est ouverte (une synchro suffit), et
    // un `ref` de widget détruit lève « Cannot use ref after the widget was
    // disposed ».
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final controleur = TextEditingController(
      text: '${entree.transfer.quantity}',
    );
    final quantite = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entree.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entree.transfer.quantity} envoyé(s). Combien reçu ?'),
            const SizedBox(height: 12),
            TextField(
              controller: controleur,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controleur.text.trim())),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (quantite == null) return;
    try {
      await conteneur
          .read(stockTransferActionsProvider)
          .confirmerReception(
            transferId: entree.transfer.id,
            receivedQuantity: quantite,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _FeuilleEnvoi extends ConsumerStatefulWidget {
  const _FeuilleEnvoi({required this.boutiques});
  final List<UserShop> boutiques;

  @override
  ConsumerState<_FeuilleEnvoi> createState() => _FeuilleEnvoiState();
}

class _FeuilleEnvoiState extends ConsumerState<_FeuilleEnvoi> {
  final _formKey = GlobalKey<FormState>();
  final _quantite = TextEditingController();
  ProductEntity? _produit;
  String? _destination;
  bool _envoi = false;

  @override
  void dispose() {
    _quantite.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await ref
          .read(stockTransferActionsProvider)
          .envoyer(
            productId: _produit!.id,
            toShopId: _destination!,
            quantity: int.parse(_quantite.text.trim()),
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final produits = ref.watch(productProvider).value ?? const [];
    final active = ref.watch(userShopsProvider).value ?? const <UserShop>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Envoyer vers une autre boutique',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Le sélecteur partagé, comme partout ailleurs : une liste
              // déroulante native tronque les noms longs, n'a pas de recherche
              // et oblige à parcourir tout le catalogue. Cet écran était le
              // dernier à ne pas l'utiliser.
              ProductPicker(
                selectedProductId: _produit?.id,
                onChanged: (value) => setState(
                  () => _produit = produits.firstWhere((p) => p.id == value),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _destination,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vers quelle boutique',
                  border: OutlineInputBorder(),
                ),
                // La boutique courante n'a rien à faire dans la liste : on ne
                // s'envoie pas de la marchandise à soi-même.
                items: widget.boutiques
                    .where((b) => b.id != ref.watch(currentShopIdProvider).value)
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _destination = value),
                validator: (value) =>
                    value == null ? 'Choisis la destination' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantite,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Combien ?',
                  helperText: _produit == null
                      ? null
                      : 'Maximum ${_produit!.quantity}',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final n = int.tryParse((value ?? '').trim());
                  if (n == null || n <= 0) return 'Saisis un nombre positif';
                  if (_produit != null && n > _produit!.quantity) {
                    return 'Pas plus de ${_produit!.quantity}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Le stock part tout de suite, avant même la confirmation de
              // l'autre côté : la marchandise a quitté l'étagère.
              Text(
                'Le stock de cette boutique baisse immédiatement. '
                'L\'autre boutique confirmera ce qu\'elle reçoit.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _envoi || active.length < 2 ? null : _envoyer,
                child: _envoi
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Envoyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Aucun transfert. Utilise le bouton pour envoyer de la marchandise '
        'vers une autre boutique.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade700, height: 1.4),
      ),
    ),
  );
}
