import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/inventory_reconciliation_calculator.dart';

/// Rapport d'une période, reconstruit depuis les repères de comptage.
///
/// La période n'est pas un mois : elle court du comptage précédent au
/// dernier, produit par produit. C'est ce que le client demandait — compter
/// « à la fin du mois ou du trimestre », quand il en a le temps.
class InventoryPeriodReport {
  const InventoryPeriodReport({
    required this.result,
    required this.periodStart,
    required this.periodEnd,
    required this.productsAwaitingSecondCount,
    required this.productsNeverCounted,
    required this.daysWithoutTakings,
  });

  final InventoryPeriodResult result;

  /// Bornes réelles des comptages retenus, pas un mois calendaire.
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// Produits comptés une seule fois : le repère de départ est posé, mais il
  /// n'y a pas encore de période à calculer.
  final int productsAwaitingSecondCount;

  /// Produits jamais comptés : ils manquent au résultat, et on le dit plutôt
  /// que de présenter un total qui aurait l'air complet.
  final int productsNeverCounted;

  final List<DateTime> daysWithoutTakings;

  bool get hasData => result.products.isNotEmpty;

  /// Le total ne vaut que si tout est compté. Un coût partiel comparé à des
  /// recettes complètes donnerait un bénéfice faussement optimiste.
  bool get isComplete =>
      productsNeverCounted == 0 && productsAwaitingSecondCount == 0;
}

final inventoryReportProvider = FutureProvider<InventoryPeriodReport>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final shopId = prefs.getString('cached_shop_id');
  if (shopId == null || shopId.isEmpty) {
    throw Exception('Boutique introuvable.');
  }

  final db = ref.watch(localDbProvider);

  final products = await (db.select(
    db.localProducts,
  )..where((row) => row.shopId.equals(shopId))).get();

  final counts =
      await (db.select(db.localInventoryCounts)
            ..where((row) => row.shopId.equals(shopId))
            ..orderBy([(row) => drift.OrderingTerm.desc(row.countedAt)]))
          .get();

  final movements = await (db.select(
    db.localStockMovements,
  )..where((row) => row.shopId.equals(shopId))).get();

  final inputs = <InventoryProductInput>[];
  var awaitingSecond = 0;
  var neverCounted = 0;
  DateTime? periodStart;
  DateTime? periodEnd;

  for (final product in products) {
    final last = counts.where((c) => c.productId == product.id).firstOrNull;

    if (last == null) {
      neverCounted++;
      continue;
    }
    final previousAt = last.previousCountedAt;
    if (previousAt == null || last.previousQuantity == null) {
      // Premier comptage : c'est un point de départ, pas une période.
      awaitingSecond++;
      continue;
    }

    // Les entrées de stock de la fenêtre. On réutilise les recharges déjà
    // enregistrées par l'app plutôt que d'attendre une table dédiée : c'est
    // le geste que le commerçant fait déjà quand il s'approvisionne.
    final purchases = movements
        .where(
          (m) =>
              m.productId == product.id &&
              m.type == 'recharge' &&
              m.createdAt.isAfter(previousAt) &&
              !m.createdAt.isAfter(last.countedAt),
        )
        .fold<int>(0, (sum, m) => sum + m.quantity);

    inputs.add(
      InventoryProductInput(
        productId: product.id,
        productName: (product.unit ?? '').trim().isEmpty
            ? product.name
            : '${product.name} (${product.unit!.trim()})',
        openingStock: last.previousQuantity!,
        countedStock: last.countedQuantity,
        purchases: purchases,
        // Transferts et pertes déclarées : tables prêtes côté Supabase, pas
        // encore saisissables dans l'app (B5, B8).
        transfersIn: 0,
        transfersOut: 0,
        declaredLosses: 0,
        unitCost: product.buyPrice,
        unitSellPrice: product.sellPrice,
      ),
    );

    if (periodStart == null || previousAt.isBefore(periodStart)) {
      periodStart = previousAt;
    }
    if (periodEnd == null || last.countedAt.isAfter(periodEnd)) {
      periodEnd = last.countedAt;
    }
  }

  // Recettes encaissées sur la fenêtre couverte par les comptages.
  final takings = await (db.select(
    db.localShopTakings,
  )..where((row) => row.shopId.equals(shopId))).get();

  var actualTakings = 0.0;
  final notedDays = <DateTime>{};
  if (periodStart != null && periodEnd != null) {
    final from = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final to = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    for (final taking in takings) {
      final day = DateTime(taking.date.year, taking.date.month, taking.date.day);
      if (!day.isBefore(from) && !day.isAfter(to)) {
        actualTakings += taking.amount;
        notedDays.add(day);
      }
    }
  }

  // Jours de la période sans recette notée : un oubli ressemble à un
  // manquant, il faut le signaler avant que quelqu'un soit soupçonné.
  final missing = <DateTime>[];
  if (periodStart != null && periodEnd != null) {
    final from = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final to = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    for (var day = from; !day.isAfter(to); day = day.add(
      const Duration(days: 1),
    )) {
      if (!notedDays.contains(day)) missing.add(day);
    }
  }

  return InventoryPeriodReport(
    result: InventoryReconciliationCalculator.calculatePeriod(
      products: inputs,
      actualTakings: actualTakings,
      daysWithoutTakings: missing.length,
    ),
    periodStart: periodStart,
    periodEnd: periodEnd,
    productsAwaitingSecondCount: awaitingSecond,
    productsNeverCounted: neverCounted,
    daysWithoutTakings: missing,
  );
});
