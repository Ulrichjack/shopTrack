import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/inventory/presentation/providers/inventory_count_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('un nouveau repère fige le comptage précédent du produit', () async {
    await db.into(db.localProducts).insert(_product('product-1', 'Riz'));
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final actions = container.read(inventoryCountActionsProvider);
    final first = await actions.saveCount(
      productId: 'product-1',
      countedQuantity: 18,
    );
    final second = await actions.saveCount(
      productId: 'product-1',
      countedQuantity: 12,
    );

    expect(second.previousCountedAt, first.countedAt);
    expect(second.previousQuantity, 18);
    expect(await db.select(db.localInventoryCounts).get(), hasLength(2));

    // Compter aligne aussi le stock affiché sur la réalité constatée,
    // sinon l'écran Stock continue d'annoncer l'ancienne quantité.
    final product = await (db.select(
      db.localProducts,
    )..where((row) => row.id.equals('product-1'))).getSingle();
    expect(product.quantity, 12);

    // 2 comptages + 2 ajustements de stock.
    expect(await db.getPendingCount(), 4);
  });

  test(
    'la progression survit produit par produit puis devient complète',
    () async {
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _product('product-1', 'Riz'),
          _product('product-2', 'Sucre'),
          _product('product-3', 'Jus'),
        ]);
        batch.insert(
          db.localInventoryCounts,
          _count('count-1', 'product-1', 8),
        );
      });

      final partial = await loadInventoryCountOverview(db, 'shop-1');
      expect(partial.countedProducts, 1);
      expect(partial.totalProducts, 3);
      expect(partial.isRoundComplete, isFalse);

      await db.batch((batch) {
        batch.insert(
          db.localInventoryCounts,
          _count('count-2', 'product-2', 5),
        );
        batch.insert(
          db.localInventoryCounts,
          _count('count-3', 'product-3', 11),
        );
      });

      final complete = await loadInventoryCountOverview(db, 'shop-1');
      expect(complete.countedProducts, 3);
      expect(complete.isRoundComplete, isTrue);
    },
  );
}

LocalProduct _product(String id, String name) => LocalProduct(
  id: id,
  shopId: 'shop-1',
  name: name,
  buyPrice: 100,
  sellPrice: 150,
  quantity: 10,
  minQuantity: 1,
);

LocalInventoryCount _count(String id, String productId, int quantity) =>
    LocalInventoryCount(
      id: id,
      shopId: 'shop-1',
      productId: productId,
      countedAt: DateTime(2026, 8, 13, 12),
      countedQuantity: quantity,
    );
