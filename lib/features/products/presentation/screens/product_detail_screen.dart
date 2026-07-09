// lib/features/products/presentation/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductEntity product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  // Petit helper pour créer les 3 blocs (Achat, Vente, Bénéfice)
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
            Text(
              title,
              style: TextStyle(fontSize: 12, color: isProfit ? AppColors.primaryDark : Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isProfit ? AppColors.primaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double profit = product.sellPrice - product.buyPrice;
    final bool isLowStock = product.quantity <= product.minQuantity;
    final bool isOutOfStock = product.quantity == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Modifier le produit
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image du produit
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: product.photoUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(product.photoUrl!, fit: BoxFit.cover),
              )
                  : const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 2. Nom et Code
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              product.barcode != null ? 'Code : ${product.barcode}' : 'Aucun code scanné',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // 3. Les 3 blocs de prix (Style de ta maquette)
            Row(
              children: [
                _buildPriceBox('Achat', product.buyPrice, AppColors.textPrimary),
                const SizedBox(width: 12),
                _buildPriceBox('Vente', product.sellPrice, AppColors.textPrimary),
                const SizedBox(width: 12),
                _buildPriceBox('Bénéfice', profit, AppColors.primary, isProfit: true),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Bloc d'état du stock
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stock actuel', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      Text('${product.quantity} unités', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Minimum', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      Text('${product.minQuantity} unités', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? Colors.red.shade700 : (isLowStock ? Colors.orange.shade800 : Colors.green.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 5. Bouton Générer QR Code
            ElevatedButton.icon(
              onPressed: () {
                if (product.barcode == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ce produit n'a pas de code à générer.")),
                  );
                  return;
                }

                // On ouvre une boîte de dialogue (Popup) avec le QR Code en grand
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(product.name, textAlign: TextAlign.center),
                    content: SizedBox(
                      width: 250,
                      height: 250,
                      child: Center(
                        child: QrImageView(
                          data: product.barcode!, // Le texte à transformer en QR
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text(
                'Générer QR code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}