import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../../core/sync/sync_service.dart'; // Pour accéder à localDbProvider
import '../../../../core/errors/sync_error_message.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'package:drift/drift.dart' hide Column;

// --- 1. MODÈLE DE DONNÉES ---
class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime time;
  final bool isIncome;
  final String? note;
  final List<String>? details;

  TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    required this.isIncome,
    this.note,
    this.details,
  });
}

// --- 2. PROVIDER 100% LOCAL (Drift) ---
final dailyTransactionsProvider = FutureProvider.family<List<TransactionItem>, DateTime>((ref, date) async {
  final db = ref.read(localDbProvider);
  final List<TransactionItem> list = [];

  // On définit le début et la fin de la journée sélectionnée
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

  // 1. Récupérer les VENTES locales de la journée
  final localSales = await (db.select(db.localSales)
    ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay)))
      .get();

  for (var sale in localSales) {
    // Récupérer les articles de cette vente spécifique
    final items = await (db.select(db.localSaleItems)..where((t) => t.saleId.equals(sale.id))).get();

    final productList = items.map((item) {
      final totalLigne = item.quantity * item.sellPrice;
      return '${item.quantity} x ${item.productName}  (${CurrencyFormatter.format(totalLigne)})';
    }).toList();

    list.add(
      TransactionItem(
        id: sale.id,
        title: 'Vente',
        subtitle: '${items.length} article(s)',
        amount: sale.totalAmount,
        time: sale.createdAt,
        isIncome: true,
        details: productList,
      ),
    );
  }

  // 2. Récupérer les SORTIES DE CAISSE locales de la journée
  final localCashMovements = await (db.select(db.localCashMovements)
    ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay)))
      .get();

  for (var movement in localCashMovements) {

    list.add(
      TransactionItem(
        id: movement.id,
        title: movement.type == 'morning_balance'
            ? 'Solde Matin' // 👈 On gère le titre
            : (movement.type == 'withdrawal' ? 'Sortie : ${movement.category}' : 'Entrée caisse'),
        subtitle: movement.note ?? 'Aucun détail',
        amount: movement.amount,
        time: movement.createdAt,
        isIncome: movement.type == 'morning_balance', // 👈 Le solde matin est une entrée
        note: movement.note,
      ),
    );
  }


  // 3. Trier du plus récent au plus ancien
  list.sort((a, b) => b.time.compareTo(a.time));
  return list;
});

// --- 3. L'ÉCRAN (UI) ---
class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Bandeau rouge sur une journée passée jamais clôturée : le commerçant
  /// voit *laquelle* pose problème en naviguant dans ses jours, et la traite
  /// sur place.
  Widget _buildPendingClosingBanner() {
    final pending = ref.watch(pendingClosingProvider(_selectedDate)).value;
    if (pending == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pending.daysLate == 1
                      ? 'Journée non clôturée (hier)'
                      : 'Journée non clôturée '
                            '(il y a ${pending.daysLate} jours)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (pending.isUnreliable) ...[
            const SizedBox(height: 8),
            Text(
              'Tu ne te souviendras probablement plus du montant exact de ce '
              'jour-là. Saisis ce dont tu es sûr : l\'écart sera peu fiable.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCloseDayDialog(pending),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.lock_clock, color: Colors.white),
              label: const Text(
                'Clôturer cette journée',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCloseDayDialog(PendingClosing pending) async {
    final controller = TextEditingController();
    final dateStr = DateFormat('dd/MM/yyyy').format(pending.date);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clôture du $dateStr'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pending.isUnreliable
                  ? 'Combien y avait-il dans la caisse à la fin de cette '
                        'journée ? Une estimation vaut mieux que rien.'
                  : 'Combien y avait-il dans la caisse à la fin de cette '
                        'journée ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Montant compté (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Clôturer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(controller.text.replaceAll(' ', ''));
    if (amount == null) return;

    try {
      await ref
          .read(dashboardProvider.notifier)
          .closeDay(
            amount,
            pending.isUnreliable
                ? 'Clôture tardive (${pending.daysLate} jours) — '
                      'montant reconstitué de mémoire.'
                : null,
            specificDate: pending.date,
          );
      ref.invalidate(pendingClosingProvider(_selectedDate));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journée du $dateStr clôturée.'),
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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(dailyTransactionsProvider(_selectedDate));

    final dateStr = _isToday(_selectedDate)
        ? "Aujourd'hui"
        : DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal de Caisse'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // SÉLECTEUR DE DATE
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                  onPressed: _previousDay,
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  onPressed: _isToday(_selectedDate) ? null : _nextDay,
                ),
              ],
            ),
          ),

          // BANDEAU DE RÉSUMÉ
          // BANDEAU DE RÉSUMÉ
          transactionsAsync.maybeWhen(
            data: (transactions) {
              if (transactions.isEmpty) return const SizedBox.shrink();

              double soldeMatin = 0;
              double totalVentes = 0;
              double totalSorties = 0;
              bool soldeMatinTrouve = false; // 👈 AJOUT : Pour ne prendre que le premier

              for (var t in transactions) {
                if (t.title == 'Solde Matin') {
                  // 👈 CORRECTION : On prend le premier (le plus récent) et on ignore les autres
                  if (!soldeMatinTrouve) {
                    soldeMatin = t.amount;
                    soldeMatinTrouve = true;
                  }
                } else if (t.isIncome) {
                  totalVentes += t.amount;
                } else {
                  totalSorties += t.amount;
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: AppColors.primaryDark.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Solde Matin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(soldeMatin),
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('Ventes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(totalVentes),
                          style: const TextStyle(color: Color(0xFF27500A), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('Sorties', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(totalSorties),
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          _buildPendingClosingBanner(),
          // LISTE DES TRANSACTIONS
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(dailyTransactionsProvider(_selectedDate)),
              child: transactionsAsync.when(
                skipError: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => NetworkErrorWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(dailyTransactionsProvider(_selectedDate)),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Aucune transaction à cette date.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final timeStr = DateFormat('HH:mm').format(tx.time);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: tx.isIncome
                                          ? const Color(0xEAF3DE00).withOpacity(0.2)
                                          : Colors.red.shade50,
                                      child: Icon(
                                        tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: tx.isIncome
                                            ? const Color(0xFF27500A)
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  tx.isIncome
                                      ? '+ ${CurrencyFormatter.format(tx.amount)}'
                                      : '- ${CurrencyFormatter.format(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: tx.isIncome
                                        ? const Color(0xFF27500A)
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),

                            if (tx.isIncome && tx.details != null && tx.details!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: tx.details!.map((itemText) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Icon(Icons.shopping_basket_outlined, size: 14, color: AppColors.primaryDark),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            itemText,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ],

                            if (!tx.isIncome && tx.note != null && tx.note!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tx.note!,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}