import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../database/app_database.dart';
import '../errors/sync_error_message.dart';
import 'sync_service.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    final status = statusAsync.value ?? const SyncStatus.initial();
    final syncing =
        status.phase == SyncPhase.sending ||
        status.phase == SyncPhase.downloading;

    return Scaffold(
      appBar: AppBar(title: const Text('État de synchronisation')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).synchronize(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      status.phase == SyncPhase.error
                          ? Icons.sync_problem
                          : syncing
                          ? Icons.sync
                          : Icons.cloud_done_outlined,
                      size: 64,
                      color: status.phase == SyncPhase.error
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _phaseLabel(status.phase),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${status.pendingCount} opération(s) en attente',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (status.blockedCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'dont ${status.blockedCount} refusée(s) par le serveur',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (status.lastSyncAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dernière réussite : ${DateFormat('dd/MM/yyyy HH:mm').format(status.lastSyncAt!)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (status.lastError != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dernière erreur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(humanSyncError(status.lastError)),
                      const SizedBox(height: 12),
                      // Le message brut reste accessible pour le support,
                      // mais replié : il n'aide pas le commerçant.
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: const Text(
                          'Détail technique',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        children: [
                          SelectableText(
                            status.lastError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (status.blockedCount > 0) ...[
              const SizedBox(height: 16),
              const _BlockedSection(),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: syncing
                  ? null
                  : () async {
                      try {
                        await ref.read(syncServiceProvider).synchronize();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Synchronisation terminée.'),
                            ),
                          );
                        }
                      } catch (_) {
                        // Le détail est conservé dans l'état de synchronisation.
                      }
                    },
              icon: syncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Synchroniser maintenant'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ne vous déconnectez pas tant que des opérations restent en attente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(SyncPhase phase) => switch (phase) {
    SyncPhase.idle => 'Prêt à synchroniser',
    SyncPhase.sending => 'Envoi des modifications…',
    SyncPhase.downloading => 'Téléchargement des données…',
    SyncPhase.success => 'Données synchronisées',
    SyncPhase.error => 'Synchronisation incomplète',
  };
}

/// Les opérations refusées, nommées et décidables.
///
/// Deux sorties, et pas une de plus : réessayer — l'erreur venait du serveur
/// et elle est corrigée — ou abandonner l'envoi de celle qui coince. Sans ces
/// deux boutons, la seule issue était de réinstaller l'application, donc de
/// perdre tout ce qui n'était pas encore parti.
class _BlockedSection extends ConsumerWidget {
  const _BlockedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(blockedSyncItemsProvider);
    final items = itemsAsync.value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opérations bloquées',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le serveur les a refusées plusieurs fois. Elles sont mises de '
              'côté : rien n\'est perdu, mais rien ne repart tant qu\'elles '
              'sont là.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              _BlockedTile(item: item),
              const Divider(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.read(syncServiceProvider).retryBlocked(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Tout réessayer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.item});

  final SyncQueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _actionLabel(item.action),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => _confirmDiscard(context, ref),
              child: const Text(
                'Abandonner',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
        Text(
          'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(item.createdAt)}'
          ' · ${item.attempts} tentative(s)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (item.lastError != null) ...[
          const SizedBox(height: 4),
          Text(
            humanSyncError(item.lastError),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner cet envoi ?'),
        content: Text(
          '« ${_actionLabel(item.action)} » ne sera plus envoyée au serveur. '
          'Elle reste visible sur ce téléphone, mais les autres téléphones ne '
          'la verront jamais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    await ref.read(syncServiceProvider).discardBlocked(item.id);
  }
}

String _actionLabel(String action) => switch (action) {
  'CREATE_SALE' => 'Une vente',
  'ADD_CASH_MOVEMENT' => 'Un mouvement de caisse',
  'ADD_PRODUCT' => 'La création d\'un produit',
  'UPDATE_PRODUCT' => 'La modification d\'un produit',
  'DELETE_PRODUCT' => 'La suppression d\'un produit',
  'ADD_STOCK' => 'Un ajout de stock',
  'ADD_CLOSING' => 'Une clôture de journée',
  'SET_SHOP_SETTINGS' => 'Un réglage de la boutique',
  'ADD_SHOP_TAKINGS' => 'Une recette du jour',
  'ADD_INVENTORY_COUNT' => 'Un comptage de stock',
  'ADD_INVENTORY_LOSS' => 'Une perte déclarée',
  'ADD_STOCK_PURCHASE' => 'Un arrivage',
  'ADD_PRODUCT_PRICE' => 'Un changement de prix',
  'ADD_STOCK_TRANSFER' => 'Un transfert entre boutiques',
  'CONFIRM_STOCK_TRANSFER' => 'La réception d\'un transfert',
  'ADD_SUPPLY_CYCLE' => 'Un cycle d\'approvisionnement',
  'CLOSE_SUPPLY_CYCLE' => 'La clôture d\'un cycle',
  'ADD_PRODUCT_UNIT' => 'Une unité de vente',
  'DELETE_PRODUCT_UNIT' => 'La suppression d\'une unité',
  'ADD_CYCLE_LOSS' => 'Une perte de cycle',
  _ => action,
};
