// lib/features/products/presentation/providers/product_provider.dart

import 'dart:convert';
import 'dart:io' as import_io;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return localProducts.map((p) => ProductEntity(
      id: p.id,
      shopId: p.shopId,
      name: p.name,
      buyPrice: p.buyPrice,
      sellPrice: p.sellPrice,
      quantity: p.quantity,
      minQuantity: p.minQuantity,
      barcode: p.barcode,
      photoUrl: p.photoUrl,
    )).toList();
  }

  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required int minQuantity,
    String? barcode,
    import_io.File? imageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      String shopId = '';

      if (isOnline) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final memberResponse = await Supabase.instance.client.from('shop_members').select('shop_id').eq('user_id', userId!).single();
        shopId = memberResponse['shop_id'] as String;
      } else {
        final currentProducts = state.value ?? [];
        if (currentProducts.isEmpty) {
          throw Exception('Connectez-vous à internet au moins une fois pour synchroniser votre boutique.');
        }
        shopId = currentProducts.first.shopId;
      }

      String? photoUrl;

      if (isOnline && imageFile != null) {
        final fileName = '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('product-photos').upload(fileName, imageFile);
        photoUrl = Supabase.instance.client.storage.from('product-photos').getPublicUrl(fileName);
      }

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().millisecondsSinceEpoch}'
          : barcode.trim();

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
      };

      await db.into(db.localProducts).insert(
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
        ),
      );

      await db.addToQueue('ADD_PRODUCT', jsonEncode(productData));
      ref.read(syncServiceProvider).processQueue();
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
    String? existingPhotoUrl,
    import_io.File? newImageFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      final currentProducts = state.value ?? [];
      final shopId = currentProducts.first.shopId;

      String? finalPhotoUrl = existingPhotoUrl;

      if (isOnline && newImageFile != null) {
        final fileName = '${shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('product-photos').upload(fileName, newImageFile);
        finalPhotoUrl = Supabase.instance.client.storage.from('product-photos').getPublicUrl(fileName);
      }

      final String finalBarcode = (barcode == null || barcode.trim().isEmpty)
          ? 'QR-${DateTime.now().millisecondsSinceEpoch}'
          : barcode.trim();

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
        ),
      );

      await db.addToQueue('UPDATE_PRODUCT', jsonEncode(productData));
      ref.read(syncServiceProvider).processQueue();

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
      await (db.update(db.localProducts)..where((t) => t.id.equals(product.id))).write(
        LocalProductsCompanion(quantity: drift.Value(newQty)),
      );

      // 2. Ajouter l'historique de recharge en local
      final movementId = const Uuid().v4();
      await db.into(db.localStockMovements).insert(
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
        'product_id': product.id,
        'shop_id': product.shopId,
        'quantity': addedQuantity,
        'type': 'recharge',
        'new_total_quantity': newQty,
      };
      await db.addToQueue('ADD_STOCK', jsonEncode(payload));
      ref.read(syncServiceProvider).processQueue();


      // 4. Rafraîchir l'écran
      state = AsyncValue.data(await _fetchProducts());
    } catch (e) {
      rethrow;
    }
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<ProductEntity>>(() {
  return ProductNotifier();
});