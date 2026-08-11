import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/cycle_report_provider.dart';

class CycleReportScreen extends ConsumerStatefulWidget {
  const CycleReportScreen({super.key});

  @override
  ConsumerState<CycleReportScreen> createState() => _CycleReportScreenState();
}

class _CycleReportScreenState extends ConsumerState<CycleReportScreen> {
  String? _selectedCycleId;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rapport de cycle')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cyclesAsync.when(
                data: (cycles) {
                  if (cycles.isEmpty) {
                    return const Text('Aucun cycle créé pour le moment.');
                  }
                  final products = productsAsync.value ?? [];
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCycleId,
                    decoration: const InputDecoration(
                      labelText: 'Choisir un cycle',
                      border: OutlineInputBorder(),
                    ),
                    items: cycles.map((c) {
                      final productName = products
                          .firstWhere(
                            (p) => p.id == c.productId,
                            orElse: () => products.first,
                          )
                          .name;
                      final date = DateFormat('dd/MM/yyyy').format(c.openedAt);
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('$productName — $date (${c.status})'),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCycleId = value),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur : $e'),
              ),

              const SizedBox(height: 24),

              if (_selectedCycleId != null)
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final reportAsync = ref.watch(
                        cycleReportProvider(_selectedCycleId!),
                      );
                      return reportAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erreur : $e'),
                        data: (report) {
                          final totals = report.totals;
                          return ListView(
                            children: [
                              _row(
                                'Quantité reçue',
                                '${report.cycle.quantityReceived}',
                              ),
                              _row(
                                "Coût d'achat total",
                                CurrencyFormatter.format(
                                  report.cycle.purchaseCost,
                                ),
                              ),
                              _row(
                                'Coût réel par unité de base',
                                CurrencyFormatter.format(totals.unitCost),
                              ),
                              const Divider(height: 32),
                              _row(
                                "Chiffre d'affaires",
                                CurrencyFormatter.format(totals.revenue),
                              ),
                              _row(
                                'Coût du stock vendu',
                                CurrencyFormatter.format(totals.soldStockCost),
                              ),
                              _row(
                                'Valeur des pertes',
                                CurrencyFormatter.format(totals.lossValue),
                              ),
                              _row(
                                'Stock restant',
                                '${totals.remainingStock}',
                              ),
                              const Divider(height: 32),
                              _row(
                                'Bénéfice net du cycle',
                                CurrencyFormatter.format(totals.netProfit),
                                emphasize: true,
                              ),
                              const SizedBox(height: 32),
                              if (report.cycle.status == 'open')
                                OutlinedButton.icon(
                                  onPressed: () => _confirmClose(report),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryDark,
                                    side: const BorderSide(
                                      color: AppColors.primaryDark,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.archive_outlined),
                                  label: const Text('Terminer ce cycle'),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Cycle terminé'
                                    '${report.cycle.closedAt != null ? " le ${DateFormat('dd/MM/yyyy').format(report.cycle.closedAt!)}" : ""}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClose(CycleReport report) async {
    final restant = report.totals.remainingStock;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer ce cycle ?'),
        content: Text(
          restant > 0
              ? 'Il reste $restant unité(s) non vendues. Le résultat sera '
                    'figé, mais ce stock reste vendable.\n\n'
                    'Les prochaines ventes ne compteront plus dans ce cycle.'
              : 'Le résultat du cycle sera figé. Les prochaines ventes ne '
                    'compteront plus dedans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            child: const Text(
              'Terminer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(cyclesProvider.notifier).closeCycle(report.cycle.id);
      ref.invalidate(cycleReportProvider(report.cycle.id));
      ref.invalidate(openCycleForProductProvider(report.cycle.productId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle terminé.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    final style = TextStyle(
      fontSize: emphasize ? 20 : 15,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: emphasize ? AppColors.primaryDark : AppColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
