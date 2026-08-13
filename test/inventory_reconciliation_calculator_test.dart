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
      expect(r.presumedSales, lessThanOrEqualTo(0));
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
}
