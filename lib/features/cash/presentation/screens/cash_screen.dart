import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../shared/widgets/network_error_widget.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/entities/cash_movement_entity.dart';

final todayWithdrawalsProvider = FutureProvider<List<CashMovementEntity>>((
  ref,
) async {
  final db = ref.read(localDbProvider);
  // Les sorties de caisse de CETTE boutique. Sans le filtre, un retrait fait
  // dans une autre boutique du même téléphone apparaissait ici et faussait le
  // total de la journée.
  final shopId = await watchShopId(ref);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final localMovements =
      await (db.select(db.localCashMovements)..where(
            (t) =>
                t.shopId.equals(shopId) &
                t.createdAt.isBetweenValues(startOfDay, endOfDay) &
                t.type.equals('withdrawal'),
          ))
          .get();

  final withdrawals = localMovements
      .map(
        (m) => CashMovementEntity(
          id: m.id,
          shopId: m.shopId,
          userId: m.userId,
          amount: m.amount,
          type: m.type,
          category: m.category,
          note: m.note,
          createdAt: m.createdAt,
        ),
      )
      .toList();

  withdrawals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return withdrawals;
});

class CashScreen extends ConsumerStatefulWidget {
  const CashScreen({super.key});

  @override
  ConsumerState<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends ConsumerState<CashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Repas';
  bool _isLoading = false;

  final List<String> _categories = [
    'Repas',
    'Transport',
    'Fournisseur',
    'Personnel',
    'Autre',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 👇 CORRECTION : ON UTILISE LA BASE LOCALE (DRIFT) 👇
      final db = ref.read(localDbProvider);
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'offline_user';

      final products = ref.read(productProvider).value;
      if (products == null || products.isEmpty) {
        throw Exception(
          'Impossible d\'enregistrer une sortie sans produits synchronisés.',
        );
      }
      final shopId = products.first.shopId;

      final movementId = const Uuid().v4();
      final now = DateTime.now();
      final amount = double.parse(_amountController.text);

      // 1. On enregistre la sortie en LOCAL
      await db
          .into(db.localCashMovements)
          .insert(
            LocalCashMovement(
              id: movementId,
              shopId: shopId,
              userId: userId,
              amount: amount,
              type: 'withdrawal',
              category: _selectedCategory,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              createdAt: now,
            ),
          );

      // 2. On met dans la SALLE D'ATTENTE pour Supabase
      final payload = {
        'id': movementId,
        'shop_id': shopId,
        'user_id': userId,
        'amount': amount,
        'type': 'withdrawal',
        'category': _selectedCategory,
        'note': _noteController.text.isEmpty ? null : _noteController.text,
        'created_at': now.toUtc().toIso8601String(),
      };
      await db.addToQueue('ADD_CASH_MOVEMENT', jsonEncode(payload));
      ref.read(syncServiceProvider).processQueue();

      // 3. On met à jour le Dashboard ET la liste en bas de l'écran
      ref.invalidate(dashboardProvider);
      ref.invalidate(todayWithdrawalsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sortie de caisse enregistrée'),
            backgroundColor: AppColors.primary,
          ),
        );
        _amountController.clear();
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalsAsync = ref.watch(todayWithdrawalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sortie de caisse'),
        backgroundColor: Colors.red.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Combien as-tu pris dans la caisse ?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      prefixIcon: const Icon(
                        Icons.money_off,
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Obligatoire';
                      if (double.tryParse(value) == null)
                        return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Pourquoi ? (Catégorie)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.red.shade900
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _selectedCategory = category);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (Optionnel)',
                      hintText: 'Ex: Taxi pour aller chercher la marchandise',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Enregistrer la sortie',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            const Text(
              'SORTIES DU JOUR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            withdrawalsAsync.when(
              skipError: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => NetworkErrorWidget(
                error: err.toString(),
                onRetry: () => ref.invalidate(todayWithdrawalsProvider),
              ),
              data: (withdrawals) {
                if (withdrawals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune sortie enregistrée aujourd\'hui.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final totalSorties = withdrawals.fold(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total sorti :',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(totalSorties),
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: withdrawals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = withdrawals[index];
                        final timeStr = DateFormat(
                          'HH:mm',
                        ).format(item.createdAt);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Icon(
                                  Icons.arrow_upward,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.category ?? 'Autre',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.note != null &&
                                        item.note!.isNotEmpty)
                                      Text(
                                        item.note!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '- ${CurrencyFormatter.format(item.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
