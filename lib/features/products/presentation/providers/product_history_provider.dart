// lib/features/products/presentation/providers/product_history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_service.dart';

class ProductHistoryItem {
  final String id;
  final DateTime date;
  final String type; // 'recharge' ou 'vente'
  final int quantity;
  final double? totalAmount;

  ProductHistoryItem({
    required this.id,
    required this.date,
    required this.type,
    required this.quantity,
    this.totalAmount,
  });
}

final productHistoryProvider = FutureProvider.family<List<ProductHistoryItem>, String>((ref, productId) async {
  final db = ref.read(localDbProvider);
  final List<ProductHistoryItem> history = [];

  // 1. Récupérer les recharges locales
  final recharges = await (db.select(db.localStockMovements)..where((t) => t.productId.equals(productId))).get();
  for (var r in recharges) {
    history.add(ProductHistoryItem(
      id: r.id,
      date: r.createdAt,
      type: 'recharge',
      quantity: r.quantity,
    ));
  }

  // 2. Récupérer les ventes locales de ce produit
  final saleItems = await (db.select(db.localSaleItems)..where((t) => t.productId.equals(productId))).get();
  for (var item in saleItems) {
    // On cherche la vente parente pour avoir la date
    final sale = await (db.select(db.localSales)..where((t) => t.id.equals(item.saleId))).getSingleOrNull();
    if (sale != null) {
      history.add(ProductHistoryItem(
        id: item.id,
        date: sale.createdAt,
        type: 'vente',
        quantity: item.quantity,
        totalAmount: item.quantity * item.sellPrice,
      ));
    }
  }

  // 3. Trier du plus récent au plus ancien
  history.sort((a, b) => b.date.compareTo(a.date));
  return history;
});