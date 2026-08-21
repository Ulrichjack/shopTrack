import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/cycle_provider.dart';

class CyclesHubScreen extends ConsumerWidget {
  const CyclesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final products = ref.watch(productProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cycles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-cycle'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau cycle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(cyclesProvider),
        child: cyclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (cycles) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        context,
                        icon: Icons.summarize_outlined,
                        label: 'Rapport',
                        sublabel: 'Ce cycle m’a-t-il rapporté ?',
                        color: AppColors.primaryDark,
                        route: '/cycle-report',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        context,
                        icon: Icons.report_problem_outlined,
                        label: 'Perte',
                        sublabel: 'Casse, rongeurs…',
                        color: Colors.orange.shade700,
                        route: '/loss-entry',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Réglage rare mais indispensable avant la 1re vente : il doit
                // rester visible, pas caché derrière une icône.
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(
                      Icons.straighten,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Unités de vente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Ex : 1 plateau = 30 œufs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/manage-units'),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'CYCLES EN COURS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (cycles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "Aucun cycle pour l'instant.\n"
                        'Crée ton premier approvisionnement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...cycles.map((cycle) {
                    final productName = products
                        .where((p) => p.id == cycle.productId)
                        .map((p) => p.name)
                        .firstOrNull;
                    final unitCost = cycle.quantityReceived > 0
                        ? cycle.purchaseCost / cycle.quantityReceived
                        : 0.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cycle.status == 'open'
                              ? AppColors.primaryLight
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: cycle.status == 'open'
                                ? AppColors.primaryDark
                                : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          productName ?? 'Produit inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${cycle.quantityReceived} reçus · '
                          '${CurrencyFormatter.format(unitCost)}/unité\n'
                          'Ouvert le ${DateFormat('dd/MM/yyyy').format(cycle.openedAt)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/cycle-report'),
                      ),
                    );
                  }),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
