class DailyClosingEntity {
  final String id;
  final String shopId;
  final String userId;
  final DateTime closingDate;
  final double morningBalance;
  final double totalSales;
  final double totalWithdrawals;
  final double calculatedCash;
  final double grossProfit;
  final double netProfit;
  final double? physicalCash;
  final double? cashGap;
  final bool isClosed;
  final String? note;

  DailyClosingEntity({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.closingDate,
    required this.morningBalance,
    required this.totalSales,
    required this.totalWithdrawals,
    required this.calculatedCash,
    required this.grossProfit,
    required this.netProfit,
    this.physicalCash,
    this.cashGap,
    required this.isClosed,
    this.note,
  });
}
