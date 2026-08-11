import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/cycle_result_calculator.dart';

class CycleReport {
  const CycleReport({required this.cycle, required this.totals});

  final LocalSupplyCycle cycle;
  final CycleResultTotals totals;
}

final cycleReportProvider = FutureProvider.family<CycleReport, String>((
  ref,
  cycleId,
) async {
  final db = ref.watch(localDbProvider);

  final cycle = await (db.select(
    db.localSupplyCycles,
  )..where((t) => t.id.equals(cycleId))).getSingle();

  final saleRows =
      await (db.select(db.localSaleItems)
            ..where((t) => t.cycleId.equals(cycleId)))
          .get();
  final lossRows =
      await (db.select(db.localCycleLosses)
            ..where((t) => t.cycleId.equals(cycleId)))
          .get();

  final totals = CycleResultCalculator.calculate(
    quantityReceived: cycle.quantityReceived,
    purchaseCost: cycle.purchaseCost,
    sales: saleRows.map(
      (row) => CycleSaleValue(
        quantityInBase: row.quantityInBase ?? 0,
        unitSellPrice: row.unitSellPrice ?? 0,
      ),
    ),
    losses: lossRows.map((row) => CycleLossValue(quantity: row.quantity)),
  );

  return CycleReport(cycle: cycle, totals: totals);
});
