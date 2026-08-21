import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../sync/sync_service.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  Future<List<_Activity>> _load(WidgetRef ref) async {
    final db = ref.read(localDbProvider);
    final activities = <_Activity>[];

    for (final sale in await db.select(db.localSales).get()) {
      activities.add(
        _Activity(
          date: sale.createdAt,
          title: 'Vente enregistrée',
          detail: '${sale.totalAmount.toStringAsFixed(0)} FCFA',
          userId: sale.userId,
          icon: Icons.point_of_sale,
        ),
      );
    }
    for (final movement in await db.select(db.localCashMovements).get()) {
      activities.add(
        _Activity(
          date: movement.createdAt,
          title: movement.type == 'morning_balance'
              ? 'Solde du matin'
              : 'Mouvement de caisse',
          detail:
              '${movement.amount.toStringAsFixed(0)} FCFA${movement.note == null ? '' : ' — ${movement.note}'}',
          userId: movement.userId,
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }
    for (final movement in await db.select(db.localStockMovements).get()) {
      activities.add(
        _Activity(
          date: movement.createdAt,
          title: 'Mouvement de stock',
          detail: '${movement.type} : ${movement.quantity}',
          userId: movement.shopId,
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    for (final closing in await db.select(db.localDailyClosings).get()) {
      activities.add(
        _Activity(
          date: closing.closingDate,
          title: 'Clôture de caisse',
          detail:
              'Écart : ${(closing.cashGap ?? 0).toStringAsFixed(0)} FCFA${closing.note == null ? '' : ' — ${closing.note}'}',
          userId: closing.userId,
          icon: Icons.lock_clock_outlined,
        ),
      );
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique d’audit')),
      body: FutureBuilder<List<_Activity>>(
        future: _load(ref),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return const Center(child: Text('Aucune activité enregistrée.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(child: Icon(activity.icon)),
                title: Text(activity.title),
                subtitle: Text(
                  '${activity.detail}\n'
                  '${DateFormat('dd/MM/yyyy HH:mm').format(activity.date)}'
                  ' • utilisateur ${_shortId(activity.userId)}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _Activity {
  const _Activity({
    required this.date,
    required this.title,
    required this.detail,
    required this.userId,
    required this.icon,
  });

  final DateTime date;
  final String title;
  final String detail;
  final String userId;
  final IconData icon;
}
