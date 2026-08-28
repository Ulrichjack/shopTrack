class CashMovementValue {
  const CashMovementValue({
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  final String type;
  final double amount;
  final DateTime createdAt;
}

class SaleValue {
  const SaleValue({
    required this.amount,
    required this.profit,
    required this.createdAt,
  });

  final double amount;
  final double profit;
  final DateTime createdAt;
}

class DailyCashTotals {
  const DailyCashTotals({
    required this.morningBalance,
    required this.totalSales,
    required this.totalWithdrawals,
    required this.calculatedCash,
    required this.grossProfit,
    required this.netProfit,
  });

  final double morningBalance;
  final double totalSales;
  final double totalWithdrawals;
  final double calculatedCash;
  final double grossProfit;
  final double netProfit;
}

class DailyCashCalculator {
  const DailyCashCalculator._();

  static DailyCashTotals calculate({
    double openingBalance = 0,
    required Iterable<SaleValue> sales,
    required Iterable<CashMovementValue> movements,
  }) {
    final movementList = movements.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // `morning_balance` reste le nom technique du tout premier solde saisi
    // pour compatibilité avec les données déjà synchronisées. En caisse
    // continue, ce n'est plus une opération quotidienne : la ligne la plus
    // récente est un point de départ, puis chaque mouvement suivant s'ajoute.
    final checkpoint = movementList
        .where((movement) => movement.type == 'morning_balance')
        .lastOrNull;
    final checkpointAt = checkpoint?.createdAt;
    final effectiveMovements = movementList.where(
      (movement) =>
          movement.type != 'morning_balance' &&
          (checkpointAt == null || movement.createdAt.isAfter(checkpointAt)),
    );
    final effectiveSales = sales.where(
      (sale) => checkpointAt == null || !sale.createdAt.isBefore(checkpointAt),
    );

    final morningBalance = checkpoint?.amount ?? openingBalance;
    final totalWithdrawals = effectiveMovements
        .where((movement) => movement.type == 'withdrawal')
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalIncoming = effectiveMovements
        .where(
          (movement) =>
              movement.type == 'incoming' || movement.type == 'adjustment_in',
        )
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalAdjustmentOut = effectiveMovements
        .where((movement) => movement.type == 'adjustment_out')
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalSales = effectiveSales.fold<double>(
      0,
      (sum, sale) => sum + sale.amount,
    );
    final grossProfit = effectiveSales.fold<double>(
      0,
      (sum, sale) => sum + sale.profit,
    );

    return DailyCashTotals(
      morningBalance: morningBalance,
      totalSales: totalSales,
      totalWithdrawals: totalWithdrawals,
      calculatedCash:
          morningBalance +
          totalSales +
          totalIncoming -
          totalWithdrawals -
          totalAdjustmentOut,
      grossProfit: grossProfit,
      netProfit: grossProfit - totalWithdrawals,
    );
  }
}
