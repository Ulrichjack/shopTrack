// Le bilan ne montre un bénéfice que s'il est comparable à la caisse.
//
// La recette d'une boutique est un montant unique : impossible d'en extraire
// la part des seuls produits comptés. Comparer les sorties de la moitié du
// catalogue à la totalité de l'argent encaissé affichait un excédent qui
// n'existe pas — en gros, en vert, avec la réserve en petit dessous.
//
// Ces tests déroulent le scénario réel : un premier tour complet, puis des
// recomptages par vagues.

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
  });

  tearDown(() async => db.close());

  Future<InventoryPeriodReport> rapport([int? indice]) async {
    final container = ProviderContainer(
      overrides: [localDbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container.read(inventoryReportProvider(indice).future);
  }

  test(
    'la moitié du catalogue recomptée ne produit aucun bénéfice global',
    () async {
      // Quatre produits comptés le 1er janvier, deux seulement recomptés le
      // 1er février. Les recettes de la période couvrent les QUATRE produits :
      // les comparer aux sorties de deux donnait un excédent fantôme.
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _produit('p1', 'Riz'),
          _produit('p2', 'Jus'),
          _produit('p3', 'Sucre'),
          _produit('p4', 'Lait'),
        ]);
        batch.insertAll(db.localInventoryCounts, [
          _comptage('c1', 'p1', DateTime(2026, 1, 1), 100),
          _comptage('c2', 'p2', DateTime(2026, 1, 1), 100),
          _comptage('c3', 'p3', DateTime(2026, 1, 1), 100),
          _comptage('c4', 'p4', DateTime(2026, 1, 1), 100),
          _comptage(
            'c5',
            'p1',
            DateTime(2026, 2, 1),
            70,
            precedent: DateTime(2026, 1, 1),
            quantitePrecedente: 100,
          ),
          _comptage(
            'c6',
            'p2',
            DateTime(2026, 2, 1),
            70,
            precedent: DateTime(2026, 1, 1),
            quantitePrecedente: 100,
          ),
        ]);
      });

      final r = await rapport();

      expect(
        r.verdictFinancierFiable,
        isFalse,
        reason: 'deux produits sur quatre : la caisse n\'est pas comparable',
      );
      expect(
        r.result.products.length,
        2,
        reason: 'les sorties des produits comptés restent un fait',
      );
      // Le trou que le commerçant vivait : l'app disait « 2 en attente » sans
      // jamais dire lesquels, et il repartait chercher dans sa boutique.
      expect(
        r.produitsAFinirDeCompter,
        ['Lait', 'Sucre'],
        reason:
            'les produits manquants sont nommés, et dans l\'ordre du '
            'comptage',
      );
    },
  );

  test(
    'tout recompté et toutes les recettes notées : le bénéfice sort',
    () async {
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _produit('p1', 'Riz'),
          _produit('p2', 'Jus'),
        ]);
        batch.insertAll(db.localInventoryCounts, [
          _comptage('c1', 'p1', DateTime(2026, 2, 1), 100),
          _comptage('c2', 'p2', DateTime(2026, 2, 1), 100),
          _comptage(
            'c3',
            'p1',
            DateTime(2026, 2, 3),
            80,
            precedent: DateTime(2026, 2, 1),
            quantitePrecedente: 100,
          ),
          _comptage(
            'c4',
            'p2',
            DateTime(2026, 2, 3),
            80,
            precedent: DateTime(2026, 2, 1),
            quantitePrecedente: 100,
          ),
        ]);
        batch.insertAll(db.localShopTakings, [
          _recette(DateTime(2026, 2, 1), 10000),
          _recette(DateTime(2026, 2, 2), 10000),
          _recette(DateTime(2026, 2, 3), 10000),
        ]);
      });

      final r = await rapport();

      expect(r.verdictFinancierFiable, isTrue);
      expect(r.produitsAFinirDeCompter, isEmpty);
      expect(r.result.actualTakings, 30000);
    },
  );

  test('une seule recette oubliée suffit à retenir le verdict', () async {
    // Un jour non noté produit exactement le même chiffre qu'un vol du même
    // montant. Afficher « il manque 10 000 F » sur un oubli de saisie est le
    // pire résultat que cette app puisse produire : quelqu'un est accusé.
    await db.batch((batch) {
      batch.insertAll(db.localProducts, [
        _produit('p1', 'Riz'),
        _produit('p2', 'Jus'),
      ]);
      batch.insertAll(db.localInventoryCounts, [
        _comptage('c1', 'p1', DateTime(2026, 2, 1), 100),
        _comptage('c2', 'p2', DateTime(2026, 2, 1), 100),
        _comptage(
          'c3',
          'p1',
          DateTime(2026, 2, 3),
          80,
          precedent: DateTime(2026, 2, 1),
          quantitePrecedente: 100,
        ),
        _comptage(
          'c4',
          'p2',
          DateTime(2026, 2, 3),
          80,
          precedent: DateTime(2026, 2, 1),
          quantitePrecedente: 100,
        ),
      ]);
      batch.insertAll(db.localShopTakings, [
        _recette(DateTime(2026, 2, 1), 10000),
        // Le 2 février manque.
        _recette(DateTime(2026, 2, 3), 10000),
      ]);
    });

    final r = await rapport();

    expect(
      r.isComplete,
      isTrue,
      reason: 'les produits, eux, sont tous comptés',
    );
    expect(
      r.verdictFinancierFiable,
      isFalse,
      reason: 'mais il manque un jour de caisse',
    );
    expect(r.daysWithoutTakings, [DateTime(2026, 2, 2)]);
  });

  test(
    'un produit archivé ne retient plus le bilan, mais reste dans le sien',
    () async {
      // Sept articles rangés suffisaient à geler une boutique entière : ils
      // sont cachés de l'écran de comptage, donc jamais recomptés, donc
      // éternellement « en attente ». Le bandeau ne partait plus et aucune
      // nouvelle période ne s'ouvrait, quoi que le commerçant compte.
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _produit('p1', 'Riz'),
          _produit('p2', 'Jus'),
          _produit('p3', 'Savon', archiveLe: DateTime(2026, 2, 5)),
        ]);
        batch.insertAll(db.localInventoryCounts, [
          for (final id in ['p1', 'p2', 'p3'])
            _comptage('$id-1', id, DateTime(2026, 2, 1), 100),
          for (final id in ['p1', 'p2', 'p3'])
            _comptage(
              '$id-2',
              id,
              DateTime(2026, 2, 3),
              80,
              precedent: DateTime(2026, 2, 1),
              quantitePrecedente: 100,
            ),
          // Le savon est archivé le 5 : il ne participe plus au tour suivant.
          for (final id in ['p1', 'p2'])
            _comptage(
              '$id-3',
              id,
              DateTime(2026, 2, 10),
              60,
              precedent: DateTime(2026, 2, 3),
              quantitePrecedente: 80,
            ),
        ]);
      });

      final recent = await rapport();

      expect(
        recent.periodesDisponibles.map((p) => p.indiceComptage),
        [2, 1],
        reason:
            'la deuxième période s\'ouvre malgré l\'archivé resté à deux '
            'comptages',
      );
      expect(
        recent.isComplete,
        isTrue,
        reason: 'un article rangé n\'est ni un oubli ni une attente',
      );
      expect(
        recent.produitsAFinirDeCompter,
        isEmpty,
        reason: 'on n\'envoie pas le commerçant compter un produit rangé',
      );

      // Et le bilan où il a réellement servi le contient toujours : ses
      // sorties ont eu lieu, un rapport déjà consulté ne se réécrit pas.
      final ancien = await rapport(1);
      expect(
        ancien.result.products.map((p) => p.productName),
        contains('Savon'),
      );
    },
  );

  test(
    'un produit compté plus que possible retient aussi le verdict',
    () async {
      // Cent au départ, cent vingt comptés : un arrivage de cinquante n'a pas
      // été saisi, et trente ventes réelles sont effacées. Leur argent reste
      // dans la caisse — l'écart repart donc en excédent fantôme, exactement le
      // défaut corrigé pour les comptages partiels, par une autre porte.
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _produit('p1', 'Riz'),
          _produit('p2', 'Jus'),
        ]);
        batch.insertAll(db.localInventoryCounts, [
          _comptage('c1', 'p1', DateTime(2026, 2, 1), 100),
          _comptage('c2', 'p2', DateTime(2026, 2, 1), 100),
          _comptage(
            'c3',
            'p1',
            DateTime(2026, 2, 3),
            120, // plus qu'au départ, sans arrivage enregistré
            precedent: DateTime(2026, 2, 1),
            quantitePrecedente: 100,
          ),
          _comptage(
            'c4',
            'p2',
            DateTime(2026, 2, 3),
            80,
            precedent: DateTime(2026, 2, 1),
            quantitePrecedente: 100,
          ),
        ]);
        batch.insertAll(db.localShopTakings, [
          _recette(DateTime(2026, 2, 1), 10000),
          _recette(DateTime(2026, 2, 2), 10000),
          _recette(DateTime(2026, 2, 3), 10000),
        ]);
      });

      final r = await rapport();

      expect(r.isComplete, isTrue, reason: 'tout est bien compté');
      expect(r.daysWithoutTakings, isEmpty, reason: 'aucune recette ne manque');
      expect(
        r.result.inconsistentProducts.map((p) => p.productName),
        ['Riz'],
        reason: 'le produit fautif est identifié pour être vérifié',
      );
      expect(
        r.verdictFinancierFiable,
        isFalse,
        reason: 'mais le bénéfice serait faux : on ne l\'affiche pas',
      );
    },
  );

  test(
    'la deuxième période ne réclame pas la recette de son jour d\'ouverture',
    () async {
      // Le jour du comptage qui FERME une période appartient à celle-ci : sa
      // recette y est encaissée, et la période suivante l'exclut de son total.
      // Mais elle continuait à la réclamer comme manquante — et la noter n'y
      // changeait rien, puisqu'elle est filtrée avant d'entrer dans les jours
      // notés. Toutes les périodes à partir de la deuxième restaient donc
      // bloquées pour toujours.
      await db.batch((batch) {
        batch.insertAll(db.localProducts, [
          _produit('p1', 'Riz'),
          _produit('p2', 'Jus'),
        ]);
        batch.insertAll(db.localInventoryCounts, [
          for (final id in ['p1', 'p2'])
            _comptage('$id-1', id, DateTime(2026, 2, 1), 100),
          for (final id in ['p1', 'p2'])
            _comptage(
              '$id-2',
              id,
              DateTime(2026, 2, 3),
              80,
              precedent: DateTime(2026, 2, 1),
              quantitePrecedente: 100,
            ),
          for (final id in ['p1', 'p2'])
            _comptage(
              '$id-3',
              id,
              DateTime(2026, 2, 5),
              60,
              precedent: DateTime(2026, 2, 3),
              quantitePrecedente: 80,
            ),
        ]);
        batch.insertAll(db.localShopTakings, [
          for (var jour = 1; jour <= 5; jour++)
            _recette(DateTime(2026, 2, jour), 10000),
        ]);
      });

      final deuxieme = await rapport(2);

      expect(
        deuxieme.daysWithoutTakings,
        isEmpty,
        reason: 'le 3 février appartient à la période qui se ferme',
      );
      expect(
        deuxieme.result.actualTakings,
        20000,
        reason: 'seuls le 4 et le 5 : le 3 est déjà encaissé ailleurs',
      );
      expect(deuxieme.verdictFinancierFiable, isTrue);

      // Et la première, elle, réclame bien son jour d'ouverture : rien ne
      // l'encaisse avant elle.
      final premiere = await rapport(1);
      expect(premiere.daysWithoutTakings, isEmpty);
      expect(
        premiere.result.actualTakings,
        30000,
        reason: 'du 1er au 3 inclus',
      );
    },
  );
}

LocalProduct _produit(String id, String nom, {DateTime? archiveLe}) =>
    LocalProduct(
      id: id,
      shopId: 'shop-1',
      name: nom,
      buyPrice: 10,
      sellPrice: 20,
      quantity: 0,
      minQuantity: 0,
      archivedAt: archiveLe,
    );

LocalShopTaking _recette(DateTime jour, double montant) =>
    LocalShopTaking(shopId: 'shop-1', date: jour, amount: montant);

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
