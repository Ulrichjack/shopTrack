// lib/features/sales/presentation/providers/sale_provider.dart

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/entities/sale_item_entity.dart';
import 'cart_provider.dart';

class SaleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createSale(List<SaleItemEntity> items, double totalAmount, double totalProfit) async {
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      String shopId = '';
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'offline_user';

      if (isOnline && userId != 'offline_user') {
        try {
          final memberResponse = await Supabase.instance.client.from('shop_members').select('shop_id').eq('user_id', userId).single();
          shopId = memberResponse['shop_id'] as String;
        } catch (e) {
          final products = ref.read(productProvider).value;
          if (products != null && products.isNotEmpty) shopId = products.first.shopId;
        }
      } else {
        final products = ref.read(productProvider).value;
        if (products != null && products.isNotEmpty) {
          shopId = products.first.shopId;
        } else {
          throw Exception('Impossible de finaliser la vente hors-ligne (ID boutique introuvable).');
        }
      }

      final saleId = const Uuid().v4();
      final now = DateTime.now();

      // 1. Sauvegarder la vente en LOCAL
      await db.into(db.localSales).insert(
        LocalSale(
          id: saleId,
          shopId: shopId,
          userId: userId,
          totalAmount: totalAmount,
          totalProfit: totalProfit,
          createdAt: now,
        ),
      );

      // 2. Sauvegarder les articles vendus en LOCAL et mettre à jour le stock
      for (var item in items) {
        final itemId = const Uuid().v4();

        await db.into(db.localSaleItems).insert(
          LocalSaleItem(
            id: itemId,
            saleId: saleId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            sellPrice: item.sellPrice,
            buyPrice: item.buyPrice,
            profit: item.profit,
          ),
        );

        // Mise à jour du stock local
        final localProduct = await (db.select(db.localProducts)..where((t) => t.id.equals(item.productId))).getSingle();
        final newQty = localProduct.quantity - item.quantity;
        await (db.update(db.localProducts)..where((t) => t.id.equals(item.productId))).write(
          LocalProductsCompanion(quantity: drift.Value(newQty)),
        );
      }

      // 3. Mettre dans la SALLE D'ATTENTE pour Supabase
      final payload = {
        'sale': {
          'id': saleId,
          'shop_id': shopId,
          'user_id': userId,
          'total_amount': totalAmount,
          'total_profit': totalProfit,
          'created_at': now.toIso8601String(),
        },
        'items': items.map((i) => {
          'sale_id': saleId,
          'product_id': i.productId,
          'product_name': i.productName,
          'quantity': i.quantity,
          'sell_price': i.sellPrice,
          'buy_price': i.buyPrice,
          'profit': i.profit,
        }).toList(),
      };
      await db.addToQueue('CREATE_SALE', jsonEncode(payload));

      ref.read(syncServiceProvider).processQueue();


      // 4. Rafraîchir les données
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(productProvider); // Pour mettre à jour la liste des produits

      ref.invalidate(dashboardProvider);

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final saleProvider = AsyncNotifierProvider<SaleNotifier, void>(() {
  return SaleNotifier();
});