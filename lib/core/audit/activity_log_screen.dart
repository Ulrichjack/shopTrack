import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/employees_provider.dart';
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
      final isIncome = {
        'morning_balance',
        'incoming',
        'adjustment_in',
      }.contains(movement.type);
      final title = switch (movement.type) {
        'morning_balance' => 'Initialisation de la caisse',
        'incoming' => 'Entrée de caisse',
        'withdrawal' => 'Sortie de caisse',
        'adjustment_in' => 'Ajustement positif de caisse',
        'adjustment_out' => 'Ajustement négatif de caisse',
        _ => 'Mouvement de caisse',
      };
      activities.add(
        _Activity(
          date: movement.createdAt,
          title: title,
          detail:
              '${isIncome ? '+' : '-'}${movement.amount.toStringAsFixed(0)} FCFA${movement.note == null ? '' : ' — ${movement.note}'}',
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
          // Qui a fait le geste, et pas son identifiant.
          //
          // « utilisateur 891ff68c » ne répondait à aucune question. Celle
          // qu'on se pose devant ce journal est « qui ? ».
          //
          // Avec une seule employée, « la vendeuse » y répond entièrement — et
          // le numéro serait du bruit. À partir de deux, il ne répond plus, et
          // le téléphone les sépare : c'est celui que la patronne a tapé en
          // créant le compte, elle le reconnaît sans consulter une liste.
          final membres = ref.watch(shopMembersProvider).value ?? const [];
          final seulVendeur = membres.where((m) => !m.isOwner).length <= 1;
          final roles = {
            for (final m in membres)
              m.userId: m.nommer(seulVendeur: seulVendeur),
          };
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
                  ' • par ${roles[activity.userId] ?? _shortId(activity.userId)}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  /// Repli quand le rôle est inconnu : un compte retiré de la boutique, ou une
  /// ligne écrite hors ligne avant la première synchronisation.
  String _shortId(String id) =>
      id.length <= 8 ? id : 'utilisateur ${id.substring(0, 8)}';
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
