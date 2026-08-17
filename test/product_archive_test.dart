import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/products/presentation/providers/product_provider.dart';

/// L'archivage est la sortie d'un produit qui a une histoire.
///
/// La suppression ne peut pas jouer ce rôle : effacer un produit cité par une
/// période close réécrirait un bilan déjà consulté — le rapport de mars
/// perdrait une ligne et changerait de bénéfice. Ce qu'on vérifie ici, c'est
/// que l'archivage retire le produit de la vente **sans toucher à son passé**,
/// et qu'il est réversible.
void main() {
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

  test('un produit archivé quitte le stock mais reste en base', () async {
    expect(await container.read(productProvider.future), hasLength(1));

    await container.read(productProvider.notifier).archiveProduct('product-1');

    expect(
      container.read(productProvider).value,
      isEmpty,
      reason: 'il ne doit plus apparaître au stock, au comptage ni à la vente',
    );

    // Mais la ligne est toujours là : c'est ce qui garde justes les périodes
    // closes qui la citent.
    final enBase = await db.select(db.localProducts).getSingle();
    expect(enBase.id, 'product-1');
    expect(enBase.archivedAt, isNotNull);
    expect(enBase.quantity, 10, reason: 'archiver ne touche pas au stock');
  });

  test('l’archivage part au serveur, sinon l’autre téléphone le vend', () async {
    await container.read(productProvider.notifier).archiveProduct('product-1');

    final file = await db.getPendingItems();
    expect(file.map((item) => item.action), ['UPDATE_PRODUCT']);

    final charge = jsonDecode(file.single.payload) as Map<String, dynamic>;
    expect(charge['id'], 'product-1');
    expect(charge['archived_at'], isNotNull);
  });

  test('on peut le ressortir du placard', () async {
    await container.read(productProvider.notifier).archiveProduct('product-1');
    expect(container.read(productProvider).value, isEmpty);

    await container
        .read(productProvider.notifier)
        .unarchiveProduct('product-1');

    expect(container.read(productProvider).value, hasLength(1));
    expect((await db.select(db.localProducts).getSingle()).archivedAt, isNull);

    final derniere = (await db.getPendingItems()).last;
    expect(
      (jsonDecode(derniere.payload) as Map<String, dynamic>)['archived_at'],
      isNull,
      reason: 'le serveur doit apprendre le retour, pas seulement le départ',
    );
  });

  test('le placard se consulte, sinon archiver serait sans retour', () async {
    await container.read(productProvider.notifier).archiveProduct('product-1');

    final archives = await container
        .read(productProvider.notifier)
        .fetchArchivedProducts();

    expect(archives, hasLength(1));
    expect(archives.single.name, 'Riz');
    expect(archives.single.estArchive, isTrue);
  });

  test('supprimer un produit qui a une histoire est refusé, pas fait à moitié', () async {
    await db
        .into(db.localSaleItems)
        .insert(
          const LocalSaleItem(
            id: 'ligne-1',
            saleId: 'vente-1',
            productId: 'product-1',
            productName: 'Riz',
            quantity: 2,
            sellPrice: 150,
            buyPrice: 100,
            profit: 100,
          ),
        );

    await expectLater(
      container.read(productProvider.notifier).deleteProduct('product-1'),
      throwsA(isA<ProduitAvecHistoireException>()),
    );

    expect(
      await db.select(db.localProducts).get(),
      hasLength(1),
      reason: 'le refus doit être total : rien de supprimé, rien en file',
    );
    expect(await db.getPendingItems(), isEmpty);
  });
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
