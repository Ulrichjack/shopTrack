import '../../domain/entities/daily_closing_entity.dart';

class DailyClosingModel extends DailyClosingEntity {
  DailyClosingModel({
    required super.id,
    required super.shopId,
    required super.userId,
    required super.closingDate,
    required super.morningBalance,
    required super.totalSales,
    required super.totalWithdrawals,
    required super.calculatedCash,
    required super.grossProfit,
    required super.netProfit,
    super.physicalCash,
    super.cashGap,
    required super.isClosed,
    super.note,
  });

  factory DailyClosingModel.fromJson(Map<String, dynamic> json) {
    return DailyClosingModel(
      id: json['id'].toString(),
      shopId: json['shop_id'].toString(),
      userId: json['user_id'].toString(),
      closingDate: DateTime.parse(json['closing_date'].toString()),
      morningBalance: double.parse(json['morning_balance'].toString()),
      totalSales: double.parse(json['total_sales'].toString()),
      totalWithdrawals: double.parse(json['total_withdrawals'].toString()),
      calculatedCash: double.parse(json['calculated_cash'].toString()),
      grossProfit: double.parse(json['gross_profit'].toString()),
      netProfit: double.parse(json['net_profit'].toString()),
      physicalCash: json['physical_cash'] != null
          ? double.parse(json['physical_cash'].toString())
          : null,
      cashGap: json['cash_gap'] != null
          ? double.parse(json['cash_gap'].toString())
          : null,
      isClosed: json['is_closed'] ?? false,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'user_id': userId,
      'closing_date':
          "${closingDate.year}-${closingDate.month.toString().padLeft(2, '0')}-${closingDate.day.toString().padLeft(2, '0')}",
      'morning_balance': morningBalance,
      'total_sales': totalSales,
      'total_withdrawals': totalWithdrawals,
      'calculated_cash': calculatedCash,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
      'physical_cash': physicalCash,
      'cash_gap': cashGap,
      'is_closed': isClosed,
      'note': note,
      // closed_at sera géré automatiquement par Supabase via now()
    };
  }
}
