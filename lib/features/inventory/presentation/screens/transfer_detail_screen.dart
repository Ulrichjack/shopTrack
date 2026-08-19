import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/sync_error_message.dart';
import '../../../../core/providers/user_shops_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/stock_transfer_provider.dart';

/// Le détail d'un transfert — sur le même principe que la fiche produit :
/// des cartes blanches, une information par ligne, rien à deviner.
///
/// Reçoit l'entrée déjà chargée par la liste (state.extra) plutôt qu'un
/// identifiant à retélécharger : elle vient d'être affichée, la redemander
/// ferait clignoter l'écran pour rien.
class TransferDetailScreen extends ConsumerWidget {
  const TransferDetailScreen({super.key, required this.entree});

  final TransferEntry entree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boutiques = ref.watch(userShopsProvider).value ?? const [];
    final nomDe = {for (final b in boutiques) b.id: b.name};
    final de = nomDe[entree.transfer.fromShopId] ?? 'Boutique inconnue';
    final vers = nomDe[entree.transfer.toShopId] ?? 'Boutique inconnue';
    final t = entree.transfer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(entree.productName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Statut(entree: entree),
            const SizedBox(height: 16),
            _Carte(
              titre: 'Le mouvement',
              lignes: [
                _ligne('Produit', entree.productName),
                _ligne('Quantité envoyée', '${t.quantity} ${t.unit ?? ''}'),
                if (entree.estConfirme)
                  _ligne(
                    'Quantité reçue',
                    '${t.receivedQuantity} ${t.unit ?? ''}',
                    accent: entree.manquant > 0 ? AppColors.error : null,
                  ),
                if (entree.manquant > 0)
                  _ligne(
                    'Perdu en route',
                    '${entree.manquant} ${t.unit ?? ''}',
                    accent: AppColors.error,
                  ),
                _ligne('De', de),
                _ligne('Vers', vers),
              ],
            ),
            const SizedBox(height: 12),
            _Carte(
              titre: 'Les dates',
              lignes: [
                _ligne(
                  'Envoyé le',
                  DateFormat('dd/MM/yyyy à HH:mm').format(t.transferredAt),
                ),
                _ligne(
                  'Reçu le',
                  t.receivedAt == null
                      ? 'Pas encore'
                      : DateFormat('dd/MM/yyyy à HH:mm').format(t.receivedAt!),
                ),
                if (entree.estAnnule)
                  _ligne(
                    'Annulé le',
                    DateFormat('dd/MM/yyyy à HH:mm').format(t.cancelledAt!),
                    accent: Colors.grey.shade700,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Le prix d'achat retenu est celui du jour de l'envoi, pas le
            // prix actuel du produit — comme sur une ligne de vente : ce
            // qu'on a payé ne bouge pas si le tarif change ensuite.
            _Carte(
              titre: "Ce que ça a coûté",
              lignes: [
                if (t.buyPrice != null)
                  _ligne(
                    'Prix d\'achat retenu',
                    '${CurrencyFormatter.format(t.buyPrice!)} / ${t.unit ?? 'unité'}',
                  ),
                _ligne(
                  'Valeur totale',
                  CurrencyFormatter.format(entree.valeurAchat),
                  gras: true,
                ),
              ],
            ),
            if (t.note != null && t.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _Carte(titre: 'Note', lignes: [_ligne(null, t.note!)]),
            ],
            const SizedBox(height: 24),
            if (!entree.estEnvoi && !entree.estConfirme && !entree.estAnnule)
              FilledButton.icon(
                onPressed: () => _confirmer(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('Confirmer la réception'),
              ),
            if (entree.estAnnulable) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _annuler(context, ref),
                icon: const Icon(Icons.undo),
                label: const Text('Annuler ce transfert'),
              ),
              const SizedBox(height: 8),
              Text(
                'Rend le stock à ta boutique. Possible tant que '
                '$vers n\'a rien confirmé.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({String? label, String valeur, Color? accent, bool gras}) _ligne(
    String? label,
    String valeur, {
    Color? accent,
    bool gras = false,
  }) => (label: label, valeur: valeur, accent: accent, gras: gras);

  Future<void> _confirmer(BuildContext context, WidgetRef ref) async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final controleur = TextEditingController(text: '${entree.transfer.quantity}');
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
                Navigator.pop(context, int.tryParse(controleur.text)),
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
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanSyncError(e))),
        );
      }
    }
  }

  Future<void> _annuler(BuildContext context, WidgetRef ref) async {
    final conteneur = ProviderScope.containerOf(context, listen: false);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler ce transfert ?'),
        content: Text(
          '${entree.transfer.quantity} ${entree.productName} reviennent '
          'dans ton stock. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler le transfert'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      await conteneur.read(stockTransferActionsProvider).annuler(entree);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanSyncError(e))),
        );
      }
    }
  }
}

class _Statut extends StatelessWidget {
  const _Statut({required this.entree});

  final TransferEntry entree;

  @override
  Widget build(BuildContext context) {
    final (String texte, Color couleur, IconData icone) = entree.estAnnule
        ? ('Annulé', Colors.grey.shade600, Icons.block)
        : entree.estConfirme
        ? (
            entree.manquant > 0 ? 'Reçu avec un manquant' : 'Reçu en entier',
            entree.manquant > 0 ? AppColors.error : AppColors.primaryDark,
            Icons.check_circle,
          )
        : entree.estEnvoi
        ? ('En attente de réception', AppColors.warningDark, Icons.schedule)
        : ('À vérifier', AppColors.warningDark, Icons.priority_high);

    final fond = entree.estAnnule
        ? Colors.grey.shade200
        : entree.estConfirme && entree.manquant == 0
        ? AppColors.success
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur),
          const SizedBox(width: 12),
          Text(
            texte,
            style: TextStyle(fontWeight: FontWeight.bold, color: couleur),
          ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({required this.titre, required this.lignes});

  final String titre;
  final List<({String? label, String valeur, Color? accent, bool gras})>
  lignes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          for (final l in lignes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: l.label == null
                  ? Text(l.valeur)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l.label!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        Text(
                          l.valeur,
                          style: TextStyle(
                            fontWeight: l.gras
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: l.accent ?? AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
