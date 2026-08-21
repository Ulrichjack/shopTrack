import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';

/// Changer de compte doit tout effacer, sans exception.
///
/// La liste des tables à vider était écrite à la main et avait quatre tables
/// de retard : pertes, arrivages, tarifs et transferts survivaient au
/// changement de compte. Le téléphone d'un vendeur gardait donc les prix
/// d'achat de son patron — exactement ce que ce ménage existe pour empêcher.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('clearAllData ne laisse aucune table derrière elle', () async {
    await db.into(db.localProducts).insert(
      const LocalProduct(
        id: 'p1',
        shopId: 'shop-1',
        name: 'Riz',
        buyPrice: 100,
        sellPrice: 150,
        quantity: 10,
        minQuantity: 2,
      ),
    );
    // Les quatre oubliées de l'ancienne liste, nommément.
    await db.into(db.localProductPrices).insert(
      LocalProductPrice(
        id: 'tarif-1',
        shopId: 'shop-1',
        productId: 'p1',
        buyPrice: 100,
        sellPrice: 150,
        effectiveAt: DateTime(2026, 8, 1),
      ),
    );
    await db.into(db.localStockPurchases).insert(
      LocalStockPurchase(
        id: 'achat-1',
        shopId: 'shop-1',
        productId: 'p1',
        quantity: 5,
        unitCost: 100,
        purchasedAt: DateTime(2026, 8, 2),
      ),
    );
    await db.into(db.localInventoryLosses).insert(
      LocalInventoryLoss(
        id: 'perte-1',
        shopId: 'shop-1',
        productId: 'p1',
        quantity: 1,
        reason: 'casse',
        occurredAt: DateTime(2026, 8, 3),
      ),
    );
    await db.into(db.localStockTransfers).insert(
      LocalStockTransfer(
        id: 'transfert-1',
        fromShopId: 'shop-1',
        toShopId: 'shop-2',
        productId: 'p1',
        quantity: 3,
        transferredAt: DateTime(2026, 8, 4),
      ),
    );
    await db.addToQueue('ADD_PRODUCT', '{}');

    await db.clearAllData();

    // Parcouru depuis `allTables` : une table ajoutée demain est couverte
    // sans que personne ait à revenir ici.
    for (final table in db.allTables) {
      final lignes = await db
          .customSelect('select count(*) as n from ${table.actualTableName}')
          .getSingle();
      expect(
        lignes.read<int>('n'),
        0,
        reason:
            '${table.actualTableName} garde des lignes du compte précédent '
            'après un changement de compte.',
      );
    }
  });
}
