import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'declare_loss_screen.dart';
import '../providers/takings_provider.dart';
import '../../../../core/providers/user_shops_provider.dart';

/// Regroupe les opérations du mode inventaire, comme l'onglet Cycles le fait
/// pour le module A : saisie quotidienne, comptage, rapport.
class InventoryHubScreen extends ConsumerWidget {
  const InventoryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takings =
        ref.watch(takingsProvider).value ?? const <LocalShopTaking>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTaking = takings
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .firstOrNull;

    final lastCount = takings.isEmpty ? null : takings.first.date;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Inventaire',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ActionTile(
            icon: Icons.payments_outlined,
            title: 'Recette du jour',
            subtitle: todayTaking == null
                ? 'Pas encore notée aujourd\'hui'
                : 'Notée : ${CurrencyFormatter.format(todayTaking.amount)}',
            highlight: todayTaking == null,
            onTap: () => context.push('/daily-takings'),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.checklist_outlined,
            title: 'Compter le stock',
            subtitle: lastCount == null
                ? 'Pose ton premier point de repère'
                : 'Dernière activité le '
                      '${DateFormat('dd/MM/yyyy').format(lastCount)}',
            onTap: () => context.push('/inventory-count'),
          ),
          // Uniquement s'il y a une autre boutique où envoyer : sinon la
          // tuile promet une action impossible.
          if ((ref.watch(userShopsProvider).value ?? const []).length > 1) ...[
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.local_shipping_outlined,
              title: 'Transferts',
              subtitle: 'Envoyer et confirmer entre tes boutiques',
              onTap: () => context.push('/transfers'),
            ),
          ],
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Déclarer une perte',
            subtitle: 'Casse, périmé, invendu — sinon compté comme vendu',
            onTap: () => showDeclareLossSheet(context),
          ),

          // Le rapport a son propre onglet en bas depuis qu'il remplace le
          // bilan : le proposer ici en plus donnait deux chemins et deux noms
          // pour le même écran.
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Compte ton stock quand tu veux : la période va du dernier '
                    'comptage à celui-ci. Compte tous tes produits pour '
                    'connaître ton bénéfice réel.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? Colors.orange.shade400 : Colors.grey.shade200,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: highlight
                    ? Colors.orange.shade50
                    : AppColors.primaryLight,
                child: Icon(
                  icon,
                  color: highlight
                      ? Colors.orange.shade800
                      : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
