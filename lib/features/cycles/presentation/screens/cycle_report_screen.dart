import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/sync_error_message.dart';
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
                  final selected = cycles
                      .where((c) => c.id == _selectedCycleId)
                      .firstOrNull;
                  String nameOf(String productId) => products
                      .where((p) => p.id == productId)
                      .map((p) => p.name)
                      .firstOrNull ??
                      'Produit inconnu';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _pickCycle(cycles, nameOf),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == null
                                ? Colors.grey.shade300
                                : AppColors.primary,
                            width: selected == null ? 1 : 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.autorenew,
                              color: selected == null
                                  ? Colors.grey.shade400
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cycle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selected == null
                                        ? 'Choisir un cycle'
                                        : nameOf(selected.productId),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: selected == null
                                          ? Colors.grey.shade500
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (selected != null)
                                    Text(
                                      '${DateFormat('dd/MM/yyyy').format(selected.openedAt)}'
                                      ' · ${selected.status == 'open' ? 'en cours' : 'terminé'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.expand_more, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
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
                              // La quantité AVANT l'argent : « j'ai vendu
                              // 3 050 œufs » est la première chose qu'un
                              // vendeur veut lire. Elle manquait, et il fallait
                              // la déduire du reçu moins le restant moins les
                              // pertes.
                              _row(
                                'Quantité vendue',
                                '${totals.soldQuantity}',
                              ),
                              _row(
                                "Chiffre d'affaires",
                                CurrencyFormatter.format(totals.revenue),
                              ),
                              _row(
                                'Coût du stock vendu',
                                CurrencyFormatter.format(totals.soldStockCost),
                              ),
                              // Le nombre ET la valeur : « 4 000 F » seul ne
                              // disait pas si c'étaient 50 œufs cassés ou un
                              // carton entier disparu.
                              _row(
                                'Pertes',
                                '${totals.lostQuantity} · '
                                '${CurrencyFormatter.format(totals.lossValue)}',
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
                              // Signaler l'épuisement plutôt que fermer tout
                              // seul : figer le résultat est un acte
                              // comptable, il reste au commerçant.
                              if (report.cycle.status == 'open' &&
                                  totals.remainingStock <= 0)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Ce cycle est épuisé : tout a été vendu '
                                    'ou perdu. Tu peux le terminer.',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
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
                              else ...[
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
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => _confirmReopen(report),
                                  icon: const Icon(Icons.lock_open, size: 18),
                                  label: const Text('Rouvrir ce cycle'),
                                ),
                              ],
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

  /// Même principe que le sélecteur de produit : une feuille lisible avec
  /// recherche, plutôt qu'une liste déroulante illisible à 20 entrées.
  Future<void> _pickCycle(
    List<LocalSupplyCycle> cycles,
    String Function(String) nameOf,
  ) async {
    final ordered = [...cycles]
      ..sort((a, b) {
        if (a.status != b.status) return a.status == 'open' ? -1 : 1;
        return b.openedAt.compareTo(a.openedAt);
      });
    final controller = TextEditingController();

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = controller.text.trim().toLowerCase();
          final visible = query.isEmpty
              ? ordered
              : ordered
                    .where((c) => nameOf(c.productId).toLowerCase().contains(query))
                    .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: controller,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('Aucun cycle trouvé'))
                          : ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final cycle = visible[index];
                                final isOpen = cycle.status == 'open';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isOpen
                                        ? AppColors.primaryLight
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      isOpen
                                          ? Icons.autorenew
                                          : Icons.archive_outlined,
                                      color: isOpen
                                          ? AppColors.primaryDark
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  title: Text(
                                    nameOf(cycle.productId),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${cycle.quantityReceived} reçus · '
                                    '${DateFormat('dd/MM/yyyy').format(cycle.openedAt)}'
                                    '${isOpen ? "" : " · terminé"}',
                                  ),
                                  onTap: () => Navigator.pop(context, cycle.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (picked != null) setState(() => _selectedCycleId = picked);
  }

  Future<void> _confirmReopen(CycleReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rouvrir ce cycle ?'),
        content: const Text(
          'Les prochaines ventes de ce produit seront de nouveau rattachées '
          'à ce cycle et compteront dans son résultat.',
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
            child: const Text('Rouvrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(cyclesProvider.notifier).reopenCycle(report.cycle.id);
      ref.invalidate(cycleReportProvider(report.cycle.id));
      ref.invalidate(openCycleForProductProvider(report.cycle.productId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cycle rouvert.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanSyncError(e)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le libellé se replie ; le montant garde toute sa place. Sans ça
          // « Coût réel par unité de base » + un montant long débordent sur
          // les petits écrans.
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
