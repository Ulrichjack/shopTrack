import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/inventory/presentation/providers/stock_transfer_provider.dart';

/// Recevoir deux fois le même transfert créditait le stock deux fois.
///
/// La ligne de transfert restait juste — `received_quantity` était simplement
/// réécrite — mais le produit gagnait la quantité à chaque appel. Vu en vrai le
/// 20/08/2026 : 6 bidons envoyés, 6 confirmés, 12 sur l'étagère. Rien dans la
/// table des transferts ne trahissait l'erreur.
void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'cached_shop_id': 'boutique-b'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.batch((batch) {
      batch.insert(
        db.localProducts,
        LocalProduct(
          id: 'produit-b',
          shopId: 'boutique-b',
          name: 'Huile 1L',
          buyPrice: 1100,
          sellPrice: 1400,
          quantity: 0,
          minQuantity: 0,
        ),
      );
      batch.insert(
        db.localStockTransfers,
        LocalStockTransfer(
          id: 'transfert-1',
          fromShopId: 'boutique-a',
          toShopId: 'boutique-b',
          productId: 'produit-a',
          productName: 'Huile 1L',
          quantity: 6,
          transferredAt: DateTime(2026, 8, 20, 16, 49),
        ),
      );
    });
  });

  tearDown(() async => db.close());

  test('confirmer deux fois n\'ajoute pas la marchandise deux fois', () async {
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final actions = container.read(stockTransferActionsProvider);

    await actions.confirmerReception(
      transferId: 'transfert-1',
      receivedQuantity: 6,
    );

    Future<int> stock() async {
      final produit = await (db.select(
        db.localProducts,
      )..where((row) => row.id.equals('produit-b'))).getSingle();
      return produit.quantity;
    }

    expect(await stock(), 6, reason: 'la première réception crédite');

    await expectLater(
      actions.confirmerReception(
        transferId: 'transfert-1',
        receivedQuantity: 6,
      ),
      throwsA(isA<Exception>()),
      reason: 'la seconde doit être refusée',
    );

    expect(await stock(), 6, reason: 'et surtout ne rien ajouter');
  });
}
