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
  const SaleValue({required this.amount, required this.profit});

  final double amount;
  final double profit;
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
    required Iterable<SaleValue> sales,
    required Iterable<CashMovementValue> movements,
  }) {
    final movementList = movements.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final morningBalance =
        movementList
            .where((movement) => movement.type == 'morning_balance')
            .firstOrNull
            ?.amount ??
        0;
    final totalWithdrawals = movementList
        .where((movement) => movement.type == 'withdrawal')
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalSales = sales.fold<double>(0, (sum, sale) => sum + sale.amount);
    final grossProfit = sales.fold<double>(0, (sum, sale) => sum + sale.profit);

    return DailyCashTotals(
      morningBalance: morningBalance,
      totalSales: totalSales,
      totalWithdrawals: totalWithdrawals,
      calculatedCash: morningBalance + totalSales - totalWithdrawals,
      grossProfit: grossProfit,
      netProfit: grossProfit - totalWithdrawals,
    );
  }
}
