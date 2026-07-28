import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

final localDbProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref.read(localDbProvider));
  ref.onDispose(service.dispose);
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});

enum SyncPhase { idle, sending, downloading, success, error }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    required this.pendingCount,
    this.lastSyncAt,
    this.lastError,
  });

  const SyncStatus.initial()
    : phase = SyncPhase.idle,
      pendingCount = 0,
      lastSyncAt = null,
      lastError = null;

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;
}

class SyncService {
  SyncService(this.db);

  final AppDatabase db;
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus.initial();
  bool _isSyncing = false;
  bool _isPulling = false;

  Stream<SyncStatus> get statusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  void _emit({
    required SyncPhase phase,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
  }) {
    _status = SyncStatus(
      phase: phase,
      pendingCount: pendingCount ?? _status.pendingCount,
      lastSyncAt: lastSyncAt ?? _status.lastSyncAt,
      lastError: lastError,
    );
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  Future<void> refreshStatus() async {
    _emit(
      phase: _isSyncing
          ? SyncPhase.sending
          : _isPulling
          ? SyncPhase.downloading
          : SyncPhase.idle,
      pendingCount: await db.getPendingCount(),
      lastError: _status.lastError,
    );
  }

  Future<void> synchronize() async {
    await processQueue();
    // Ne jamais écraser un stock local tant qu'une écriture n'est pas envoyée.
    if (await db.getPendingCount() == 0) {
      await pullDataFromSupabase();
    }
  }

  Future<void> pullDataFromSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || _isPulling) return;

    _isPulling = true;
    _emit(
      phase: SyncPhase.downloading,
      pendingCount: await db.getPendingCount(),
    );

    try {
      final memberResponse = await supabase
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', userId)
          .single();
      final shopId = memberResponse['shop_id'] as String;

      final results = await Future.wait([
        supabase.from('products').select().eq('shop_id', shopId),
        supabase.from('cash_movements').select().eq('shop_id', shopId),
        supabase.from('sales').select().eq('shop_id', shopId),
        supabase
            .from('sale_items')
            .select('*, sales!inner(shop_id)')
            .eq('sales.shop_id', shopId),
        supabase.from('daily_closings').select().eq('shop_id', shopId),
      ]);

      final productsData = results[0];
      final cashData = results[1];
      final salesData = results[2];
      final saleItemsData = results[3];
      final closingsData = results[4];

      // Fusionner au lieu de vider les tables protège les écritures hors ligne.
      await db.transaction(() async {
        await db.batch((batch) {
          batch.insertAll(
            db.localProducts,
            productsData
                .map(
                  (p) => LocalProduct(
                    id: p['id'],
                    shopId: p['shop_id'],
                    name: p['name'],
                    buyPrice: (p['buy_price'] as num).toDouble(),
                    sellPrice: (p['sell_price'] as num).toDouble(),
                    quantity: p['quantity'],
                    minQuantity: p['min_quantity'],
                    barcode: p['barcode'],
                    photoUrl: p['photo_url'],
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localCashMovements,
            cashData
                .map(
                  (c) => LocalCashMovement(
                    id: c['id'],
                    shopId: c['shop_id'],
                    userId: c['user_id'],
                    amount: (c['amount'] as num).toDouble(),
                    type: c['type'],
                    category: c['category'],
                    note: c['note'],
                    createdAt: DateTime.parse(c['created_at']).toLocal(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localSales,
            salesData
                .map(
                  (s) => LocalSale(
                    id: s['id'],
                    shopId: s['shop_id'],
                    userId: s['user_id'],
                    totalAmount: (s['total_amount'] as num).toDouble(),
                    totalProfit: (s['total_profit'] as num).toDouble(),
                    createdAt: DateTime.parse(s['created_at']).toLocal(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localSaleItems,
            saleItemsData
                .map(
                  (i) => LocalSaleItem(
                    id: i['id'],
                    saleId: i['sale_id'],
                    productId: i['product_id'],
                    productName: i['product_name'],
                    quantity: i['quantity'],
                    sellPrice: (i['sell_price'] as num).toDouble(),
                    buyPrice: (i['buy_price'] as num).toDouble(),
                    profit: (i['profit'] as num).toDouble(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localDailyClosings,
            closingsData
                .map(
                  (c) => LocalDailyClosing(
                    id: c['id'],
                    shopId: c['shop_id'],
                    userId: c['user_id'],
                    closingDate: DateTime.parse(c['closing_date']),
                    morningBalance: (c['morning_balance'] as num).toDouble(),
                    totalSales: (c['total_sales'] as num).toDouble(),
                    totalWithdrawals: (c['total_withdrawals'] as num)
                        .toDouble(),
                    calculatedCash: (c['calculated_cash'] as num).toDouble(),
                    grossProfit: (c['gross_profit'] as num).toDouble(),
                    netProfit: (c['net_profit'] as num).toDouble(),
                    physicalCash: c['physical_cash'] == null
                        ? null
                        : (c['physical_cash'] as num).toDouble(),
                    cashGap: c['cash_gap'] == null
                        ? null
                        : (c['cash_gap'] as num).toDouble(),
                    isClosed: c['is_closed'] ?? false,
                    note: c['note'],
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
      });

      _emit(
        phase: SyncPhase.success,
        pendingCount: await db.getPendingCount(),
        lastSyncAt: DateTime.now(),
      );
    } catch (error) {
      _emit(
        phase: SyncPhase.error,
        pendingCount: await db.getPendingCount(),
        lastError: error.toString(),
      );
      rethrow;
    } finally {
      _isPulling = false;
    }
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _emit(phase: SyncPhase.sending, pendingCount: await db.getPendingCount());

    String? lastError;
    try {
      final pendingItems = await db.getPendingItems();
      for (final item in pendingItems) {
        try {
          final payload = jsonDecode(item.payload) as Map<String, dynamic>;
          await _processItem(item.action, payload);
          await db.removeFromQueue(item.id);
        } catch (error) {
          // Respecter l'ordre : une opération plus récente peut dépendre de celle-ci.
          lastError = error.toString();
          break;
        }
      }
    } finally {
      _isSyncing = false;
      final pendingCount = await db.getPendingCount();
      _emit(
        phase: lastError == null ? SyncPhase.success : SyncPhase.error,
        pendingCount: pendingCount,
        lastSyncAt: lastError == null ? DateTime.now() : null,
        lastError: lastError,
      );
    }
  }

  Future<void> _processItem(String action, Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    switch (action) {
      case 'CREATE_SALE':
        await _syncSale(payload);
      case 'ADD_CASH_MOVEMENT':
        await supabase.from('cash_movements').upsert(payload);
      case 'ADD_PRODUCT':
        await supabase.from('products').upsert(payload);
      case 'UPDATE_PRODUCT':
        await supabase.from('products').update(payload).eq('id', payload['id']);
      case 'ADD_STOCK':
        await supabase.rpc(
          'apply_stock_movement',
          params: {
            'p_movement_id': payload['movement_id'],
            'p_shop_id': payload['shop_id'],
            'p_product_id': payload['product_id'],
            'p_quantity_delta': payload['quantity'],
            'p_type': payload['type'],
          },
        );
      case 'ADD_CLOSING':
        await supabase
            .from('daily_closings')
            .upsert(payload, onConflict: 'shop_id,closing_date');
      default:
        throw StateError('Action de synchronisation inconnue : $action');
    }
  }

  Future<void> _syncSale(Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    final saleData = Map<String, dynamic>.from(
      payload['sale'] as Map<String, dynamic>,
    );
    final itemsData = List<Map<String, dynamic>>.from(payload['items']);

    await supabase.from('sales').upsert(saleData);
    final rowsToInsert = itemsData.map((item) {
      final row = Map<String, dynamic>.from(item);
      row.remove('stock_movement_id');
      return row;
    }).toList();
    await supabase.from('sale_items').upsert(rowsToInsert);

    for (final item in itemsData) {
      await supabase.rpc(
        'apply_stock_movement',
        params: {
          'p_movement_id': item['stock_movement_id'],
          'p_shop_id': saleData['shop_id'],
          'p_product_id': item['product_id'],
          'p_quantity_delta': -(item['quantity'] as int),
          'p_type': 'sale',
        },
      );
    }
  }

  void dispose() {
    _statusController.close();
  }
}
