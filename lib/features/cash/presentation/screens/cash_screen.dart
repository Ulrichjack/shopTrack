import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/cash_movement_entity.dart';

// 👇 NOUVEAU : Provider pour lister uniquement les sorties du jour
final todayWithdrawalsProvider = FutureProvider<List<CashMovementEntity>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final memberResponse = await Supabase.instance.client
      .from('shop_members')
      .select('shop_id')
      .eq('user_id', userId!)
      .single();
  final shopId = memberResponse['shop_id'] as String;

  final cashRepo = ref.read(cashRepositoryProvider);
  final movements = await cashRepo.getTodayMovements(shopId, DateTime.now());

  // On ne garde que les sorties (withdrawal)
  final withdrawals = movements.where((m) => m.type == 'withdrawal').toList();

  // On trie du plus récent au plus ancien
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

  final List<String> _categories = ['Repas', 'Transport', 'Fournisseur', 'Personnel', 'Autre'];

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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final memberResponse = await Supabase.instance.client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId!)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      final cashRepo = ref.read(cashRepositoryProvider);

      // 1. On enregistre la sortie
      await cashRepo.addMovement(
        CashMovementEntity(
          id: '',
          shopId: shopId,
          userId: userId,
          amount: double.parse(_amountController.text),
          type: 'withdrawal',
          category: _selectedCategory,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: DateTime.now(),
        ),
      );

      // 2. On met à jour le Dashboard ET la liste en bas de l'écran
      ref.invalidate(dashboardProvider);
      ref.invalidate(todayWithdrawalsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sortie de caisse enregistrée'), backgroundColor: AppColors.primary),
        );
        // On vide les champs pour une éventuelle autre saisie
        _amountController.clear();
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
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
        backgroundColor: Colors.red.shade600, // Rouge pour indiquer une dépense
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. FORMULAIRE DE SAISIE ---
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Combien as-tu pris dans la caisse ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      prefixIcon: const Icon(Icons.money_off, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Obligatoire';
                      if (double.tryParse(value) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  const Text('Pourquoi ? (Catégorie)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          color: isSelected ? Colors.red.shade900 : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = category);
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enregistrer la sortie', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            // --- 2. LISTE DES SORTIES DU JOUR ---
            const Text('SORTIES DU JOUR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),

            withdrawalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Erreur : $err'),
              data: (withdrawals) {
                if (withdrawals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Text('Aucune sortie enregistrée aujourd\'hui.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                // Calcul du total des sorties du jour
                final totalSorties = withdrawals.fold(0.0, (sum, item) => sum + item.amount);

                return Column(
                  children: [
                    // Petit résumé du total
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
                          Text('Total sorti :', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(totalSorties),
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // La liste
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: withdrawals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = withdrawals[index];
                        final timeStr = DateFormat('HH:mm').format(item.createdAt);

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
                                child: Icon(Icons.arrow_upward, color: Colors.red.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.category ?? 'Autre', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (item.note != null && item.note!.isNotEmpty)
                                      Text(item.note!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '- ${CurrencyFormatter.format(item.amount)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade700),
                                  ),
                                  Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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