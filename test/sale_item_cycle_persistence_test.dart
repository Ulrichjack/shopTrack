import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';

/// Vérifie que le rattachement d'une vente à son cycle est bien persisté :
/// sans `cycle_id`, le rapport de cycle affiche 0 F de chiffre d'affaires.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('une ligne de vente de cycle conserve cycle_id et quantity_in_base', () async {
    await db
        .into(db.localSaleItems)
        .insert(
          LocalSaleItem(
            id: 'item-1',
            saleId: 'sale-1',
            productId: 'prod-1',
            productName: 'oeuf (plateau)',
            quantity: 60,
            sellPrice: 66.67,
            buyPrice: 50,
            profit: 1000,
            cycleId: 'cycle-1',
            unitId: 'unit-1',
            quantityInBase: 60,
            unitSellPrice: 66.67,
          ),
        );

    final row = await (db.select(
      db.localSaleItems,
    )..where((t) => t.id.equals('item-1'))).getSingle();

    expect(row.cycleId, 'cycle-1');
    expect(row.unitId, 'unit-1');
    expect(row.quantityInBase, 60);
    expect(row.unitSellPrice, 66.67);
  });

  test('une vente simple laisse les colonnes Module A vides', () async {
    await db
        .into(db.localSaleItems)
        .insert(
          LocalSaleItem(
            id: 'item-2',
            saleId: 'sale-2',
            productId: 'prod-2',
            productName: 'savon',
            quantity: 3,
            sellPrice: 500,
            buyPrice: 300,
            profit: 600,
          ),
        );

    final row = await (db.select(
      db.localSaleItems,
    )..where((t) => t.id.equals('item-2'))).getSingle();

    expect(row.cycleId, isNull);
    expect(row.quantityInBase, isNull);
  });
}
