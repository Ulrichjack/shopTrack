import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/cycle_result_calculator.dart';

void main() {
  group('UnitSaleConversion', () {
    test('convertit une vente en plateaux vers l’unité de base', () {
      final conversion = UnitSaleConversion.convert(
        quantityInUnit: 2,
        pricePerUnit: 2000,
        ratioToBase: 30,
      );

      expect(conversion.quantityInBase, 60);
      // 2000 F le plateau de 30 œufs => 66,67 F l'œuf.
      expect(conversion.pricePerBaseUnit, closeTo(66.67, 0.01));
      expect(conversion.lineTotal, 4000);
    });

    test('quantité_base × prix_base redonne toujours le total encaissé', () {
      final conversion = UnitSaleConversion.convert(
        quantityInUnit: 3,
        pricePerUnit: 24000,
        ratioToBase: 360,
      );

      expect(
        conversion.quantityInBase * conversion.pricePerBaseUnit,
        closeTo(conversion.lineTotal, 0.001),
      );
    });

    test('vendre à l’unité de base ne change rien', () {
      final conversion = UnitSaleConversion.convert(
        quantityInUnit: 12,
        pricePerUnit: 75,
        ratioToBase: 1,
      );

      expect(conversion.quantityInBase, 12);
      expect(conversion.pricePerBaseUnit, 75);
      expect(conversion.lineTotal, 900);
    });

    test('refuse un ratio invalide plutôt que de diviser par zéro', () {
      expect(
        () => UnitSaleConversion.convert(
          quantityInUnit: 1,
          pricePerUnit: 100,
          ratioToBase: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Scénario complet client œufs', () {
    test('un carton acheté, vendu en plateaux, avec casse', () {
      // 1 carton = 360 œufs acheté 18 000 F (50 F l'œuf).
      const quantityReceived = 360;
      const purchaseCost = 18000.0;

      // Le vendeur écoule 10 plateaux à 2 000 F le plateau.
      final vente = UnitSaleConversion.convert(
        quantityInUnit: 10,
        pricePerUnit: 2000,
        ratioToBase: 30,
      );
      expect(vente.quantityInBase, 300);
      expect(vente.lineTotal, 20000);

      // 12 œufs cassés pendant le transport.
      final totals = CycleResultCalculator.calculate(
        quantityReceived: quantityReceived,
        purchaseCost: purchaseCost,
        sales: [
          CycleSaleValue(
            quantityInBase: vente.quantityInBase,
            unitSellPrice: vente.pricePerBaseUnit,
          ),
        ],
        losses: const [CycleLossValue(quantity: 12)],
      );

      expect(totals.unitCost, 50);
      // Le chiffre d'affaires du cycle correspond bien à l'argent encaissé.
      expect(totals.revenue, closeTo(vente.lineTotal, 0.001));
      expect(totals.soldStockCost, 15000);
      expect(totals.lossValue, 600);
      expect(totals.remainingStock, 48);
      // 20 000 encaissés − 15 000 de stock vendu − 600 de casse.
      expect(totals.netProfit, closeTo(4400, 0.001));
    });

    test('le gain de référence du client ne fausse jamais le bénéfice réel', () {
      // Le client annonce un "gain théorique" de 6 000 F par carton, mais il
      // a dû brader : le rapport doit montrer la réalité, pas la théorie.
      final vente = UnitSaleConversion.convert(
        quantityInUnit: 12,
        pricePerUnit: 1500,
        ratioToBase: 30,
      );

      final totals = CycleResultCalculator.calculate(
        quantityReceived: 360,
        purchaseCost: 18000,
        sales: [
          CycleSaleValue(
            quantityInBase: vente.quantityInBase,
            unitSellPrice: vente.pricePerBaseUnit,
          ),
        ],
        losses: const [],
      );

      // 360 œufs vendus 18 000 F au total, achetés 18 000 F : marge nulle,
      // très loin des 6 000 F "théoriques".
      expect(totals.revenue, closeTo(18000, 0.001));
      expect(totals.netProfit, closeTo(0, 0.001));
      expect(totals.remainingStock, 0);
    });

    test('une perte totale donne une perte sèche égale au coût d’achat', () {
      final totals = CycleResultCalculator.calculate(
        quantityReceived: 360,
        purchaseCost: 18000,
        sales: const [],
        losses: const [CycleLossValue(quantity: 360)],
      );

      expect(totals.lossValue, 18000);
      expect(totals.netProfit, -18000);
      expect(totals.remainingStock, 0);
    });
  });

  group('CycleResultCalculator', () {
    test('calcule le bénéfice net à partir du coût réel, pas du prix théorique', () {
      // Cycle de 360 œufs (1 carton) acheté 18000 FCFA, vendu au détail.
      final totals = CycleResultCalculator.calculate(
        quantityReceived: 360,
        purchaseCost: 18000,
        sales: const [
          CycleSaleValue(quantityInBase: 300, unitSellPrice: 75),
        ],
        losses: const [CycleLossValue(quantity: 10)],
      );

      expect(totals.unitCost, 50);
      expect(totals.revenue, 22500);
      expect(totals.soldStockCost, 15000);
      expect(totals.lossValue, 500);
      expect(totals.remainingStock, 50);
      expect(totals.netProfit, 7000);
    });

    test('ne divise jamais par zéro si rien n’a encore été reçu', () {
      final totals = CycleResultCalculator.calculate(
        quantityReceived: 0,
        purchaseCost: 0,
        sales: const [],
        losses: const [],
      );

      expect(totals.unitCost, 0);
      expect(totals.remainingStock, 0);
      expect(totals.netProfit, 0);
    });

    test('additionne plusieurs lignes de vente et de pertes', () {
      final totals = CycleResultCalculator.calculate(
        quantityReceived: 100,
        purchaseCost: 1000,
        sales: const [
          CycleSaleValue(quantityInBase: 20, unitSellPrice: 15),
          CycleSaleValue(quantityInBase: 30, unitSellPrice: 15),
        ],
        losses: const [
          CycleLossValue(quantity: 5),
          CycleLossValue(quantity: 5),
        ],
      );

      expect(totals.revenue, 750);
      expect(totals.soldStockCost, 500);
      expect(totals.lossValue, 100);
      expect(totals.remainingStock, 40);
      expect(totals.netProfit, 150);
    });

    test('rapporte les quantités vendues et perdues, pas seulement l’argent', () {
      // Ces deux nombres étaient calculés puis jetés : le rapport ne pouvait
      // afficher que des montants. Un vendeur d'œufs lit d'abord « 3 050
      // vendus, 50 cassés », et devait jusqu'ici le déduire lui-même du reçu
      // moins le restant moins les pertes.
      final totals = CycleResultCalculator.calculate(
        quantityReceived: 3600,
        purchaseCost: 288000,
        sales: const [
          CycleSaleValue(quantityInBase: 1800, unitSellPrice: 90),
          CycleSaleValue(quantityInBase: 600, unitSellPrice: 95),
          CycleSaleValue(quantityInBase: 450, unitSellPrice: 100),
          CycleSaleValue(quantityInBase: 200, unitSellPrice: 80),
        ],
        losses: const [CycleLossValue(quantity: 50)],
      );

      expect(totals.soldQuantity, 3050);
      expect(totals.lostQuantity, 50);

      // Les trois nombres doivent rester d'accord entre eux : ce qui reste,
      // c'est ce qu'on a reçu moins ce qu'on a vendu et perdu. Un écart ici
      // voudrait dire qu'une des trois lignes du rapport ment.
      expect(
        totals.remainingStock,
        3600 - totals.soldQuantity - totals.lostQuantity,
      );

      // Journée réellement jouée sur téléphone le 18/08/2026 : la dernière
      // ligne, vendue à 80 F soit le coût exact, dégage un profit nul — c'est
      // ce qui prouve que le coût vient de l'arrivage (288 000 / 3 600) et non
      // du prix d'achat inscrit sur le produit.
      expect(totals.unitCost, 80);
      expect(totals.netProfit, 32000);
    });
  });
}
