import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/inventory_reconciliation_calculator.dart';
import 'package:shoptrack/features/inventory/presentation/providers/inventory_report_provider.dart';
import 'package:shoptrack/features/inventory/presentation/utils/inventory_report_pdf.dart';

void main() {
  test('le rapport de trois produits produit un PDF valide', () async {
    const produits = [
      InventoryProductResult(
        productId: 'pain',
        productName: 'Pain (pièce)',
        totalOutflow: 20,
        declaredLosses: 0,
        presumedSales: 20,
        expectedRevenue: 3000,
        costOfGoodsSold: 2000,
        lossValue: 0,
      ),
      InventoryProductResult(
        productId: 'jus',
        productName: 'Jus (bouteille)',
        totalOutflow: 12,
        declaredLosses: 0,
        presumedSales: 12,
        expectedRevenue: 6000,
        costOfGoodsSold: 4200,
        lossValue: 0,
      ),
      InventoryProductResult(
        productId: 'riz',
        productName: 'Riz (sac)',
        totalOutflow: 3,
        declaredLosses: 0,
        presumedSales: 3,
        expectedRevenue: 45000,
        costOfGoodsSold: 36000,
        lossValue: 0,
      ),
    ];
    final report = InventoryPeriodReport(
      result: const InventoryPeriodResult(
        products: produits,
        expectedRevenue: 54000,
        actualTakings: 53000,
        unexplainedGap: -1000,
        costOfGoodsSold: 42200,
        lossValue: 0,
        profit: 10800,
        daysWithoutTakings: 0,
      ),
      periodStart: DateTime(2026, 8, 1),
      periodEnd: DateTime(2026, 8, 14),
      productsAwaitingSecondCount: 0,
      productsNeverCounted: 0,
      daysWithoutTakings: [],
    );

    final bytes = await buildInventoryReportPdf(
      report,
      shopName: 'Boutique Test',
    );

    expect(bytes, isNotEmpty);
    expect(bytes.take(4), orderedEquals('%PDF'.codeUnits));
  });

  test('les pertes déclarées apparaissent dans le PDF', () async {
    // Sans cette ligne, Recettes − Coût ne redonne pas le Bénéfice imprimé :
    // 13 000 F d'écart pour qui refait l'addition sur le document partagé.
    final report = InventoryPeriodReport(
      result: const InventoryPeriodResult(
        products: [
          InventoryProductResult(
            productId: 'huile',
            productName: 'Bidon huile 5L (bidon)',
            totalOutflow: 15,
            declaredLosses: 2,
            presumedSales: 13,
            expectedRevenue: 97500,
            costOfGoodsSold: 84500,
            lossValue: 13000,
          ),
        ],
        expectedRevenue: 97500,
        actualTakings: 110000,
        unexplainedGap: 12500,
        costOfGoodsSold: 84500,
        lossValue: 13000,
        profit: 12500,
        daysWithoutTakings: 0,
      ),
      periodStart: DateTime(2026, 8, 1),
      periodEnd: DateTime(2026, 8, 14),
      productsAwaitingSecondCount: 0,
      productsNeverCounted: 0,
      daysWithoutTakings: [],
    );

    final bytes = await buildInventoryReportPdf(report);
    expect(bytes, isNotEmpty);
    expect(bytes.take(4), orderedEquals('%PDF'.codeUnits));
  });
}
