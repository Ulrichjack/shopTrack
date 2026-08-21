import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/cycles/presentation/providers/product_unit_provider.dart';

/// La première unité d'un produit doit être sa base (ratio 1).
///
/// Sans elle, la vente au détail n'a aucune unité de ratio 1 à proposer, et
/// le reste de stock ne peut plus s'exprimer. Rien ne l'imposait avant : on
/// pouvait créer « plateau = 30 » sans jamais poser « œuf = 1 » — vu en test
/// manuel le 18/08/2026, un cycle œufs avec seulement plateau et carton,
/// impossible à vendre au détail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});

  late AppDatabase db;
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('impossible de créer un plateau avant la base', () async {
    await expectLater(
      container.read(productUnitActionsProvider).addUnit(
        productId: 'product-1',
        unitName: 'plateau',
        ratioToBase: 30,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('unité de base'),
        ),
      ),
    );

    expect(
      await db.select(db.localProductUnits).get(),
      isEmpty,
      reason: 'le refus doit être total, rien créé à moitié',
    );
  });

  test('la base elle-même passe toujours, même en premier', () async {
    await container.read(productUnitActionsProvider).addUnit(
      productId: 'product-1',
      unitName: 'œuf',
      ratioToBase: 1,
    );

    final unites = await db.select(db.localProductUnits).get();
    expect(unites, hasLength(1));
    expect(unites.single.ratioToBase, 1);
  });

  test('une fois la base posée, les unités dérivées passent', () async {
    await container.read(productUnitActionsProvider).addUnit(
      productId: 'product-1',
      unitName: 'œuf',
      ratioToBase: 1,
    );

    await container.read(productUnitActionsProvider).addUnit(
      productId: 'product-1',
      unitName: 'plateau',
      ratioToBase: 30,
    );

    final unites = await db.select(db.localProductUnits).get();
    expect(unites.map((u) => u.unitName), containsAll(['œuf', 'plateau']));
  });

  test('la base d’un autre produit ne compte pas pour celui-ci', () async {
    await container.read(productUnitActionsProvider).addUnit(
      productId: 'product-2',
      unitName: 'bouteille',
      ratioToBase: 1,
    );

    await expectLater(
      container.read(productUnitActionsProvider).addUnit(
        productId: 'product-1',
        unitName: 'plateau',
        ratioToBase: 30,
      ),
      throwsA(isA<Exception>()),
      reason: 'chaque produit a sa propre base — celle du voisin ne compte pas',
    );
  });
}

class _SyncServiceSansReseau extends SyncService {
  _SyncServiceSansReseau(super.db, super.ref);

  @override
  Future<void> processQueue() async {}
}
