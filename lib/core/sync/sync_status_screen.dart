import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
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
