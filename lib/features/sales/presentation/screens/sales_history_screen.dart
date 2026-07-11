// lib/features/sales/presentation/screens/sales_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../sales/presentation/providers/sale_provider.dart';

/// Modèle pour mélanger Ventes et Sorties dans l'ordre chronologique
class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime time;
  final bool isIncome; // vrai pour les ventes, faux pour les sorties/dépenses
  final String? note;
  final List<String>? details; // Liste des articles vendus

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

/// PROVIDER CORRIGÉ : Indépendant du Dashboard pour éviter les rechargements inutiles
final dailyTransactionsProvider = FutureProvider.family<List<TransactionItem>, DateTime>((ref, date) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('Non connecté');

  final memberResponse = await Supabase.instance.client
      .from('shop_members')
      .select('shop_id')
      .eq('user_id', userId)
      .limit(1)
      .single();
  final shopId = memberResponse['shop_id'] as String;

  final saleRepo = ref.read(saleRepositoryProvider);
  final cashRepo = ref.read(cashRepositoryProvider);

  // On récupère les ventes et les mouvements de caisse pour la date demandée
  final sales = await saleRepo.getDailySales(shopId, date);
  final cashMovements = await cashRepo.getTodayMovements(shopId, date);

  final List<TransactionItem> list = [];

  // On transforme les ventes en transactions avec leurs détails
  for (var sale in sales) {
    // On extrait le nom, la quantité ET LE PRIX TOTAL de chaque produit vendu
    final productList = sale.items.map((item) {
      final totalLigne = item.quantity * item.sellPrice;
      return '${item.quantity} x ${item.productName}  (${CurrencyFormatter.format(totalLigne)})';
    }).toList();

    list.add(
      TransactionItem(
        id: sale.id,
        title: 'Vente',
        subtitle: '${sale.items.length} article(s)',
        amount: sale.totalAmount,
        time: sale.createdAt,
        isIncome: true,
        details: productList,
      ),
    );
  }

  // On transforme les mouvements de caisse en transactions
  for (var movement in cashMovements) {
    if (movement.type == 'morning_balance') continue; // On ignore le solde du matin

    list.add(
      TransactionItem(
        id: movement.id,
        title: movement.type == 'withdrawal' ? 'Sortie : ${movement.category}' : 'Entrée caisse',
        subtitle: movement.note ?? 'Aucun détail',
        amount: movement.amount,
        time: movement.createdAt,
        isIncome: false,
        note: movement.note,
      ),
    );
  }

  // On trie tout du plus récent au plus ancien
  list.sort((a, b) => b.time.compareTo(a.time));
  return list;
});

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

  // Fonction pour ouvrir le calendrier natif
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023), // L'année de création de l'app
      lastDate: DateTime.now(),  // On bloque les dates futures
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
          // 1. SÉLECTEUR DE DATE EN HAUT
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
                // La date est maintenant cliquable pour ouvrir le calendrier
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

          // 2. BANDEAU DE RÉSUMÉ DE LA JOURNÉE
          transactionsAsync.maybeWhen(
            data: (transactions) {
              if (transactions.isEmpty) return const SizedBox.shrink();

              double totalEntrees = 0;
              double totalSorties = 0;
              for (var t in transactions) {
                if (t.isIncome) {
                  totalEntrees += t.amount;
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
                        const Text('Entrées', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(totalEntrees),
                          style: const TextStyle(color: Color(0xFF27500A), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('Sorties', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(totalSorties),
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 3. LISTE DES TRANSACTIONS
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(dailyTransactionsProvider(_selectedDate)),
              child: transactionsAsync.when(
                skipError: true, // 👈 On ajoute ça
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

                            // AFFICHAGE DU REÇU DÉTAILLÉ DE LA VENTE
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

                            // AFFICHAGE DE LA NOTE DE LA DÉPENSE
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