import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/sync/sync_service.dart';
import '../../../dashboard/domain/entities/daily_closing_entity.dart';

class MonthlyReportState {
  final double totalSales;
  final double totalNetProfit;
  final double totalWithdrawals;
  final double totalCashGap;
  final double totalShortage;
  final double totalSurplus;
  final double cashAdjustedResult;
  final List<DailyClosingEntity> dailyClosings;

  MonthlyReportState({
    required this.totalSales,
    required this.totalNetProfit,
    required this.totalWithdrawals,
    required this.totalCashGap,
    required this.totalShortage,
    required this.totalSurplus,
    required this.cashAdjustedResult,
    required this.dailyClosings,
  });
}

// 👇 NOUVEAU : Lecture 100% Locale (Drift) 👇
final monthlyReportProvider =
    FutureProvider.family<MonthlyReportState, DateTime>((ref, date) async {
      final db = ref.read(localDbProvider);

      // Définir le 1er et le dernier jour du mois
      final startDate = DateTime(date.year, date.month, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      // Lire les clôtures locales de ce mois
      final localClosings =
          await (db.select(db.localDailyClosings)
                ..where(
                  (t) => t.closingDate.isBetweenValues(startDate, endDate),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.closingDate)]))
              .get();

      final closings = localClosings
          .map(
            (c) => DailyClosingEntity(
              id: c.id,
              shopId: c.shopId,
              userId: c.userId,
              closingDate: c.closingDate,
              morningBalance: c.morningBalance,
              totalSales: c.totalSales,
              totalWithdrawals: c.totalWithdrawals,
              calculatedCash: c.calculatedCash,
              grossProfit: c.grossProfit,
              netProfit: c.netProfit,
              physicalCash: c.physicalCash,
              cashGap: c.cashGap,
              isClosed: c.isClosed,
              note: c.note,
            ),
          )
          .toList();

      double totalSales = 0;
      double totalNetProfit = 0;
      double totalWithdrawals = 0;
      double totalCashGap = 0;
      double totalShortage = 0;
      double totalSurplus = 0;

      for (var closing in closings) {
        totalSales += closing.totalSales;
        totalNetProfit += closing.netProfit;
        totalWithdrawals += closing.totalWithdrawals;
        final gap = closing.cashGap ?? 0;
        totalCashGap += gap;
        if (gap < 0) {
          totalShortage += gap.abs();
        } else {
          totalSurplus += gap;
        }
      }

      return MonthlyReportState(
        totalSales: totalSales,
        totalNetProfit: totalNetProfit,
        totalWithdrawals: totalWithdrawals,
        totalCashGap: totalCashGap,
        totalShortage: totalShortage,
        totalSurplus: totalSurplus,
        cashAdjustedResult: totalNetProfit + totalCashGap,
        dailyClosings: closings,
      );
    });
