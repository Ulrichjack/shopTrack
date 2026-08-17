import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/current_shop_provider.dart';
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
    this.periodesDisponibles = const [],
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
  final List<PeriodeRapportInventaire> periodesDisponibles;

  bool get hasData => result.products.isNotEmpty;

  /// Le total ne vaut que si tout est compté. Un coût partiel comparé à des
  /// recettes complètes donnerait un bénéfice faussement optimiste.
  bool get isComplete =>
      productsNeverCounted == 0 && productsAwaitingSecondCount == 0;
}

class PeriodeRapportInventaire {
  const PeriodeRapportInventaire({
    required this.indiceComptage,
    required this.debut,
    required this.fin,
  });

  /// Le premier comptage pose le repère ; l'indice 1 désigne donc la
  /// première période réellement fermée par un deuxième comptage.
  final int indiceComptage;
  final DateTime debut;
  final DateTime fin;
}

/// Une période n'est proposée que si chaque produit possède les deux repères
/// qui la bornent : afficher une période partielle donnerait un total trompeur.
List<PeriodeRapportInventaire> construirePeriodesRapport({
  required Iterable<String> idsProduits,
  required Iterable<LocalInventoryCount> comptages,
}) {
  final ids = idsProduits.toSet();
  if (ids.isEmpty) return const [];

  final parProduit = <String, List<LocalInventoryCount>>{};
  for (final comptage in comptages) {
    if (!ids.contains(comptage.productId)) continue;
    parProduit.putIfAbsent(comptage.productId, () => []).add(comptage);
  }
  for (final liste in parProduit.values) {
    liste.sort((a, b) => a.countedAt.compareTo(b.countedAt));
  }

  var nombreCommun = 1 << 31;
  for (final id in ids) {
    final nombre = parProduit[id]?.length ?? 0;
    if (nombre < nombreCommun) nombreCommun = nombre;
  }
  if (nombreCommun < 2) return const [];

  final periodes = <PeriodeRapportInventaire>[];
  for (var indice = 1; indice < nombreCommun; indice++) {
    DateTime? debut;
    DateTime? fin;
    var complete = true;

    for (final id in ids) {
      final comptage = parProduit[id]![indice];
      final precedent = comptage.previousCountedAt;
      if (precedent == null || comptage.previousQuantity == null) {
        complete = false;
        break;
      }
      if (debut == null || precedent.isBefore(debut)) debut = precedent;
      if (fin == null || comptage.countedAt.isAfter(fin)) {
        fin = comptage.countedAt;
      }
    }

    if (complete) {
      periodes.add(
        PeriodeRapportInventaire(
          indiceComptage: indice,
          debut: debut!,
          fin: fin!,
        ),
      );
    }
  }

  return periodes.reversed.toList();
}

final inventoryReportProvider = FutureProvider.family<InventoryPeriodReport, int?>(
  (ref, indiceDemande) async {
    final shopId = await watchShopId(ref);

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

    final losses = await (db.select(
      db.localInventoryLosses,
    )..where((row) => row.shopId.equals(shopId))).get();

    final purchaseLines = await (db.select(
      db.localStockPurchases,
    )..where((row) => row.shopId.equals(shopId))).get();

    final priceLines = await (db.select(
      db.localProductPrices,
    )..where((row) => row.shopId.equals(shopId))).get();

    // Les deux sens sont dans la même table : on filtre par boutique au
    // moment de compter, pas ici.
    final transferts =
        await (db.select(db.localStockTransfers)..where(
              (row) =>
                  row.fromShopId.equals(shopId) | row.toShopId.equals(shopId),
            ))
            .get();

    final comptagesParProduit = <String, List<LocalInventoryCount>>{};
    for (final count in counts) {
      comptagesParProduit.putIfAbsent(count.productId, () => []).add(count);
    }
    for (final comptagesProduit in comptagesParProduit.values) {
      comptagesProduit.sort((a, b) => a.countedAt.compareTo(b.countedAt));
    }

    final periodesDisponibles = construirePeriodesRapport(
      idsProduits: products.map((product) => product.id),
      comptages: counts,
    );
    final demandeExiste = periodesDisponibles.any(
      (periode) => periode.indiceComptage == indiceDemande,
    );
    final indiceSelectionne = demandeExiste
        ? indiceDemande
        : periodesDisponibles.firstOrNull?.indiceComptage;

    final inputs = <InventoryProductInput>[];
    var awaitingSecond = 0;
    var neverCounted = 0;
    DateTime? periodStart;
    DateTime? periodEnd;

    for (final product in products) {
      final comptagesProduit =
          comptagesParProduit[product.id] ?? const <LocalInventoryCount>[];
      final last = indiceSelectionne == null
          ? comptagesProduit.lastOrNull
          : indiceSelectionne < comptagesProduit.length
          ? comptagesProduit[indiceSelectionne]
          : null;

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

      // Pertes déclarées sur la même fenêtre. Sans elles, la casse se retrouve
      // dans les ventes présumées : l'app réclame l'argent d'une bouteille
      // cassée et le manquant ressemble à un vol.
      //
      // Comparaison au JOUR, comme les recettes : le commerçant déclare « j'ai
      // cassé 3 bouteilles le 14 », pas « à 12h07 ». À la seconde près, une
      // perte notée après le comptage du matin tombait dans la période suivante
      // et le rapport ne bougeait pas — et une date choisie au calendrier vaut
      // minuit, donc avant le comptage, donc exclue elle aussi.
      final debutJour = DateTime(
        previousAt.year,
        previousAt.month,
        previousAt.day,
      );
      final finJour = DateTime(
        last.countedAt.year,
        last.countedAt.month,
        last.countedAt.day,
      );
      // Le jour d'ouverture n'appartient à cette période que s'il n'y a rien
      // avant : sinon la période précédente s'est déjà fermée ce jour-là et a
      // déjà compté cette perte. Sans cette borne, une perte du 14 était
      // comptée DEUX fois — dans la période qui finit le 14 et dans celle qui
      // commence le 14.
      final estPremierePeriode =
          comptagesProduit.isNotEmpty &&
          comptagesProduit.first.countedAt.isAtSameMomentAs(previousAt);
      final declaredLosses = losses
          .where((l) {
            if (l.productId != product.id) return false;
            final jour = DateTime(
              l.occurredAt.year,
              l.occurredAt.month,
              l.occurredAt.day,
            );
            if (jour.isAfter(finJour)) return false;
            return estPremierePeriode
                ? !jour.isBefore(debutJour)
                : jour.isAfter(debutJour);
          })
          .fold<int>(0, (sum, l) => sum + l.quantity);

      // Ce qui est entré et sorti par transfert sur la fenêtre.
      //
      // Reçu : la quantité **réellement arrivée** si quelqu'un a confirmé,
      // sinon celle envoyée. La marchandise est sur l'étagère, qu'on ait tapé
      // sur un bouton ou non — attendre la confirmation ferait apparaître un
      // faux « compté plus que possible » au comptage suivant.
      //
      // Envoyé : la quantité expédiée. Le manquant éventuel est une perte de
      // transport de l'expéditeur, comptée plus bas : sans elle, il
      // deviendrait un écart inexpliqué chez lui, donc un vol présumé.
      var transfersIn = 0;
      var transfersOut = 0;
      var perteTransport = 0;
      for (final t in transferts) {
        if (t.productId != product.id) continue;
        if (t.transferredAt.isBefore(previousAt) ||
            t.transferredAt.isAfter(last.countedAt)) {
          continue;
        }
        if (t.toShopId == shopId) {
          transfersIn += t.receivedQuantity ?? t.quantity;
        } else if (t.fromShopId == shopId) {
          transfersOut += t.quantity;
          final recu = t.receivedQuantity;
          if (recu != null && recu < t.quantity) {
            perteTransport += t.quantity - recu;
          }
        }
      }

      // Le prix payé, pas le prix affiché aujourd'hui : sinon revaloriser un
      // produit réécrit le coût des périodes déjà closes.
      final productPurchases = purchaseLines.where(
        (p) => p.productId == product.id,
      );
      final historique = priceLines
          .where((p) => p.productId == product.id)
          .map(
            (p) => PricePoint(
              effectiveAt: p.effectiveAt,
              sellPrice: p.sellPrice,
              buyPrice: p.buyPrice,
            ),
          )
          .toList();
      final unitCost = weightedUnitCost(
        openingStock: last.previousQuantity!,
        purchasesInPeriod: productPurchases
            .where(
              (p) =>
                  p.purchasedAt.isAfter(previousAt) &&
                  !p.purchasedAt.isAfter(last.countedAt),
            )
            .map(
              (p) => PurchaseLine(quantity: p.quantity, unitCost: p.unitCost),
            )
            .toList(),
        purchasesBefore: productPurchases
            .where((p) => !p.purchasedAt.isAfter(previousAt))
            .map(
              (p) => PurchaseLine(quantity: p.quantity, unitCost: p.unitCost),
            )
            .toList(),
        // Le stock déjà en rayon garde le prix auquel il a été acheté, pas
        // celui du dernier arrivage : c'est le gros du volume, et le laisser
        // suivre le prix du jour faisait bouger toute la période close.
        openingCost: buyPriceAt(previousAt, historique, product.buyPrice),
      );

      // Le tarif pratiqué pendant la période, pas celui d'aujourd'hui : sinon
      // remonter un prix réévalue tout seul les périodes déjà closes et l'écart
      // avec la caisse devient faux sans que rien ne le signale.
      final unitSellPrice = weightedSellPrice(
        periodStart: previousAt,
        periodEnd: last.countedAt,
        priceHistory: historique,
        productSellPrice: product.sellPrice,
      );

      inputs.add(
        InventoryProductInput(
          productId: product.id,
          productName: (product.unit ?? '').trim().isEmpty
              ? product.name
              : '${product.name} (${product.unit!.trim()})',
          openingStock: last.previousQuantity!,
          countedStock: last.countedQuantity,
          purchases: purchases,
          transfersIn: transfersIn,
          transfersOut: transfersOut,
          // La perte de transport rejoint les pertes déclarées : elle est
          // connue et expliquée, elle n'a rien à faire dans l'inexpliqué.
          declaredLosses: declaredLosses + perteTransport,
          unitCost: unitCost,
          unitSellPrice: unitSellPrice,
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

    // Même règle que pour les pertes : le jour d'ouverture appartient à la
    // période qui se ferme, sauf s'il n'y a rien avant elle. Sans ça, la
    // recette du jour de bascule était encaissée DEUX fois — une fois dans
    // chaque période — et l'écart des deux rapports devenait faux.
    final toutPremierComptage = counts.isEmpty
        ? null
        : counts
              .map((c) => c.countedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final ouvertureIncluse =
        periodStart != null &&
        toutPremierComptage != null &&
        !periodStart.isAfter(toutPremierComptage);

    var actualTakings = 0.0;
    final notedDays = <DateTime>{};
    if (periodStart != null && periodEnd != null) {
      final from = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final to = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      for (final taking in takings) {
        final day = DateTime(
          taking.date.year,
          taking.date.month,
          taking.date.day,
        );
        if (day.isAfter(to)) continue;
        if (ouvertureIncluse ? day.isBefore(from) : !day.isAfter(from)) {
          continue;
        }
        actualTakings += taking.amount;
        notedDays.add(day);
      }
    }

    // Jours de la période sans recette notée : un oubli ressemble à un
    // manquant, il faut le signaler avant que quelqu'un soit soupçonné.
    final missing = <DateTime>[];
    if (periodStart != null && periodEnd != null) {
      final from = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final to = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      for (
        var day = from;
        !day.isAfter(to);
        day = day.add(const Duration(days: 1))
      ) {
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
      periodesDisponibles: periodesDisponibles,
    );
  },
);
