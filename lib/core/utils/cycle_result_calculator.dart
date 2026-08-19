// Module A (cycles/unités) — voir docs/ARCHITECTURE_MODULES.md §1.
// Le "gain théorique par carton" (reference_margin_per_unit) n'entre jamais
// dans ce calcul : il n'est qu'une aide à la saisie du prix côté écran de
// vente, jamais la source du bénéfice net rapporté en fin de cycle.

class CycleSaleValue {
  const CycleSaleValue({
    required this.quantityInBase,
    required this.unitSellPrice,
  });

  final int quantityInBase;
  final double unitSellPrice;
}

class CycleLossValue {
  const CycleLossValue({required this.quantity});

  final int quantity;
}

class CycleResultTotals {
  const CycleResultTotals({
    required this.unitCost,
    required this.revenue,
    required this.soldQuantity,
    required this.soldStockCost,
    required this.lostQuantity,
    required this.lossValue,
    required this.remainingStock,
    required this.netProfit,
  });

  final double unitCost;
  final double revenue;

  /// Combien d'unités de base ont été vendues.
  ///
  /// Calculé de longue date, mais gardé en variable locale : le rapport ne
  /// pouvait donc afficher que de l'argent. Un vendeur d'œufs veut savoir
  /// « j'ai vendu 3 050 œufs », pas seulement « j'ai fait 280 000 F » — et il
  /// devait le déduire lui-même du reçu moins le restant moins les pertes.
  final int soldQuantity;

  final double soldStockCost;

  /// Combien d'unités de base ont été perdues. Même histoire : seule la
  /// **valeur** des pertes était visible, jamais leur nombre. « 4 000 F » ne
  /// dit pas si ce sont 50 œufs cassés ou un carton entier volé.
  final int lostQuantity;

  final double lossValue;
  final int remainingStock;
  final double netProfit;
}

/// Conversion d'une vente saisie dans une unité (plateau, carton...) vers
/// l'unité de base, seule unité dans laquelle le stock et le coût réel sont
/// exprimés. Pur et testable : c'est ce calcul qui détermine le chiffre
/// d'affaires réel de la ligne, donc il ne doit pas vivre dans un écran.
class UnitSaleConversion {
  const UnitSaleConversion({
    required this.quantityInBase,
    required this.pricePerBaseUnit,
    required this.lineTotal,
  });

  final int quantityInBase;
  final double pricePerBaseUnit;
  final double lineTotal;

  static UnitSaleConversion convert({
    required int quantityInUnit,
    required double pricePerUnit,
    required int ratioToBase,
  }) {
    if (ratioToBase <= 0) {
      throw ArgumentError('Le ratio doit être strictement positif.');
    }
    return UnitSaleConversion(
      quantityInBase: quantityInUnit * ratioToBase,
      pricePerBaseUnit: pricePerUnit / ratioToBase,
      lineTotal: quantityInUnit * pricePerUnit,
    );
  }
}

class CycleResultCalculator {
  const CycleResultCalculator._();

  static CycleResultTotals calculate({
    required int quantityReceived,
    required double purchaseCost,
    required Iterable<CycleSaleValue> sales,
    required Iterable<CycleLossValue> losses,
  }) {
    final unitCost = quantityReceived > 0
        ? purchaseCost / quantityReceived
        : 0.0;

    final soldQuantity = sales.fold<int>(
      0,
      (sum, sale) => sum + sale.quantityInBase,
    );
    final lostQuantity = losses.fold<int>(
      0,
      (sum, loss) => sum + loss.quantity,
    );

    final revenue = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.quantityInBase * sale.unitSellPrice,
    );
    final soldStockCost = soldQuantity * unitCost;
    final lossValue = lostQuantity * unitCost;

    return CycleResultTotals(
      unitCost: unitCost,
      revenue: revenue,
      soldQuantity: soldQuantity,
      soldStockCost: soldStockCost,
      lostQuantity: lostQuantity,
      lossValue: lossValue,
      remainingStock: quantityReceived - soldQuantity - lostQuantity,
      netProfit: revenue - soldStockCost - lossValue,
    );
  }
}
