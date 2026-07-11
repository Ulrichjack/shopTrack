import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductHistoryItem {
  final String id;
  final DateTime date;
  final String type; // 'recharge' ou 'vente'
  final int quantity;
  final double? totalAmount; // Uniquement pour les ventes

  ProductHistoryItem({
    required this.id,
    required this.date,
    required this.type,
    required this.quantity,
    this.totalAmount,
  });
}

// Ce provider prend l'ID du produit en paramètre et renvoie son historique
final productHistoryProvider = FutureProvider.family<List<ProductHistoryItem>, String>((ref, productId) async {
  final supabase = Supabase.instance.client;
  final List<ProductHistoryItem> history = [];

  // 1. Récupérer les recharges de stock
  final recharges = await supabase
      .from('stock_movements')
      .select()
      .eq('product_id', productId)
      .order('created_at', ascending: false);

  for (var r in recharges) {
    history.add(ProductHistoryItem(
      id: r['id'],
      date: DateTime.parse(r['created_at']),
      type: 'recharge',
      quantity: r['quantity'],
    ));
  }

  // 2. Récupérer les ventes de ce produit
  final sales = await supabase
      .from('sale_items')
      .select('id, quantity, sell_price, sales(created_at)')
      .eq('product_id', productId);

  for (var s in sales) {
    // Supabase renvoie la date de la vente imbriquée
    final saleData = s['sales'] as Map<String, dynamic>;
    history.add(ProductHistoryItem(
      id: s['id'],
      date: DateTime.parse(saleData['created_at']),
      type: 'vente',
      quantity: s['quantity'],
      totalAmount: (s['quantity'] as int) * double.parse(s['sell_price'].toString()),
    ));
  }

  // 3. Trier du plus récent au plus ancien
  history.sort((a, b) => b.date.compareTo(a.date));
  return history;
});