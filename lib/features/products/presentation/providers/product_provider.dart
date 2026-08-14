// lib/features/products/presentation/providers/product_provider.dart

import 'dart:convert';
import 'dart:io' as import_io;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../domain/entities/product_entity.dart';

class ProductNotifier extends AsyncNotifier<List<ProductEntity>> {
  @override
  Future<List<ProductEntity>> build() async {
    return _fetchProducts();
  }

  Future<List<ProductEntity>> _fetchProducts() async {
    final db = ref.read(localDbProvider);
    final localProducts = await db.select(db.localProducts).get();

    return localProducts.map(_toEntity).toList();
  }

  ProductEntity _toEntity(LocalProduct p) => ProductEntity(
    id: p.id,
    shopId: p.shopId,
    name: p.name,
    buyPrice: p.buyPrice,
    sellPrice: p.sellPrice,
    quantity: p.quantity,
    minQuantity: p.minQuantity,
    barcode: p.barcode,
    photoUrl: p.photoUrl,
  );

  Future<void> _cacheProduct(Map<String, dynamic> data) async {
    final db = ref.read(localDbProvider);
    await db
        .into(db.localProducts)
        .insert(
          LocalProduct(
            id: data['id'] as String,
            shopId: data['shop_id'] as String,
            name: data['name'] as String,
            buyPrice: (data['buy_price'] as num).toDouble(),
            sellPrice: (data['sell_price'] as num).toDouble(),
            quantity: data['quantity'] as int,
            minQuantity: data['min_quantity'] as int,
            barcode: data['barcode'] as String?,
            photoUrl: data['photo_url'] as String?,
            unit: data['unit'] as String?,
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> _ensureBarcodeAvailable({
    required String barcode,
    required String shopId,
    String? excludedProductId,
    required bool isOnline,
  }) async {
    final db = ref.read(localDbProvider);
    final localMatches = await (db.select(
      db.localProducts,
    )..where((product) => product.barcode.equals(barcode))).get();
    final localConflict = localMatches
        .where((product) => product.id != excludedProductId)
        .firstOrNull;
    if (localConflict != null) {
      throw Exception(
        'Ce QR/code-barres est déjà utilisé par « ${localConflict.name} ». '
        'Chaque produit doit avoir un code différent.',
      );
    }

    if (!isOnline || Supabase.instance.client.auth.currentUser == null) return;

    final remoteMatches = await Supabase.instance.client
        .from('products')
        .select('id,name')
        .eq('shop_id', shopId)
        .eq('barcode', barcode)
        .limit(2);
    final remoteConflict = remoteMatches
        .where((product) => product['id'] != excludedProductId)
        .firstOrNull;
    if (remoteConflict != null) {
      throw Exception(
        'Ce QR/code-barres est déjà utilisé par '
        '« ${remoteConflict['name']} » dans Supabase.',
      );
    }
  }

  /// Recherche fiable pour le scanner : cache local, puis Supabase.
  Future<ProductEntity?> findByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) return null;

    final db = ref.read(localDbProvider);
    final local =
        await (db.select(db.localProducts)
              ..where((product) => product.barcode.equals(barcode))
              ..orderBy([(product) => drift.OrderingTerm.asc(product.name)])
              ..limit(1))
            .getSingleOrNull();
    if (local != null) return _toEntity(local);

    final isOnline = ref.read(connectivityProvider).value ?? false;
    if (!isOnline || Supabase.instance.client.auth.currentUser == null) {
      return null;
    }

    // Envoie d'abord un produit éventuellement créé sur cet appareil.
    await ref.read(syncServiceProvider).processQueue();

    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('cached_shop_id');
    if (shopId == null || shopId.isEmpty) return null;

    final remote = await Supabase.instance.client
        .from('products')
        .select()
        .eq('shop_id', shopId)
        .eq('barcode', barcode)
        .order('name')
        .limit(1)
        .maybeSingle();
    if (remote == null) return null;

    await _cacheProduct(remote);
    final products = await _fetchProducts();
    state = AsyncValue.data(products);
    return products.where((product) => product.id == remote['id']).firstOrNull;
  }

  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    String? unit,
    import_io.File? imageFile,
  }) async {
    final previousProducts = state.value ?? await _fetchProducts();
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      String shopId = '';

      if (isOnline) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final memberResponse = await Supabase.instance.client
            .from('shop_members')
            .select('shop_id')
            .eq('user_id', userId!)
            .single();
        shopId = memberResponse['shop_id'] as String;
      } else {
        if (previousProducts.isEmpty) {
          throw Exception(
            'Connectez-vous à internet au moins une fois pour synchroniser votre boutique.',
          );
        }
        shopId = previousProducts.first.shopId;
      }

      String? photoUrl;

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().microsecondsSinceEpoch}-${const Uuid().v4()}'
          : barcode.trim();
      await _ensureBarcodeAvailable(
        barcode: finalBarcode,
        shopId: shopId,
        isOnline: isOnline,
      );

      if (isOnline && imageFile != null) {
        final fileName =
            '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, imageFile);
        photoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final newId = const Uuid().v4();

      final productData = {
        'id': newId,
        'shop_id': shopId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'barcode': finalBarcode,
        'photo_url': photoUrl,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };

      await db
          .into(db.localProducts)
          .insert(
            LocalProduct(
              id: newId,
              shopId: shopId,
              name: name,
              buyPrice: buyPrice,
              sellPrice: sellPrice,
              quantity: quantity,
              minQuantity: minQuantity,
              barcode: finalBarcode,
              photoUrl: photoUrl,
              unit: (unit == null || unit.trim().isEmpty) ? null : unit.trim(),
            ),
          );

      await db.addToQueue('ADD_PRODUCT', jsonEncode(productData));
      await ref.read(syncServiceProvider).processQueue();
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    String? unit,
    String? existingPhotoUrl,
    import_io.File? newImageFile,
  }) async {
    final previousProducts = state.value ?? await _fetchProducts();
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      if (previousProducts.isEmpty) {
        throw Exception('Boutique introuvable. Synchronisez les produits.');
      }
      final shopId = previousProducts.first.shopId;

      String? finalPhotoUrl = existingPhotoUrl;

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().microsecondsSinceEpoch}-${const Uuid().v4()}'
          : barcode.trim();
      await _ensureBarcodeAvailable(
        barcode: finalBarcode,
        shopId: shopId,
        excludedProductId: id,
        isOnline: isOnline,
      );

      if (isOnline && newImageFile != null) {
        final fileName =
            '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product-photos')
            .upload(fileName, newImageFile);
        finalPhotoUrl = Supabase.instance.client.storage
            .from('product-photos')
            .getPublicUrl(fileName);
      }

      final productData = {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'barcode': finalBarcode,
        'photo_url': finalPhotoUrl,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };

      await (db.update(db.localProducts)..where((t) => t.id.equals(id))).write(
        LocalProductsCompanion(
          name: drift.Value(name),
          buyPrice: drift.Value(buyPrice),
          sellPrice: drift.Value(sellPrice),
          quantity: drift.Value(quantity),
          minQuantity: drift.Value(minQuantity),
          barcode: drift.Value(finalBarcode),
          photoUrl: drift.Value(finalPhotoUrl),
          unit: drift.Value(
            (unit == null || unit.trim().isEmpty) ? null : unit.trim(),
          ),
        ),
      );

      await db.addToQueue('UPDATE_PRODUCT', jsonEncode(productData));
      await ref.read(syncServiceProvider).processQueue();

      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      state = AsyncValue.data(await _fetchProducts());
      rethrow;
    }
  }

  // 👇 NOUVEAU : Fonction pour ajouter du stock (100% Local + File d'attente)
  Future<void> addStock(ProductEntity product, int addedQuantity) async {
    try {
      final db = ref.read(localDbProvider);
      final newQty = product.quantity + addedQuantity;

      // 1. Mettre à jour la quantité en local
      await (db.update(db.localProducts)..where((t) => t.id.equals(product.id)))
          .write(LocalProductsCompanion(quantity: drift.Value(newQty)));

      // 2. Ajouter l'historique de recharge en local
      final movementId = const Uuid().v4();
      await db
          .into(db.localStockMovements)
          .insert(
            LocalStockMovement(
              id: movementId,
              shopId: product.shopId,
              productId: product.id,
              quantity: addedQuantity,
              type: 'recharge',
              createdAt: DateTime.now(),
            ),
          );

      // 3. Mettre dans la salle d'attente pour Supabase
      final payload = {
        'movement_id': movementId,
        'product_id': product.id,
        'shop_id': product.shopId,
        'quantity': addedQuantity,
        'type': 'recharge',
      };
      await db.addToQueue('ADD_STOCK', jsonEncode(payload));
      await ref.read(syncServiceProvider).processQueue();

      // 4. Rafraîchir l'écran
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      rethrow;
    }
  }
}

/// Unités déjà utilisées dans cette boutique, les plus fréquentes d'abord.
/// Propre à la boutique par construction (les produits le sont), donc un
/// dépôt de boissons et une épicerie n'auront jamais les mêmes suggestions.
final knownUnitsProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productProvider).value ?? const [];
  final counts = <String, int>{};
  for (final product in products) {
    final unit = product.unit?.trim();
    if (unit == null || unit.isEmpty) continue;
    counts[unit] = (counts[unit] ?? 0) + 1;
  }
  final units = counts.keys.toList()
    ..sort((a, b) {
      final byUse = counts[b]!.compareTo(counts[a]!);
      return byUse != 0 ? byUse : a.compareTo(b);
    });
  return units;
});

final productProvider =
    AsyncNotifierProvider<ProductNotifier, List<ProductEntity>>(() {
      return ProductNotifier();
    });
