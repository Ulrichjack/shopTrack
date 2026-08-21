import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/products/presentation/providers/product_provider.dart';

void main() {
  // `_fetchProducts` filtre désormais par boutique : il lui faut une boutique
  // active, comme en vrai.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});

  late AppDatabase db;
  late SyncService syncSansReseau;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        localDbProvider.overrideWithValue(db),
        // `overrideWith` et non `overrideWithValue` : le service a besoin du
        // ref pour connaître la boutique active, comme en production.
        syncServiceProvider.overrideWith(
          (ref) => _SyncServiceSansReseau(db, ref),
        ),
      ],
    );
    syncSansReseau = container.read(syncServiceProvider);
    await db.into(db.localProducts).insert(_produit());
  });

  tearDown(() async {
    container.dispose();
    syncSansReseau.dispose();
    await db.close();
  });

  test('addStock sans prix préserve les modes simple et cycles', () async {
    final produit = (await container.read(productProvider.future)).single;

    // Ces deux modes utilisent cette signature historique : créer des lignes
    // du module B ici polluerait leurs prix et bloquerait leur synchronisation.
    await container.read(productProvider.notifier).addStock(produit, 5);

    expect(await db.select(db.localStockPurchases).get(), isEmpty);
    expect(await db.select(db.localProductPrices).get(), isEmpty);

    final actualise = await db.select(db.localProducts).getSingle();
    expect(actualise.quantity, 15);
    expect(actualise.buyPrice, 100);
    expect(actualise.sellPrice, 150);

    final file = await db.getPendingItems();
    expect(file.map((item) => item.action), ['ADD_STOCK']);
  });

  test('addStock avec nouveaux prix fige achat et tarif', () async {
    final produit = (await container.read(productProvider.future)).single;

    await container
        .read(productProvider.notifier)
        .addStock(produit, 4, unitCost: 120, sellPrice: 180);

    final achats = await db.select(db.localStockPurchases).get();
    expect(achats, hasLength(1));
    expect(achats.single.quantity, 4);
    expect(achats.single.unitCost, 120);

    // DEUX lignes : le premier changement grave d'abord l'ancien tarif, sinon
    // le calcul d'inventaire retombe sur le nouveau pour toute la période
    // antérieure et revalorise un bilan déjà consulté.
    final tarifs = await db.select(db.localProductPrices).get()
      ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));
    expect(tarifs, hasLength(2));
    expect(tarifs.first.buyPrice, 100, reason: 'l\'ancien prix d\'achat');
    expect(tarifs.first.sellPrice, 150, reason: 'l\'ancien prix de vente');
    expect(tarifs.last.buyPrice, 120);
    expect(tarifs.last.sellPrice, 180);

    final actualise = await db.select(db.localProducts).getSingle();
    expect(actualise.buyPrice, 120);
    expect(actualise.sellPrice, 180);

    expect(
      (await db.getPendingItems()).map((item) => item.action),
      unorderedEquals([
        'ADD_STOCK',
        'UPDATE_PRODUCT',
        // Deux tarifs : l'ancien gravé avant le premier changement, puis le
        // nouveau. Sans le premier, une hausse revalorise une période close.
        'ADD_PRODUCT_PRICE',
        'ADD_PRODUCT_PRICE',
        'ADD_STOCK_PURCHASE',
      ]),
    );
  });

  test('addStock avec prix identiques ne duplique pas le tarif', () async {
    final produit = (await container.read(productProvider.future)).single;

    await container
        .read(productProvider.notifier)
        .addStock(produit, 3, unitCost: 100, sellPrice: 150);

    expect(await db.select(db.localStockPurchases).get(), hasLength(1));
    expect(await db.select(db.localProductPrices).get(), isEmpty);
    expect(
      (await db.getPendingItems()).map((item) => item.action),
      unorderedEquals(['ADD_STOCK', 'ADD_STOCK_PURCHASE']),
    );
  });

  test(
    'le stock affiché est celui de la boutique active, pas des autres',
    () async {
      // La base locale garde les produits de TOUTES les boutiques du compte.
      // Sans filtre, ouvrir une boutique neuve affichait le stock d'une autre —
      // et un arrivage serait allé au mauvais endroit sans que rien ne le dise.
      await db
          .into(db.localProducts)
          .insert(
            LocalProduct(
              id: 'produit-autre-boutique',
              shopId: 'shop-2',
              name: 'Riz de la boutique 2',
              buyPrice: 100,
              sellPrice: 150,
              quantity: 99,
              minQuantity: 1,
            ),
          );

      final produits = await container.read(productProvider.future);
      expect(
        produits.map((p) => p.shopId).toSet(),
        {'shop-1'},
        reason: 'aucun produit d\'une autre boutique ne doit apparaître',
      );
    },
  );
}

LocalProduct _produit() => const LocalProduct(
  id: 'product-1',
  shopId: 'shop-1',
  name: 'Riz',
  buyPrice: 100,
  sellPrice: 150,
  quantity: 10,
  minQuantity: 2,
);

class _SyncServiceSansReseau extends SyncService {
  _SyncServiceSansReseau(super.db, super.ref);

  @override
  Future<void> processQueue() async {}
}
