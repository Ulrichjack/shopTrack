import 'dart:convert';
import 'package:drift/drift.dart'; // 👈 Important pour le InsertMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';

final localDbProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.read(localDbProvider);
  return SyncService(db);
});

class SyncService {
  final AppDatabase db;
  bool _isSyncing = false;

  SyncService(this.db);

  // =================================================================
  // 1. LE GRAND TÉLÉCHARGEMENT (Supabase ➡️ Base Locale)
  // =================================================================
  Future<void> pullDataFromSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      print('⬇️ Début du téléchargement des données vers le téléphone...');

      // 1. Trouver l'ID de la boutique
      final memberResponse = await supabase.from('shop_members').select('shop_id').eq('user_id', userId).single();
      final shopId = memberResponse['shop_id'] as String;

      // 2. Télécharger TOUS les produits
      final productsData = await supabase.from('products').select().eq('shop_id', shopId);

      // On utilise un "batch" (lot) pour insérer 100 produits d'un coup très rapidement
      await db.batch((batch) {
        batch.insertAll(
          db.localProducts,
          productsData.map((p) => LocalProduct(
            id: p['id'],
            shopId: p['shop_id'],
            name: p['name'],
            buyPrice: (p['buy_price'] as num).toDouble(),
            sellPrice: (p['sell_price'] as num).toDouble(),
            quantity: p['quantity'],
            minQuantity: p['min_quantity'],
            barcode: p['barcode'],
            photoUrl: p['photo_url'],
          )).toList(),
          mode: InsertMode.insertOrReplace, // 👈 MAGIQUE : Si le produit existe déjà en local, il le met à jour !
        );
      });

      // 3. Télécharger les mouvements de caisse d'aujourd'hui (pour le Dashboard)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final cashData = await supabase.from('cash_movements').select().eq('shop_id', shopId).gte('created_at', startOfDay);

      await db.batch((batch) {
        batch.insertAll(
          db.localCashMovements,
          cashData.map((c) => LocalCashMovement(
            id: c['id'],
            shopId: c['shop_id'],
            userId: c['user_id'],
            amount: (c['amount'] as num).toDouble(),
            type: c['type'],
            category: c['category'],
            note: c['note'],
            createdAt: DateTime.parse(c['created_at']),
          )).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });

      print('✅ Grand téléchargement terminé ! Le téléphone est à jour.');
    } catch (e) {
      print('❌ Erreur lors du téléchargement : $e');
    }
  }

  // =================================================================
  // 2. LE FACTEUR (Salle d'attente Locale ➡️ Supabase)
  // =================================================================
  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = await db.getPendingItems();
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      print('🔄 Début de l\'envoi : ${pendingItems.length} élément(s) en attente...');

      for (final item in pendingItems) {
        try {
          final payload = jsonDecode(item.payload);

          if (item.action == 'CREATE_SALE') {
            await _syncSale(payload);
          } else if (item.action == 'ADD_CASH_MOVEMENT') {
            await Supabase.instance.client.from('cash_movements').insert(payload);
          }

          await db.removeFromQueue(item.id);
          print('✅ Élément ${item.id} envoyé avec succès !');
        } catch (e) {
          print('❌ Échec de l\'envoi pour l\'élément ${item.id}: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSale(Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    final saleData = payload['sale'];

    final saleResponse = await supabase.from('sales').insert(saleData).select('id').single();
    final generatedSaleId = saleResponse['id'] as String;

    final itemsData = List<Map<String, dynamic>>.from(payload['items']);
    final itemsToInsert = itemsData.map((item) {
      item['sale_id'] = generatedSaleId;
      return item;
    }).toList();

    await supabase.from('sale_items').insert(itemsToInsert);

    // Mise à jour du stock sur Supabase
    for (var item in itemsToInsert) {
      final productResponse = await supabase.from('products').select('quantity').eq('id', item['product_id']).single();
      final currentQuantity = productResponse['quantity'] as int;
      final newQuantity = currentQuantity - (item['quantity'] as int);
      await supabase.from('products').update({'quantity': newQuantity}).eq('id', item['product_id']);
    }
  }
}