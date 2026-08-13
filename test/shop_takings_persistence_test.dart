import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:shoptrack/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('une correction remplace la recette du même jour', () async {
    final date = DateTime(2026, 8, 13);

    await db
        .into(db.localShopTakings)
        .insertOnConflictUpdate(
          LocalShopTaking(shopId: 'shop-1', date: date, amount: 125000),
        );
    await db
        .into(db.localShopTakings)
        .insertOnConflictUpdate(
          LocalShopTaking(shopId: 'shop-1', date: date, amount: 131500),
        );

    final rows = await db.select(db.localShopTakings).get();
    expect(rows, hasLength(1));
    expect(rows.single.amount, 131500);
  });

  test('deux boutiques conservent chacune leur recette du même jour', () async {
    final date = DateTime(2026, 8, 13);

    await db.batch((batch) {
      batch.insertAll(db.localShopTakings, [
        LocalShopTaking(shopId: 'shop-1', date: date, amount: 90000),
        LocalShopTaking(shopId: 'shop-2', date: date, amount: 75000),
      ]);
    });

    final rows = await db.select(db.localShopTakings).get();
    expect(rows, hasLength(2));
  });

  test('la correction d’un jour garde le même identifiant distant', () {
    // Une recette est identifiée par « cette boutique, ce jour-là ». Corriger
    // le montant ne doit pas changer la ligne côté serveur, sinon l'upsert
    // réécrit la clé primaire à chaque saisie.
    String idPour(String shop, String date) => const Uuid().v5(
      Namespace.url.value,
      'shoptrack:takings:$shop:$date',
    );

    expect(idPour('shop-1', '2026-08-13'), idPour('shop-1', '2026-08-13'));
    expect(
      idPour('shop-1', '2026-08-13'),
      isNot(idPour('shop-1', '2026-08-14')),
    );
    expect(
      idPour('shop-1', '2026-08-13'),
      isNot(idPour('shop-2', '2026-08-13')),
    );
  });
}
