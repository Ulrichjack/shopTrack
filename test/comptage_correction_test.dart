import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/inventory/presentation/providers/inventory_count_provider.dart';

/// Se tromper de chiffre était définitif : l'app insérait un troisième
/// comptage, le rapport continuait d'utiliser le deuxième, et la correction
/// restait invisible. Sur les 235 articles d'un vrai catalogue, une faute de
/// frappe est certaine.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.localProducts)
        .insert(
          LocalProduct(
            id: 'riz',
            shopId: 'shop-1',
            name: 'Riz 5kg',
            buyPrice: 3200,
            sellPrice: 4000,
            quantity: 0,
            minQuantity: 0,
          ),
        );
    container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<LocalInventoryCount>> comptages() => (db.select(
    db.localInventoryCounts,
  )..where((row) => row.productId.equals('riz'))).get();

  test('recompter le même jour corrige au lieu d\'ajouter un repère', () async {
    final actions = container.read(inventoryCountActionsProvider);

    await actions.saveCount(productId: 'riz', countedQuantity: 40);
    await actions.saveCount(productId: 'riz', countedQuantity: 50);

    final lignes = await comptages();
    expect(lignes, hasLength(1), reason: 'un seul repère pour aujourd\'hui');
    expect(lignes.single.countedQuantity, 50, reason: 'le chiffre corrigé');

    final produit = await (db.select(
      db.localProducts,
    )..where((row) => row.id.equals('riz'))).getSingle();
    expect(produit.quantity, 50, reason: 'le stock suit la correction');
  });

  test('un comptage d\'un AUTRE jour reste un nouveau repère', () async {
    final actions = container.read(inventoryCountActionsProvider);
    final hier = DateTime.now().subtract(const Duration(days: 1));

    await actions.saveCount(
      productId: 'riz',
      countedQuantity: 40,
      dateDuComptage: hier,
    );
    await actions.saveCount(productId: 'riz', countedQuantity: 30);

    final lignes = await comptages()
      ..sort((a, b) => a.countedAt.compareTo(b.countedAt));
    expect(lignes, hasLength(2), reason: 'deux jours, deux repères');
    expect(lignes.last.previousQuantity, 40, reason: 'la période est bornée');
  });
}
