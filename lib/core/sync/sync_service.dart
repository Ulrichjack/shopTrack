import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../providers/current_shop_provider.dart';

final localDbProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref.read(localDbProvider), ref);
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
  SyncService(this.db, this.ref);

  final AppDatabase db;

  /// Sert à connaître la boutique active. La synchro ne la décide pas : elle
  /// travaille sur celle que le commerçant a choisie.
  final Ref ref;
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
    await pullDataFromSupabase();
  }

  Future<void> pullDataFromSupabase() async {
    // Ne JAMAIS écraser les données locales tant qu'une écriture n'est pas
    // partie : le serveur ignore encore cette vente, donc son stock est
    // périmé. La garde vit ici et pas chez l'appelant, sinon un appel direct
    // (dashboard, bilan) la contourne et fait « remonter » le stock vendu.
    if (_isPulling || await db.getPendingCount() > 0) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isPulling = true;
    _emit(
      phase: SyncPhase.downloading,
      pendingCount: await db.getPendingCount(),
    );

    try {
      // La boutique active, pas « la » boutique du compte : `.single()`
      // supposait un seul rattachement et levait une exception dès le
      // deuxième. Le patron en a trois.
      final shopId = await ref.read(currentShopIdProvider.future);
      if (shopId == null || shopId.isEmpty) {
        // Rien à télécharger tant qu'aucune boutique n'est choisie : la
        // première connexion la renseigne, la synchro suivra.
        _emit(phase: SyncPhase.idle, pendingCount: await db.getPendingCount());
        return;
      }

      // Une table absente côté serveur ne doit pas emporter tout le
      // téléchargement. Vu en vrai : la migration `product_prices` pas encore
      // appliquée, et plus aucun produit ni comptage ne descendait. Le pull
      // fusionne sans jamais vider, donc une table vide est sans danger — on
      // note l'échec et on continue avec les autres.
      final tablesEnEchec = <String>[];
      Future<List<dynamic>> tirer(String nom, Future<dynamic> requete) async {
        try {
          return (await requete) as List<dynamic>;
        } catch (erreur) {
          // Bruyant dans les logs : depuis que le pull survit à une table
          // absente, un échec ne casse plus rien de visible — l'app affiche
          // juste des données manquantes sans dire pourquoi. Sans cette trace,
          // le diagnostic redevient de la devinette.
          debugPrint('[SYNC] échec du téléchargement de $nom : $erreur');
          tablesEnEchec.add(nom);
          return const [];
        }
      }

      final results = await Future.wait([
        tirer(
          'products',
          supabase.from('products').select().eq('shop_id', shopId),
        ),
        tirer(
          'cash_movements',
          supabase.from('cash_movements').select().eq('shop_id', shopId),
        ),
        tirer('sales', supabase.from('sales').select().eq('shop_id', shopId)),
        tirer(
          'sale_items',
          supabase
              .from('sale_items')
              .select('*, sales!inner(shop_id)')
              .eq('sales.shop_id', shopId),
        ),
        tirer(
          'daily_closings',
          supabase.from('daily_closings').select().eq('shop_id', shopId),
        ),
        // Module A : sans ces trois-là, un 2e téléphone ne voit ni les
        // cycles ni les unités, donc ne peut pas vendre au plateau.
        tirer(
          'supply_cycles',
          supabase.from('supply_cycles').select().eq('shop_id', shopId),
        ),
        tirer(
          'product_units',
          supabase
              .from('product_units')
              .select('*, products!inner(shop_id)')
              .eq('products.shop_id', shopId),
        ),
        tirer(
          'cycle_losses',
          supabase
              .from('cycle_losses')
              .select('*, supply_cycles!inner(shop_id)')
              .eq('supply_cycles.shop_id', shopId),
        ),
        // Module B : la recette locale doit revenir après connexion sur un
        // autre téléphone, au même titre que les autres données métier.
        tirer(
          'shop_takings',
          supabase.from('shop_takings').select().eq('shop_id', shopId),
        ),
        // Module B : les comptages sont des repères historiques. Sans ce
        // pull, un second téléphone ne peut ni reprendre ni terminer le tour.
        tirer(
          'inventory_counts',
          supabase.from('inventory_counts').select().eq('shop_id', shopId),
        ),
        // Les recharges sont poussées par apply_stock_movement mais n'étaient
        // jamais retéléchargées. Le rapport de période en tire ses `purchases` :
        // sans elles, les sorties valent « stock de départ − stock compté », le
        // réapprovisionnement disparaît du calcul et l'app annonce un bénéfice
        // surévalué avec un faux « tu as encaissé plus ». Le stock, lui, restait
        // juste : le bug était invisible sur l'écran Stock.
        tirer(
          'stock_movements',
          supabase.from('stock_movements').select().eq('shop_id', shopId),
        ),
        // Module B : sans les pertes déclarées, la casse d'un téléphone
        // redevient de l'inexpliqué sur l'autre — donc du vol présumé.
        tirer(
          'inventory_losses',
          supabase.from('inventory_losses').select().eq('shop_id', shopId),
        ),
        // Le prix payé voyage avec l'achat : sans ce pull, un second téléphone
        // revaloriserait tout au prix actuel du produit.
        tirer(
          'stock_purchases',
          supabase.from('stock_purchases').select().eq('shop_id', shopId),
        ),
        // Le tarif pratiqué pendant la période : sans lui, un second
        // téléphone revaloriserait tout au prix du jour.
        tirer(
          'product_prices',
          supabase.from('product_prices').select().eq('shop_id', shopId),
        ),
        // Les deux sens : la boutique voit ce qu'elle a envoyé ET ce qu'elle
        // doit recevoir. Sans le second, personne ne pourrait confirmer une
        // réception.
        tirer(
          'stock_transfers',
          supabase
              .from('stock_transfers')
              .select()
              .or('from_shop_id.eq.$shopId,to_shop_id.eq.$shopId'),
        ),
      ]);

      final productsData = results[0];
      final cashData = results[1];
      final salesData = results[2];
      final saleItemsData = results[3];
      final closingsData = results[4];
      final cyclesData = results[5];
      final unitsData = results[6];
      final lossesData = results[7];
      final takingsData = results[8];
      final inventoryCountsData = results[9];
      final stockMovementsData = results[10];
      final inventoryLossesData = results[11];
      final stockPurchasesData = results[12];
      final productPricesData = results[13];
      final transfersData = results[14];

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
                    unit: p['unit'] as String?,
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
                    // Module A : sans ces colonnes, le pull efface le lien
                    // vente ↔ cycle et le rapport retombe à 0 F.
                    cycleId: i['cycle_id'] as String?,
                    unitId: i['unit_id'] as String?,
                    quantityInBase: i['quantity_in_base'] as int?,
                    unitSellPrice: (i['unit_sell_price'] as num?)?.toDouble(),
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
          batch.insertAll(
            db.localSupplyCycles,
            cyclesData
                .map(
                  (c) => LocalSupplyCycle(
                    id: c['id'],
                    shopId: c['shop_id'],
                    productId: c['product_id'],
                    openedAt: DateTime.parse(c['opened_at']),
                    closedAt: c['closed_at'] == null
                        ? null
                        : DateTime.parse(c['closed_at']),
                    quantityReceived: c['quantity_received'],
                    purchaseCost: (c['purchase_cost'] as num).toDouble(),
                    referenceMarginPerUnit:
                        (c['reference_margin_per_unit'] as num?)?.toDouble(),
                    status: c['status'] ?? 'open',
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localProductUnits,
            unitsData
                .map(
                  (u) => LocalProductUnit(
                    id: u['id'],
                    productId: u['product_id'],
                    unitName: u['unit_name'],
                    ratioToBase: u['ratio_to_base'],
                    sortOrder: u['sort_order'] ?? 0,
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localCycleLosses,
            lossesData
                .map(
                  (l) => LocalCycleLossesData(
                    id: l['id'],
                    cycleId: l['cycle_id'],
                    quantity: l['quantity'],
                    reason: l['reason'],
                    note: l['note'],
                    createdAt: DateTime.parse(l['created_at']),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localShopTakings,
            takingsData
                .map(
                  (taking) => LocalShopTaking(
                    shopId: taking['shop_id'],
                    date: DateTime.parse(taking['date']),
                    amount: (taking['amount'] as num).toDouble(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localInventoryCounts,
            inventoryCountsData
                .map(
                  (count) => LocalInventoryCount(
                    id: count['id'],
                    shopId: count['shop_id'],
                    productId: count['product_id'],
                    countedAt: DateTime.parse(count['counted_at']).toLocal(),
                    countedQuantity: count['counted_quantity'],
                    previousCountedAt: count['previous_counted_at'] == null
                        ? null
                        : DateTime.parse(
                            count['previous_counted_at'],
                          ).toLocal(),
                    previousQuantity: count['previous_quantity'],
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localStockTransfers,
            transfersData
                .map(
                  (t) => LocalStockTransfer(
                    id: t['id'],
                    fromShopId: t['from_shop_id'],
                    toShopId: t['to_shop_id'],
                    productId: t['product_id'],
                    quantity: t['quantity'],
                    receivedQuantity: t['received_quantity'] as int?,
                    receivedAt: t['received_at'] == null
                        ? null
                        : DateTime.parse(t['received_at']).toLocal(),
                    transferredAt: DateTime.parse(
                      t['transferred_at'],
                    ).toLocal(),
                    note: t['note'] as String?,
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localProductPrices,
            productPricesData
                .map(
                  (p) => LocalProductPrice(
                    id: p['id'],
                    shopId: p['shop_id'],
                    productId: p['product_id'],
                    buyPrice: (p['buy_price'] as num).toDouble(),
                    sellPrice: (p['sell_price'] as num).toDouble(),
                    effectiveAt: DateTime.parse(p['effective_at']).toLocal(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localStockPurchases,
            stockPurchasesData
                .map(
                  (p) => LocalStockPurchase(
                    id: p['id'],
                    shopId: p['shop_id'],
                    productId: p['product_id'],
                    quantity: p['quantity'],
                    unitCost: (p['unit_cost'] as num).toDouble(),
                    purchasedAt: DateTime.parse(p['purchased_at']).toLocal(),
                    note: p['note'] as String?,
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localInventoryLosses,
            inventoryLossesData
                .map(
                  (l) => LocalInventoryLoss(
                    id: l['id'],
                    shopId: l['shop_id'],
                    productId: l['product_id'],
                    quantity: l['quantity'],
                    reason: l['reason'],
                    note: l['note'] as String?,
                    occurredAt: DateTime.parse(l['occurred_at']).toLocal(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
          batch.insertAll(
            db.localStockMovements,
            stockMovementsData
                .map(
                  (m) => LocalStockMovement(
                    id: m['id'],
                    shopId: m['shop_id'],
                    productId: m['product_id'],
                    quantity: m['quantity'],
                    type: m['type'],
                    createdAt: DateTime.parse(m['created_at']).toLocal(),
                  ),
                )
                .toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
      });

      debugPrint(
        '[SYNC] téléchargement terminé — '
        '${productsData.length} produits, ${inventoryCountsData.length} '
        'comptages, ${takingsData.length} recettes'
        '${tablesEnEchec.isEmpty ? '' : ' — ÉCHECS : ${tablesEnEchec.join(', ')}'}',
      );
      _emit(
        phase: tablesEnEchec.isEmpty ? SyncPhase.success : SyncPhase.error,
        pendingCount: await db.getPendingCount(),
        lastSyncAt: tablesEnEchec.isEmpty ? DateTime.now() : null,
        lastError: tablesEnEchec.isEmpty
            ? null
            : 'Tables non téléchargées : ${tablesEnEchec.join(', ')}. '
                  'Une migration Supabase n\'a probablement pas été appliquée.',
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
          // Bruyant : un échec d'envoi bloque toute la file derrière lui, et
          // sans trace on ne voit qu'un compteur d'opérations qui ne descend
          // plus. Le nom de l'action dit tout de suite laquelle coince.
          debugPrint('[SYNC] échec de l\'envoi ${item.action} : $error');
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
      case 'SET_SHOP_SETTINGS':
        await supabase
            .from('shop_settings')
            .upsert(payload, onConflict: 'shop_id');
      case 'ADD_SHOP_TAKINGS':
        await supabase
            .from('shop_takings')
            .upsert(payload, onConflict: 'shop_id,date');
      case 'ADD_INVENTORY_COUNT':
        await supabase.from('inventory_counts').upsert(payload);
      case 'ADD_INVENTORY_LOSS':
        await supabase.from('inventory_losses').upsert(payload);
      case 'ADD_STOCK_PURCHASE':
        await supabase.from('stock_purchases').upsert(payload);
      case 'ADD_PRODUCT_PRICE':
        await supabase.from('product_prices').upsert(payload);
      case 'ADD_STOCK_TRANSFER':
        await supabase.from('stock_transfers').upsert(payload);
      case 'CONFIRM_STOCK_TRANSFER':
        await supabase
            .from('stock_transfers')
            .update({
              'received_quantity': payload['received_quantity'],
              'received_at': payload['received_at'],
            })
            .eq('id', payload['id']);
      case 'ADD_SUPPLY_CYCLE':
        await supabase.from('supply_cycles').upsert(payload);
      case 'CLOSE_SUPPLY_CYCLE':
        await supabase
            .from('supply_cycles')
            .update({
              'status': payload['status'],
              'closed_at': payload['closed_at'],
            })
            .eq('id', payload['id']);
      case 'ADD_PRODUCT_UNIT':
        await supabase.from('product_units').upsert(payload);
      case 'DELETE_PRODUCT_UNIT':
        await supabase.from('product_units').delete().eq('id', payload['id']);
      case 'ADD_CYCLE_LOSS':
        await supabase.from('cycle_losses').upsert(payload);
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
