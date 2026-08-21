import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/providers/current_shop_provider.dart';
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
      // La boutique active, SURVEILLÉE — le bilan doit se refaire quand on
      // change de boutique.
      //
      // Sans ce filtre, il additionnait les clôtures de toutes les boutiques
      // du téléphone : la journée du 21/08 d'une épicerie en vente simple
      // apparaissait dans le bilan d'une ferme en mode cycles. Le pull
      // fusionne sans jamais vider, donc la base locale les contient toutes.
      final shopId = await watchShopId(ref);

      // Définir le 1er et le dernier jour du mois
      final startDate = DateTime(date.year, date.month, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      // Lire les clôtures locales de ce mois
      final localClosings =
          await (db.select(db.localDailyClosings)
                ..where(
                  (t) =>
                      t.shopId.equals(shopId) &
                      t.closingDate.isBetweenValues(startDate, endDate),
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
