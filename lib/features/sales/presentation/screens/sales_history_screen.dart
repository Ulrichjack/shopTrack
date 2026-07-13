import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../../core/sync/sync_service.dart'; // Pour accéder à localDbProvider
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