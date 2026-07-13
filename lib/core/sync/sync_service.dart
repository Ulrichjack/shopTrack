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
  bool _isPulling = false;
  Future<void> pullDataFromSupabase() async {

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_isPulling) {
      print('⏳ Téléchargement déjà en cours, on ignore cette requête.');
      return;
    }
    _isPulling = true;
    try {
      print('⬇️ Début du téléchargement des données vers le téléphone...');

      final memberResponse = await supabase.from('shop_members').select('shop_id').eq('user_id', userId).single();
      final shopId = memberResponse['shop_id'] as String;

      // 1. Produits
      final productsData = await supabase.from('products').select().eq('shop_id', shopId);
      await db.batch((batch) {
        batch.deleteAll(db.localProducts);
        batch.insertAll(db.localProducts, productsData.map((p) => LocalProduct(
          id: p['id'], shopId: p['shop_id'], name: p['name'], buyPrice: (p['buy_price'] as num).toDouble(),
          sellPrice: (p['sell_price'] as num).toDouble(), quantity: p['quantity'], minQuantity: p['min_quantity'],
          barcode: p['barcode'], photoUrl: p['photo_url'],
        )).toList(), mode: InsertMode.insertOrReplace);
      });

      // 2. Mouvements de caisse (TOUS)
      final cashData = await supabase.from('cash_movements').select().eq('shop_id', shopId);

      await db.batch((batch) {
        batch.deleteAll(db.localCashMovements);
        batch.insertAll(db.localCashMovements, cashData.map((c) => LocalCashMovement(
          id: c['id'], shopId: c['shop_id'], userId: c['user_id'], amount: (c['amount'] as num).toDouble(),
          type: c['type'], category: c['category'], note: c['note'], createdAt: DateTime.parse(c['created_at']).toLocal(),
        )).toList(), mode: InsertMode.insertOrReplace);
      });

      // 3. Ventes (TOUTES)
      final salesData = await supabase.from('sales').select().eq('shop_id', shopId);
      await db.batch((batch) {
        batch.deleteAll(db.localSales);
        batch.insertAll(db.localSales, salesData.map((s) => LocalSale(
          id: s['id'], shopId: s['shop_id'], userId: s['user_id'], totalAmount: (s['total_amount'] as num).toDouble(),
          totalProfit: (s['total_profit'] as num).toDouble(), createdAt: DateTime.parse(s['created_at']).toLocal(),
        )).toList(), mode: InsertMode.insertOrReplace);
      });

      // 4. Articles vendus
      final saleItemsData = await supabase.from('sale_items').select('*, sales!inner(shop_id)').eq('sales.shop_id', shopId);
      await db.batch((batch) {
        batch.deleteAll(db.localSaleItems);
        batch.insertAll(db.localSaleItems, saleItemsData.map((i) => LocalSaleItem(
          id: i['id'], saleId: i['sale_id'], productId: i['product_id'], productName: i['product_name'],
          quantity: i['quantity'], sellPrice: (i['sell_price'] as num).toDouble(), buyPrice: (i['buy_price'] as num).toDouble(),
          profit: (i['profit'] as num).toDouble(),
        )).toList(), mode: InsertMode.insertOrReplace);
      });

      // 5. Clôtures
      final closingsData = await supabase.from('daily_closings').select().eq('shop_id', shopId);
      await db.batch((batch) {
        batch.deleteAll(db.localDailyClosings);
        batch.insertAll(db.localDailyClosings, closingsData.map((c) => LocalDailyClosing(
          id: c['id'], shopId: c['shop_id'], userId: c['user_id'], closingDate: DateTime.parse(c['closing_date']),
          morningBalance: (c['morning_balance'] as num).toDouble(), totalSales: (c['total_sales'] as num).toDouble(),
          totalWithdrawals: (c['total_withdrawals'] as num).toDouble(), calculatedCash: (c['calculated_cash'] as num).toDouble(),
          grossProfit: (c['gross_profit'] as num).toDouble(), netProfit: (c['net_profit'] as num).toDouble(),
          physicalCash: c['physical_cash'] != null ? (c['physical_cash'] as num).toDouble() : null,
          cashGap: c['cash_gap'] != null ? (c['cash_gap'] as num).toDouble() : null,
          isClosed: c['is_closed'] ?? false, note: c['note'],
        )).toList(), mode: InsertMode.insertOrReplace);
      });

      print('✅ Grand téléchargement terminé ! Le téléphone a TOUT l\'historique.');
    } catch (e) {
      print('❌ Erreur lors du téléchargement : $e');
    }finally {
      _isPulling = false;
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
          } else if (item.action == 'ADD_PRODUCT') {
            await Supabase.instance.client.from('products').insert(payload);
          } else if (item.action == 'UPDATE_PRODUCT') {
            await Supabase.instance.client.from('products').update(payload).eq('id', payload['id']);
          } else if (item.action == 'ADD_STOCK') {
            // 1. On enregistre le mouvement
            await Supabase.instance.client.from('stock_movements').insert({
              'shop_id': payload['shop_id'],
              'product_id': payload['product_id'],
              'quantity': payload['quantity'],
              'type': payload['type'],
            });
            // 2. On met à jour la quantité du produit sur Supabase
            await Supabase.instance.client.from('products')
                .update({'quantity': payload['new_total_quantity']})
                .eq('id', payload['product_id']);
          } else if (item.action == 'ADD_CLOSING') {
            // On utilise upsert pour éviter les doublons si on clôture 2 fois
            await Supabase.instance.client.from('daily_closings').upsert(
              payload,
              onConflict: 'shop_id,closing_date',
            );
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