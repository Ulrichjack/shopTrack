import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/inventory_reconciliation_calculator.dart';

InventoryProductInput _produit({
  String nom = 'produit',
  int debut = 0,
  int compte = 0,
  int achats = 0,
  int entrees = 0,
  int sorties = 0,
  int pertes = 0,
  double cout = 0,
  double vente = 0,
}) {
  return InventoryProductInput(
    productId: nom,
    productName: nom,
    openingStock: debut,
    countedStock: compte,
    purchases: achats,
    transfersIn: entrees,
    transfersOut: sorties,
    declaredLosses: pertes,
    unitCost: cout,
    unitSellPrice: vente,
  );
}

void main() {
  group('Un produit', () {
    test('déduit les sorties de deux comptages', () {
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 5, achats: 10, sorties: 4, compte: 3, cout: 20000,
            vente: 22000),
      );

      // 5 + 10 − 4 transférés − 3 restants
      expect(r.totalOutflow, 8);
      expect(r.presumedSales, 8);
      expect(r.expectedRevenue, 176000);
      expect(r.costOfGoodsSold, 160000);
    });

    test('retire les pertes déclarées des ventes présumées', () {
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(achats: 600, compte: 0, pertes: 30, cout: 100, vente: 150),
      );

      expect(r.totalOutflow, 600);
      expect(r.presumedSales, 570, reason: 'le pain jeté n\'est pas vendu');
      expect(r.expectedRevenue, 85500);
      expect(r.lossValue, 3000);
    });

    test('un transfert sortant n’est pas une vente', () {
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 10, sorties: 10, compte: 0, cout: 20000, vente: 22000),
      );

      expect(r.totalOutflow, 0);
      expect(r.presumedSales, 0);
      expect(
        r.expectedRevenue,
        0,
        reason: 'déplacer la marchandise ne rapporte rien',
      );
    });

    test('signale un comptage impossible sans planter', () {
      // On compte 20 alors qu'au mieux il pouvait en rester 10 : achat non
      // enregistré ou erreur de comptage.
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 10, compte: 20, cout: 100, vente: 150),
      );

      expect(r.hasNegativeOutflow, isTrue);
      expect(
        r.presumedSales,
        0,
        reason: 'jamais de vente négative : un seul produit mal saisi '
            'fausserait sinon tout le total de la boutique',
      );
      expect(r.expectedRevenue, 0);
      expect(r.costOfGoodsSold, 0);
    });

    test('signale des pertes supérieures aux sorties', () {
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 10, compte: 8, pertes: 5, cout: 100, vente: 150),
      );

      expect(r.totalOutflow, 2);
      expect(r.lossesExceedOutflow, isTrue);
      expect(
        r.presumedSales,
        0,
        reason: 'jamais de ventes négatives, même sur saisie incohérente',
      );
    });
  });

  group('Une période complète — l’épicerie du client', () {
    // Mayonnaise, riz et pain sur un mois, avec un transfert et du pain jeté.
    final produits = [
      _produit(
        nom: 'Mayonnaise',
        debut: 5,
        achats: 10,
        sorties: 4,
        compte: 3,
        cout: 20000,
        vente: 22000,
      ),
      _produit(
        nom: 'Riz',
        debut: 8,
        achats: 12,
        compte: 5,
        cout: 25000,
        vente: 28000,
      ),
      _produit(
        nom: 'Pain',
        achats: 600,
        compte: 0,
        pertes: 30,
        cout: 100,
        vente: 150,
      ),
    ];

    test('croise la marchandise sortie avec l’argent encaissé', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: produits,
        actualTakings: 675000,
      );

      // 176 000 + 420 000 + 85 500
      expect(r.expectedRevenue, 681500);
      expect(r.actualTakings, 675000);
      expect(
        r.unexplainedGap,
        -6500,
        reason: 'ce que le commerçant ne peut pas voir aujourd’hui',
      );
      expect(r.hasUnexplainedGap, isTrue);

      // 160 000 + 375 000 + 57 000
      expect(r.costOfGoodsSold, 592000);
      expect(r.lossValue, 3000);
      // On part de l'argent réellement encaissé, pas de l'attendu.
      expect(r.profit, 80000);
    });

    test('aucun écart quand tout concorde', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: produits,
        actualTakings: 681500,
      );

      expect(r.unexplainedGap, 0);
      expect(r.hasUnexplainedGap, isFalse);
    });

    test('les produits sortent triés du plus gros au plus petit', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: produits,
        actualTakings: 681500,
      );

      final valeurs = r.products.map((p) => p.expectedRevenue).toList();
      expect(
        valeurs,
        orderedEquals(List.of(valeurs)..sort((a, b) => b.compareTo(a))),
        reason: 'le commerçant ne lit que le haut de la liste',
      );
    });

    test('un produit incohérent ne fausse pas le total de la boutique', () {
      // Cas réel du 13/08 : comptage 5 puis 10 sans approvisionnement
      // enregistré entre les deux. Sans borne, ce produit retirait
      // 140 000 F du chiffre d'affaires attendu de toute la boutique.
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: [
          _produit(nom: 'Riz', debut: 5, compte: 10, cout: 25000, vente: 28000),
          _produit(
            nom: 'Mayonnaise',
            debut: 8,
            compte: 5,
            cout: 20000,
            vente: 22000,
          ),
        ],
        actualTakings: 66000,
      );

      expect(r.expectedRevenue, 66000, reason: 'seule la mayonnaise compte');
      expect(r.unexplainedGap, 0);
      expect(r.inconsistentProducts.map((p) => p.productName), ['Riz']);
    });

    test('remonte les produits dont la saisie est incohérente', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: [
          ...produits,
          _produit(nom: 'Sucre', debut: 2, compte: 9, cout: 500, vente: 700),
        ],
        actualTakings: 675000,
      );

      expect(r.inconsistentProducts.map((p) => p.productName), ['Sucre']);
    });

    test('compte les jours sans recette notée', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: produits,
        actualTakings: 600000,
        daysWithoutTakings: 3,
      );

      expect(r.daysWithoutTakings, 3);
      expect(
        r.unexplainedGap,
        lessThan(0),
        reason: 'un oubli de saisie ressemble à un manquant — à signaler',
      );
    });

    test('une période sans aucun mouvement ne casse rien', () {
      final r = InventoryReconciliationCalculator.calculatePeriod(
        products: const [],
        actualTakings: 0,
      );

      expect(r.expectedRevenue, 0);
      expect(r.profit, 0);
      expect(r.hasUnexplainedGap, isFalse);
    });
  });


  group('coût unitaire figé sur la ligne d\'achat', () {
    test('sans ligne d\'achat, on garde le prix du produit', () {
      // L'historique déjà saisi ne doit pas changer de valorisation le jour où
      // la table stock_purchases apparaît.
      expect(
        weightedUnitCost(
          openingStock: 10,
          purchasesInPeriod: const [],
          purchasesBefore: const [],
          openingCost: 22000,
        ),
        22000,
      );
    });

    test('moyenne pondérée entre le stock d\'ouverture et les achats', () {
      // 10 sacs déjà là à 22 000 + 5 achetés à 24 000 → 22 666,67.
      final cost = weightedUnitCost(
        openingStock: 10,
        purchasesInPeriod: const [PurchaseLine(quantity: 5, unitCost: 24000)],
        purchasesBefore: const [],
        openingCost: 22000,
      );
      expect(cost, closeTo(22666.67, 0.01));
    });

    test('un changement de prix ne réécrit pas la période close', () {
      // 10 sacs achetés 22 000 avant la période, 5 achetés 24 000 pendant.
      // Le produit est ensuite revalorisé à 30 000 : la période close garde le
      // coût réellement payé, elle ne bouge pas.
      final cost = weightedUnitCost(
        openingStock: 10,
        purchasesInPeriod: const [PurchaseLine(quantity: 5, unitCost: 24000)],
        purchasesBefore: const [PurchaseLine(quantity: 10, unitCost: 22000)],
        openingCost: 30000,
      );
      expect(cost, closeTo(22666.67, 0.01));
    });

    test('le stock d\'ouverture est valorisé aux achats antérieurs', () {
      expect(
        weightedUnitCost(
          openingStock: 4,
          purchasesInPeriod: const [],
          purchasesBefore: const [PurchaseLine(quantity: 10, unitCost: 21000)],
          openingCost: 30000,
        ),
        21000,
      );
    });
  });

  group('prix de vente figé sur la période', () {
    test('sans historique, on garde le prix du produit', () {
      expect(
        weightedSellPrice(
          periodStart: DateTime(2026, 8, 1),
          periodEnd: DateTime(2026, 8, 31),
          priceHistory: const [],
          productSellPrice: 350,
        ),
        350,
      );
    });

    test('un tarif changé en cours de période est pondéré par les jours', () {
      // 350 F du 1er au 10 (10 jours), 400 F du 11 au 20 (10 jours) → 375.
      final prix = weightedSellPrice(
        periodStart: DateTime(2026, 8, 1),
        periodEnd: DateTime(2026, 8, 20),
        priceHistory: [
          PricePoint(effectiveAt: DateTime(2026, 8, 1), sellPrice: 350),
          PricePoint(effectiveAt: DateTime(2026, 8, 11), sellPrice: 400),
        ],
        productSellPrice: 999,
      );
      expect(prix, closeTo(375, 0.01));
    });

    test('deux tarifs le même jour : le plus récent gagne', () {
      // Le prix de départ et celui saisi à l'arrivage tombent le même jour.
      // Sans l'heure pour départager, le tarif retenu dépendait de l'ordre
      // des lignes en base — donc du hasard.
      final prix = weightedSellPrice(
        periodStart: DateTime(2026, 8, 14),
        periodEnd: DateTime(2026, 8, 14),
        priceHistory: [
          PricePoint(
            effectiveAt: DateTime(2026, 8, 14, 16, 30),
            sellPrice: 27000,
          ),
          PricePoint(
            effectiveAt: DateTime(2026, 8, 14, 9, 0),
            sellPrice: 25000,
          ),
        ],
        productSellPrice: 999,
      );
      expect(prix, 27000);
    });

    test('une hausse postérieure ne réévalue pas la période close', () {
      // Le savon passe à 400 F le 5 septembre : août reste valorisé à 350.
      final prix = weightedSellPrice(
        periodStart: DateTime(2026, 8, 1),
        periodEnd: DateTime(2026, 8, 31),
        priceHistory: [
          PricePoint(effectiveAt: DateTime(2026, 8, 1), sellPrice: 350),
          PricePoint(effectiveAt: DateTime(2026, 9, 5), sellPrice: 400),
        ],
        productSellPrice: 400,
      );
      expect(prix, 350);
    });
  });

  group('coût du stock d\'ouverture', () {
    test('le stock en rayon garde le prix auquel il a été acheté', () {
      // 12 sacs achetés 22 000, 8 rachetés 24 000 pendant la période.
      // Sans historique des tarifs, les 12 se réévaluaient à 24 000 et toute
      // la période close bougeait avec le dernier arrivage.
      final ouverture = buyPriceAt(
        DateTime(2026, 8, 1),
        [
          PricePoint(
            effectiveAt: DateTime(2026, 7, 1),
            buyPrice: 22000,
            sellPrice: 25000,
          ),
          PricePoint(
            effectiveAt: DateTime(2026, 8, 15),
            buyPrice: 24000,
            sellPrice: 27000,
          ),
        ],
        99999,
      );
      expect(ouverture, 22000);

      final cout = weightedUnitCost(
        openingStock: 12,
        purchasesInPeriod: const [PurchaseLine(quantity: 8, unitCost: 24000)],
        purchasesBefore: const [],
        openingCost: ouverture,
      );
      expect(cout, closeTo(22800, 0.01));
    });

    test('sans historique, on retombe sur le prix du produit', () {
      expect(buyPriceAt(DateTime(2026, 8, 1), const [], 22000), 22000);
    });

    test('une hausse du même jour ne revalorise pas le stock d\'ouverture', () {
      // Période ouverte à 15h35, hausse enregistrée à 15h41 avec l'arrivage.
      // Au jour près, les 12 sacs déjà en rayon passaient à 24 000.
      expect(
        buyPriceAt(
          DateTime(2026, 8, 14, 15, 35),
          [
            PricePoint(
              effectiveAt: DateTime(2026, 8, 14, 15, 35),
              buyPrice: 22000,
              sellPrice: 25000,
            ),
            PricePoint(
              effectiveAt: DateTime(2026, 8, 14, 15, 41),
              buyPrice: 24000,
              sellPrice: 27000,
            ),
          ],
          99999,
        ),
        22000,
      );
    });
  });

  group('transferts entre boutiques', () {
    test('la marchandise reçue augmente ce qui était disponible', () {
      // 10 au départ, 5 reçus d'une autre boutique, 3 restants → 12 sortis.
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 10, entrees: 5, compte: 3, cout: 275, vente: 350),
      );
      expect(r.totalOutflow, 12);
      expect(r.presumedSales, 12);
    });

    test('un envoi ne crée ni vente ni bénéfice', () {
      // Toute la marchandise part vers l'autre boutique : rien n'a été vendu,
      // et surtout rien ne doit être réclamé à la caisse.
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(debut: 10, sorties: 10, compte: 0, cout: 275, vente: 350),
      );
      expect(r.totalOutflow, 0);
      expect(r.expectedRevenue, 0);
      expect(r.costOfGoodsSold, 0);
    });

    test('ce qui se perd en route sort des ventes présumées', () {
      // 10 envoyés, 9 arrivés : le dixième est une perte de transport chez
      // l'expéditeur. Sans elle il deviendrait un écart inexpliqué — donc un
      // vol présumé alors que la marchandise s'est perdue sur la route.
      final r = InventoryReconciliationCalculator.calculateProduct(
        _produit(
          debut: 20,
          sorties: 10,
          compte: 8,
          pertes: 1,
          cout: 275,
          vente: 350,
        ),
      );
      expect(r.totalOutflow, 2, reason: '20 − 10 transférés − 8 comptés');
      expect(r.declaredLosses, 1);
      expect(r.presumedSales, 1);
      expect(r.lossValue, 275);
    });
  });
}
