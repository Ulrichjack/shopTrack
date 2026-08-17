import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_service.dart';

/// Prévient qu'une opération refusée par le serveur bloque l'envoi.
///
/// Sans ce bandeau, le seul signe était un compteur d'opérations en attente
/// qui ne descendait plus — invisible pour qui ne va pas le regarder. Le
/// commerçant continuait de vendre pendant des jours en croyant que tout
/// remontait.
class BlockedSyncBanner extends ConsumerWidget {
  const BlockedSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloquees = ref.watch(syncStatusProvider).value?.blockedCount ?? 0;
    if (bloquees == 0) return const SizedBox.shrink();

    return Material(
      color: Colors.red.shade700,
      child: InkWell(
        onTap: () => context.push('/sync-status'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.sync_problem, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bloquees == 1
                      ? '1 opération refusée bloque la synchronisation'
                      : '$bloquees opérations refusées bloquent la '
                            'synchronisation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text(
                'Voir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
