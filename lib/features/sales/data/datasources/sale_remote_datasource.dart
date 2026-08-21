// lib/features/sales/data/datasources/sale_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';

class SaleRemoteDataSource {
  final SupabaseClient supabase;

  SaleRemoteDataSource(this.supabase);

  // 1. Créer une vente complète (Transaction)
  Future<void> createSale(SaleModel sale) async {
    // Étape A : On insère la vente globale et on récupère son ID généré par Supabase
    final saleResponse = await supabase
        .from('sales')
        .insert(sale.toJson())
        .select('id')
        .single();

    final generatedSaleId = saleResponse['id'] as String;

    // Étape B : On prépare la liste des articles avec le bon sale_id
    final itemsToInsert = sale.items.map((item) {
      final itemModel = item as SaleItemModel;
      final json = itemModel.toJson();
      json['sale_id'] = generatedSaleId; // On lie l'article à la vente
      return json;
    }).toList();

    // On insère tous les articles d'un coup
    await supabase.from('sale_items').insert(itemsToInsert);

    // Étape C : On diminue le stock des produits vendus
    // (Pour le MVP, on fait une boucle simple. En V2, on fera une fonction SQL RPC)
    for (var item in sale.items) {
      // On récupère la quantité actuelle
      final productResponse = await supabase
          .from('products')
          .select('quantity')
          .eq('id', item.productId)
          .single();

      final currentQuantity = productResponse['quantity'] as int;
      final newQuantity = currentQuantity - item.quantity;

      // On met à jour le stock
      await supabase
          .from('products')
          .update({'quantity': newQuantity})
          .eq('id', item.productId);
    }
  }

  // 2. Récupérer les ventes d'une journée précise
  Future<List<SaleModel>> getDailySales(String shopId, DateTime date) async {
    // On crée les limites de la journée (De 00:00:00 à 23:59:59)
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toUtc().toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    // On demande à Supabase les ventes ET les articles liés (Jointure)
    final response = await supabase
        .from('sales')
        .select(
          '*, sale_items(*)',
        ) // La magie de Supabase pour faire une jointure !
        .eq('shop_id', shopId)
        .gte('created_at', startOfDay) // Plus grand ou égal à 00:00
        .lte('created_at', endOfDay) // Plus petit ou égal à 23:59
        .order('created_at', ascending: false);

    return response.map((json) => SaleModel.fromJson(json)).toList();
  }
}
