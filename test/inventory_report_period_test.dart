import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/database/app_database.dart';
import 'package:shoptrack/core/sync/sync_service.dart';
import 'package:shoptrack/features/inventory/presentation/providers/inventory_report_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'cached_shop_id': 'shop-1'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.batch((batch) {
      batch.insertAll(db.localProducts, [
        _produit('p1', 'Riz', 20),
        _produit('p2', 'Jus', 30),
      ]);
      batch.insertAll(db.localInventoryCounts, [
        _comptage('p1-1', 'p1', DateTime(2026, 1, 1), 100),
        _comptage(
          'p1-2',
          'p1',
          DateTime(2026, 1, 31),
          70,
          precedent: DateTime(2026, 1, 1),
          quantitePrecedente: 100,
        ),
        _comptage(
          'p1-3',
          'p1',
          DateTime(2026, 2, 28),
          40,
          precedent: DateTime(2026, 1, 31),
          quantitePrecedente: 70,
        ),
        _comptage('p2-1', 'p2', DateTime(2026, 1, 2), 50),
        _comptage(
          'p2-2',
          'p2',
          DateTime(2026, 2, 1),
          30,
          precedent: DateTime(2026, 1, 2),
          quantitePrecedente: 50,
        ),
        _comptage(
          'p2-3',
          'p2',
          DateTime(2026, 3, 1),
          20,
          precedent: DateTime(2026, 2, 1),
          quantitePrecedente: 30,
        ),
      ]);
    });
  });

  tearDown(() async => db.close());

  test(
    'les périodes closes sont proposées de la plus récente à l’ancienne',
    () async {
      final comptages = await db.select(db.localInventoryCounts).get();

      final periodes = construirePeriodesRapport(
        idsProduits: const ['p1', 'p2'],
        comptages: comptages,
      );

      // Les deux produits ne sont pas comptés à la même minute : les bornes
      // englobent toute la fenêtre réellement couverte, sans inventer un mois.
      expect(periodes.map((periode) => periode.indiceComptage), [2, 1]);
      expect(periodes.first.debut, DateTime(2026, 1, 31));
      expect(periodes.first.fin, DateTime(2026, 3, 1));
      expect(periodes.last.debut, DateTime(2026, 1, 1));
      expect(periodes.last.fin, DateTime(2026, 2, 1));
    },
  );

  test('une perte du jour de bascule n\'est comptée qu\'une fois', () async {
    // Le 31/01 ferme la période 1 et ouvre la période 2. Sans borne stricte
    // sur le jour d'ouverture, une casse notée ce jour-là était comptée dans
    // les DEUX périodes — les ventes présumées baissaient deux fois.
    await db
        .into(db.localInventoryLosses)
        .insert(
          LocalInventoryLoss(
            id: 'perte-bascule',
            shopId: 'shop-1',
            productId: 'p1',
            quantity: 4,
            reason: 'casse',
            occurredAt: DateTime(2026, 1, 31, 9),
          ),
        );

    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final ancienne = await container.read(inventoryReportProvider(1).future);
    final recente = await container.read(inventoryReportProvider(2).future);

    int pertesDe(InventoryPeriodReport rapport) => rapport.result.products
        .where((produit) => produit.productId == 'p1')
        .single
        .declaredLosses;

    expect(pertesDe(ancienne), 4, reason: 'la période qui se ferme la porte');
    expect(pertesDe(recente), 0, reason: 'celle qui s\'ouvre ne la reprend pas');
  });

  test('la recette du jour de bascule n\'est encaissée qu\'une fois', () async {
    // Le 31/01 ferme une période et en ouvre une autre. Comptée des deux
    // côtés, la recette gonflait l'écart d'un rapport et le creusait dans
    // l'autre — deux verdicts faux à partir d'une seule journée.
    await db
        .into(db.localShopTakings)
        .insert(
          LocalShopTaking(
            shopId: 'shop-1',
            date: DateTime(2026, 1, 31),
            amount: 50000,
          ),
        );

    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final ancienne = await container.read(inventoryReportProvider(1).future);
    final recente = await container.read(inventoryReportProvider(2).future);

    expect(ancienne.result.actualTakings, 50000);
    expect(recente.result.actualTakings, 0);
  });

  test('un produit récent n\'efface pas l\'historique des périodes', () async {
    // Un article ajouté hier — ou arrivé par transfert — n'a qu'un comptage,
    // voire aucun. En prenant le minimum sur TOUS les produits, il ramenait le
    // compte à zéro et le sélecteur de périodes disparaissait entièrement.
    await db
        .into(db.localProducts)
        .insert(_produit('p3', 'Savon arrivé hier', 350));

    final comptages = await db.select(db.localInventoryCounts).get();
    final periodes = construirePeriodesRapport(
      idsProduits: const ['p1', 'p2', 'p3'],
      comptages: comptages,
    );

    expect(
      periodes.map((periode) => periode.indiceComptage),
      [2, 1],
      reason: 'les périodes des produits établis restent consultables',
    );
  });

  test('le rapport choisi utilise les comptages de cette période', () async {
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final ancienne = await container.read(inventoryReportProvider(1).future);
    final recente = await container.read(inventoryReportProvider(2).future);

    expect(ancienne.periodStart, DateTime(2026, 1, 1));
    expect(ancienne.periodEnd, DateTime(2026, 2, 1));
    expect(
      ancienne.result.products
          .where((produit) => produit.productId == 'p2')
          .single
          .presumedSales,
      20,
    );
    expect(
      recente.result.products
          .where((produit) => produit.productId == 'p2')
          .single
          .presumedSales,
      10,
    );
  });
}

LocalProduct _produit(String id, String nom, double prixVente) => LocalProduct(
  id: id,
  shopId: 'shop-1',
  name: nom,
  buyPrice: 10,
  sellPrice: prixVente,
  quantity: 0,
  minQuantity: 0,
);

LocalInventoryCount _comptage(
  String id,
  String produitId,
  DateTime date,
  int quantite, {
  DateTime? precedent,
  int? quantitePrecedente,
}) => LocalInventoryCount(
  id: id,
  shopId: 'shop-1',
  productId: produitId,
  countedAt: date,
  countedQuantity: quantite,
  previousCountedAt: precedent,
  previousQuantity: quantitePrecedente,
);
