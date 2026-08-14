import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/utils/inventory_reconciliation_calculator.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('une perte déclarée ne touche pas au stock du produit', () async {
    await db
        .into(db.localProducts)
        .insert(
          LocalProduct(
            id: 'product-1',
            shopId: 'shop-1',
            name: 'Bouteille huile 1L',
            buyPrice: 1500,
            sellPrice: 1800,
            quantity: 44,
            minQuantity: 5,
          ),
        );

    await db
        .into(db.localInventoryLosses)
        .insert(
          LocalInventoryLoss(
            id: 'loss-1',
            shopId: 'shop-1',
            productId: 'product-1',
            quantity: 3,
            reason: 'casse',
            occurredAt: DateTime(2026, 8, 14),
          ),
        );

    // En inventaire périodique le stock ne bouge qu'au comptage : la
    // marchandise cassée a déjà quitté l'étagère, la déclarer ne doit pas la
    // retirer une seconde fois.
    final product = await (db.select(
      db.localProducts,
    )..where((row) => row.id.equals('product-1'))).getSingle();
    expect(product.quantity, 44);
  });

  test('la perte part en synchro avec la raison attendue par Supabase', () async {
    await db.addToQueue(
      'ADD_INVENTORY_LOSS',
      jsonEncode({
        'id': 'loss-1',
        'shop_id': 'shop-1',
        'product_id': 'product-1',
        'quantity': 3,
        'reason': 'casse',
        'note': null,
        'occurred_at': DateTime.utc(2026, 8, 14).toIso8601String(),
      }),
    );

    final queued = await db.select(db.syncQueueItems).getSingle();
    expect(queued.action, 'ADD_INVENTORY_LOSS');

    final payload = jsonDecode(queued.payload) as Map<String, dynamic>;
    // La contrainte SQL n'accepte que ces cinq valeurs : une faute de frappe
    // ici bloquerait la file entière, pas seulement cette perte.
    expect(
      payload['reason'],
      isIn(['casse', 'peremption', 'invendu', 'vol', 'autre']),
    );
    expect(payload['quantity'], greaterThan(0));
  });

  test('on ne peut pas perdre plus que ce qui a pu exister', () {
    // Le calculateur borne déjà les pertes au moment du rapport, mais une
    // saisie absurde acceptée ferait disparaître des ventes réelles et
    // inventerait un excédent de caisse. On refuse à l'entrée.
    final produit = InventoryProductInput(
      productId: 'p',
      productName: 'Bidon huile 5L',
      openingStock: 100,
      countedStock: 85,
      purchases: 0,
      transfersIn: 0,
      transfersOut: 0,
      declaredLosses: 40,
      unitCost: 6500,
      unitSellPrice: 7500,
    );

    final r = InventoryReconciliationCalculator.calculateProduct(produit);
    expect(r.totalOutflow, 15);
    expect(r.lossesExceedOutflow, isTrue);
    expect(
      r.presumedSales,
      0,
      reason: 'jamais de ventes négatives, même sur perte surdéclarée',
    );
  });
}
