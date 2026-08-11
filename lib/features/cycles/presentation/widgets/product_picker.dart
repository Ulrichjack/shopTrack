import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_provider.dart';

/// Sélecteur de produit partagé par les écrans du module cycles.
/// Une liste déroulante native affiche mal le stock et se manipule mal sur un
/// petit écran : on ouvre plutôt une feuille avec des lignes lisibles.
class ProductPicker extends ConsumerWidget {
  const ProductPicker({
    super.key,
    required this.selectedProductId,
    required this.onChanged,
    this.label = 'Produit',
  });

  final String? selectedProductId;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur : $e'),
      data: (products) {
        final selected = products
            .where((p) => p.id == selectedProductId)
            .firstOrNull;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: products.isEmpty
                ? null
                : () => _openSheet(context, products),
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
                    Icons.inventory_2_outlined,
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
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected?.name ??
                              (products.isEmpty
                                  ? 'Aucun produit — crée-en un dans Stock'
                                  : 'Choisir un produit'),
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
                            'Stock : ${selected.quantity}',
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
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    List<ProductEntity> products,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: products.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isSelected = product.id == selectedProductId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.primaryLight
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: isSelected
                            ? AppColors.primaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Stock : ${product.quantity}'),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, product.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null) onChanged(picked);
  }
}
