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
import '../../domain/entities/sale_item_entity.dart';
import 'cart_provider.dart';

class SaleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createSale(
    List<SaleItemEntity> items,
    double totalAmount,
    double totalProfit,
  ) async {
    state = const AsyncValue.loading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? true;
      final db = ref.read(localDbProvider);

      String shopId = '';
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? 'offline_user';

      if (isOnline && userId != 'offline_user') {
        try {
          final memberResponse = await Supabase.instance.client
              .from('shop_members')
              .select('shop_id')
              .eq('user_id', userId)
              .single();
          shopId = memberResponse['shop_id'] as String;
        } catch (e) {
          final products = ref.read(productProvider).value;
          if (products != null && products.isNotEmpty)
            shopId = products.first.shopId;
        }
      } else {
        final products = ref.read(productProvider).value;
        if (products != null && products.isNotEmpty) {
          shopId = products.first.shopId;
        } else {
          throw Exception(
            'Impossible de finaliser la vente hors-ligne (ID boutique introuvable).',
          );
        }
      }

      final saleId = const Uuid().v4();
      final now = DateTime.now();

      final itemPayloads = <Map<String, dynamic>>[];
      await db.transaction(() async {
        await db
            .into(db.localSales)
            .insert(
              LocalSale(
                id: saleId,
                shopId: shopId,
                userId: userId,
                totalAmount: totalAmount,
                totalProfit: totalProfit,
                createdAt: now,
              ),
            );

        for (final item in items) {
          final itemId = const Uuid().v4();
          final stockMovementId = const Uuid().v4();
          final localProduct = await (db.select(
            db.localProducts,
          )..where((product) => product.id.equals(item.productId))).getSingle();
          if (item.quantity <= 0 || localProduct.quantity < item.quantity) {
            throw Exception(
              'Stock insuffisant pour ${item.productName} '
              '(disponible : ${localProduct.quantity}).',
            );
          }

          await db
              .into(db.localSaleItems)
              .insert(
                LocalSaleItem(
                  id: itemId,
                  saleId: saleId,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  sellPrice: item.sellPrice,
                  buyPrice: item.buyPrice,
                  profit: item.profit,
                  cycleId: item.cycleId,
                  unitId: item.unitId,
                  // Module A : quantité/prix déjà exprimés en unité de base
                  // pour toute la ligne (voir cycle_result_calculator.dart).
                  quantityInBase: item.cycleId != null ? item.quantity : null,
                  unitSellPrice: item.cycleId != null ? item.sellPrice : null,
                ),
              );
          await (db.update(
            db.localProducts,
          )..where((product) => product.id.equals(item.productId))).write(
            LocalProductsCompanion(
              quantity: drift.Value(localProduct.quantity - item.quantity),
            ),
          );

          itemPayloads.add({
            'id': itemId,
            'sale_id': saleId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'sell_price': item.sellPrice,
            'buy_price': item.buyPrice,
            'profit': item.profit,
            // Colonnes Module A ajoutées seulement pour une vente de cycle :
            // une vente simple envoie exactement le même payload qu'avant, et
            // reste donc valide même sur une base où la migration Module A
            // n'a pas encore été appliquée.
            if (item.cycleId != null) ...{
              'cycle_id': item.cycleId,
              'unit_id': item.unitId,
              'quantity_in_base': item.quantity,
              'unit_sell_price': item.sellPrice,
            },
            // Champ interne retiré avant insertion distante.
            'stock_movement_id': stockMovementId,
          });
        }

        final payload = {
          'sale': {
            'id': saleId,
            'shop_id': shopId,
            'user_id': userId,
            'total_amount': totalAmount,
            'total_profit': totalProfit,
            'created_at': now.toIso8601String(),
          },
          'items': itemPayloads,
        };
        await db.addToQueue('CREATE_SALE', jsonEncode(payload));
      });

      await ref.read(syncServiceProvider).processQueue();

      // 4. Rafraîchir les données
      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(
        productProvider,
      ); // Pour mettre à jour la liste des produits

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
