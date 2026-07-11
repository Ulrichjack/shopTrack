import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../providers/product_history_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {

  void _showAddStockBottomSheet(BuildContext context, ProductEntity currentProduct) {
    final quantityController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ajouter du stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Article : ${currentProduct.name}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantité à ajouter',
                        prefixIcon: const Icon(Icons.add_box),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final qty = int.tryParse(quantityController.text);
                        if (qty == null || qty <= 0) return;

                        setModalState(() => isSaving = true);

                        try {
                          final supabase = Supabase.instance.client;

                          final newQty = currentProduct.quantity + qty;
                          await supabase.from('products').update({'quantity': newQty}).eq('id', currentProduct.id);

                          await supabase.from('stock_movements').insert({
                            'shop_id': currentProduct.shopId,
                            'product_id': currentProduct.id,
                            'quantity': qty,
                            'type': 'recharge',
                          });

                          ref.invalidate(productProvider);
                          ref.invalidate(productHistoryProvider(currentProduct.id));

                          if (context.mounted) {
                            Navigator.pop(context); // 👈 On ferme JUSTE le BottomSheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Stock ajouté avec succès !'), backgroundColor: AppColors.primary),
                            );
                            // On a enlevé le 2ème context.pop() ! On reste sur la page.
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirmer la recharge', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildPriceBox(String title, double amount, Color color, {bool isProfit = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isProfit ? AppColors.success : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isProfit ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isProfit ? AppColors.primaryDark : Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isProfit ? AppColors.primaryDark : AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 👇 LA MAGIE EST ICI 👇
    // On écoute la liste globale des produits. Si le produit est modifié ailleurs,
    // cet écran va se mettre à jour tout seul avec les nouvelles infos !
    final productsList = ref.watch(productProvider).value ?? [];

    // On initialise avec le produit passé en paramètre
    ProductEntity currentProduct = widget.product;

    // On cherche manuellement dans la liste pour éviter l'erreur de type stricte de Dart
    for (var p in productsList) {
      if (p.id == widget.product.id) {
        currentProduct = p;
        break;
      }
    }

    final double profit = currentProduct.sellPrice - currentProduct.buyPrice;
    final bool isLowStock = currentProduct.quantity <= currentProduct.minQuantity;
    final bool isOutOfStock = currentProduct.quantity == 0;

    final historyAsync = ref.watch(productHistoryProvider(currentProduct.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-product', extra: currentProduct),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: currentProduct.photoUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(currentProduct.photoUrl!, fit: BoxFit.cover))
                  : const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Text(currentProduct.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(currentProduct.barcode != null ? 'Code : ${currentProduct.barcode}' : 'Aucun code scanné', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildPriceBox('Achat', currentProduct.buyPrice, AppColors.textPrimary),
                const SizedBox(width: 12),
                _buildPriceBox('Vente', currentProduct.sellPrice, AppColors.textPrimary),
                const SizedBox(width: 12),
                _buildPriceBox('Bénéfice', profit, AppColors.primary, isProfit: true),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stock actuel', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      Text('${currentProduct.quantity} unités', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Statut', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.red.shade100 : (isLowStock ? Colors.orange.shade100 : Colors.green.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOutOfStock ? 'Rupture' : (isLowStock ? 'Stock critique' : 'En stock'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.red.shade700 : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('HISTORIQUE RÉCENT (15 derniers)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Erreur : $err'),
              data: (history) {
                if (history.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucun mouvement pour ce produit.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length > 15 ? 15 : history.length, // On affiche les 15 derniers
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isRecharge = item.type == 'recharge';
                    final dateStr = DateFormat('dd/MM/yy HH:mm').format(item.date);

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
                            backgroundColor: isRecharge ? Colors.blue.shade50 : AppColors.primaryLight,
                            child: Icon(
                              isRecharge ? Icons.add_shopping_cart : Icons.point_of_sale,
                              color: isRecharge ? Colors.blue : AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isRecharge ? 'Recharge de stock' : 'Vente', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isRecharge ? '+ ${item.quantity}' : '- ${item.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isRecharge ? Colors.blue : AppColors.primaryDark,
                                ),
                              ),
                              if (!isRecharge && item.totalAmount != null)
                                Text(CurrencyFormatter.format(item.totalAmount!), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStockBottomSheet(context, currentProduct),
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_box, color: Colors.white),
        label: const Text('Ajouter Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}