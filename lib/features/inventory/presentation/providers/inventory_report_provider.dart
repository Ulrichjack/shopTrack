import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/current_shop_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/inventory_reconciliation_calculator.dart';
import '../../../products/presentation/providers/product_provider.dart';

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
    this.produitsAFinirDeCompter = const [],
    this.periodesDisponibles = const [],
    this.recettesAvantLePremierComptage = 0,
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

  /// Les produits qu'il reste à compter pour qu'une NOUVELLE période s'ouvre.
  ///
  /// Le rapport ne crée une période que lorsque tous les produits ayant déjà
  /// au moins deux repères ont atteint le même nombre de comptages — il
  /// s'aligne sur le plus petit. Recompter trois articles sur cinq ne change
  /// donc rien à l'écran, et rien ne le disait : le commerçant comptait, allait
  /// voir son bilan, ne voyait pas bouger, et concluait que ça ne marchait pas.
  ///
  /// Vide quand aucun produit n'a pris d'avance.
  final List<String> produitsAFinirDeCompter;
  final List<PeriodeRapportInventaire> periodesDisponibles;

  /// Recettes notées AVANT le tout premier comptage jamais fait.
  ///
  /// Aucune période, présente ou future, ne peut les compter : le premier
  /// comptage est le point de départ, et on ne reconstitue jamais le stock
  /// d'avant. Sans ce compteur, ces recettes disparaissaient du rapport sans
  /// un mot — un commerçant qui note sa semaine puis compte pour la première
  /// fois le dimanche perdait ses six jours sans jamais comprendre pourquoi.
  /// Constaté le 18/08/2026 : 443 250 F envolés, silencieusement, à « 0 F ».
  final int recettesAvantLePremierComptage;

  bool get hasData => result.products.isNotEmpty;

  /// Le total ne vaut que si tout est compté. Un coût partiel comparé à des
  /// recettes complètes donnerait un bénéfice faussement optimiste.
  bool get isComplete =>
      productsNeverCounted == 0 && productsAwaitingSecondCount == 0;

  /// Le verdict financier — bénéfice, écart avec la caisse — n'a de sens que
  /// si ce qu'on a calculé couvre la même chose que ce qu'on a encaissé.
  ///
  /// Il faut les DEUX conditions :
  ///
  /// - **Tout est compté.** La recette est un montant unique pour toute la
  ///   boutique ; on ne peut pas en extraire la part des seuls produits
  ///   comptés. Comparer les sorties de 10 produits à la caisse de 20 affichait
  ///   un excédent qui n'existe pas — sur une boutique à 100 000 F/jour, plus
  ///   d'un million de bénéfice fantôme, en gros et en vert.
  /// - **Aucune recette n'est oubliée.** Un jour non noté produit exactement le
  ///   même chiffre qu'un vol du même montant. Accuser quelqu'un sur un oubli
  ///   de saisie est le pire résultat que cette app puisse produire.
  /// - **Aucun produit compté plus que possible.** Un comptage supérieur au
  ///   stock disponible donne des sorties négatives, ramenées à zéro pour ne
  ///   pas empoisonner le total. Ce zéro efface des ventes réelles : leur
  ///   argent est dans la caisse mais plus dans l'attendu, et l'écart repart
  ///   en excédent fantôme — exactement le défaut que ce garde-fou existe pour
  ///   empêcher, par une autre porte. Cent sacs au départ, cent vingt comptés,
  ///   un arrivage de cinquante oublié : trente sacs vendus disparaissent.
  ///
  /// Le comptage lui-même n'est jamais refusé — c'est une observation, et
  /// « compté plus que possible » est une information utile (un arrivage
  /// manque). Seul le VERDICT attend.
  ///
  /// Quand c'est faux, l'écran montre ce qui est **sorti** — un fait
  /// vérifiable, produit par produit — et ce qu'il reste à faire. Jamais un
  /// montant assorti d'une réserve : le commerçant retient le montant et
  /// oublie la réserve.
  bool get verdictFinancierFiable =>
      isComplete &&
      daysWithoutTakings.isEmpty &&
      result.inconsistentProducts.isEmpty;
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

  // Seuls les produits ayant au moins deux comptages définissent les périodes.
  //
  // En prenant le minimum sur TOUS les produits, un article ajouté hier — ou
  // arrivé par transfert — ramenait le compte à zéro et faisait disparaître
  // tout l'historique des périodes. Un produit qui n'existait pas encore ne
  // peut pas borner une période passée ; il est déjà signalé à part comme
  // « jamais compté ».
  final avecPeriodes = ids
      .where((id) => (parProduit[id]?.length ?? 0) >= 2)
      .toList();
  if (avecPeriodes.isEmpty) return const [];

  var nombreCommun = 1 << 31;
  for (final id in avecPeriodes) {
    final nombre = parProduit[id]!.length;
    if (nombre < nombreCommun) nombreCommun = nombre;
  }
  if (nombreCommun < 2) return const [];

  final periodes = <PeriodeRapportInventaire>[];
  for (var indice = 1; indice < nombreCommun; indice++) {
    DateTime? debut;
    DateTime? fin;
    var complete = true;

    for (final id in avecPeriodes) {
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

    // Un produit archivé reste dans `products` : ses sorties appartiennent aux
    // périodes déjà closes, et un bilan consulté ne se réécrit pas. Le filtrer
    // partout effacerait ses lignes d'un rapport déjà imprimé.
    //
    // Mais il ne peut plus rien BORNER : l'écran de comptage le cache, donc il
    // ne sera jamais recompté. Sans cette distinction, un article rangé
    // bloquait tout — il retenait le nombre de comptages commun, et plus
    // aucune période ne s'ouvrait. Gildas en avait sept dans une seule
    // boutique : assez pour que `isComplete` reste faux à jamais et que le
    // bandeau « résultat partiel » ne parte plus, quoi qu'il compte.
    final produitsActifs = products
        .where((product) => product.archivedAt == null)
        .toList();

    final counts =
        await (db.select(db.localInventoryCounts)
              ..where((row) => row.shopId.equals(shopId))
              ..orderBy([(row) => drift.OrderingTerm.desc(row.countedAt)]))
            .get();

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

    // Seuls les produits ACTIFS décident du nombre de périodes ouvertes : un
    // archivé ne sera plus jamais recompté, il ne peut donc pas retenir la
    // suivante. Les bornes réelles du rapport, elles, sont recalculées plus
    // bas sur tout ce qui entre dans `inputs` — archivés compris.
    final periodesDisponibles = construirePeriodesRapport(
      idsProduits: produitsActifs.map((product) => product.id),
      comptages: counts,
    );
    final demandeExiste = periodesDisponibles.any(
      (periode) => periode.indiceComptage == indiceDemande,
    );
    final indiceSelectionne = demandeExiste
        ? indiceDemande
        : periodesDisponibles.firstOrNull?.indiceComptage;

    // Qui retient la prochaine période ?
    //
    // Une période ne s'ouvre que lorsque tous les produits ont le même nombre
    // de comptages : le rapport s'aligne sur le moins compté. Le seuil à
    // atteindre est donc le MAXIMUM observé — et jamais moins de deux, un
    // comptage seul n'étant qu'un point de départ, pas une période.
    //
    // L'ancienne règle ne regardait que les produits ayant DÉJÀ deux repères.
    // Juste après un premier tour complet, plus personne n'était en retard sur
    // personne : la liste sortait vide alors qu'il restait toute la boutique à
    // recompter. Le commerçant lisait « 10 en attente d'un 2e comptage » sans
    // jamais savoir lesquels — il devait parcourir sa boutique pour les
    // retrouver.
    //
    // Vérifié sur les quatre étapes du scénario à 20 produits : les 20 après
    // le premier tour, les 10 oubliés quand la moitié est recomptée, aucun
    // quand tout est à égalité, les 15 en retard quand 5 ont pris de l'avance.
    final comptagesParId = {
      for (final product in produitsActifs)
        product.id: comptagesParProduit[product.id]?.length ?? 0,
    };
    final seuil = comptagesParId.isEmpty
        ? 2
        : math.max(2, comptagesParId.values.reduce(math.max));
    final produitsAFinir =
        produitsActifs
            .where((p) => (comptagesParId[p.id] ?? 0) < seuil)
            .map((p) => p.name)
            .toList()
          // Le même ordre que l'écran de comptage : c'est là qu'il va les
          // chercher, une liste triée autrement l'oblige à relire chaque nom.
          ..sort(comparerNomsProduits);

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

      // Un archivé qui n'a pas de quoi border cette période n'est ni un oubli
      // ni une attente : il est rangé. Le compter comme manquant retenait
      // `isComplete` à faux pour toujours, puisque plus personne n'ira le
      // compter. En revanche, s'il a ses deux repères, il descend plus bas
      // comme les autres : sa marchandise est bien sortie pendant la période.
      final estArchive = product.archivedAt != null;

      if (last == null) {
        // « Jamais compté » et « pas encore assez compté » ne sont pas la même
        // chose. Un produit compté une fois, alors que la période affichée en
        // demande deux, tombait dans le même sac que ceux qu'on n'a jamais
        // touchés : l'app annonçait « jamais compté » à propos d'un article
        // saisi une heure plus tôt, et le commerçant repartait le compter.
        if (estArchive) continue;
        if (comptagesProduit.isEmpty) {
          neverCounted++;
        } else {
          awaitingSecond++;
        }
        continue;
      }
      final previousAt = last.previousCountedAt;
      if (previousAt == null || last.previousQuantity == null) {
        // Premier comptage : c'est un point de départ, pas une période.
        if (!estArchive) awaitingSecond++;
        continue;
      }

      // Les arrivages de ce produit. Le prix payé, pas le prix affiché
      // aujourd'hui : sinon revaloriser un produit réécrit le coût des
      // périodes déjà closes.
      final productPurchases = purchaseLines.where(
        (p) => p.productId == product.id,
      );

      // Les entrées de stock de la fenêtre, lues sur les lignes d'ARRIVAGE et
      // non sur les mouvements.
      //
      // Les deux décrivent le même geste, mais seule la ligne d'arrivage porte
      // `purchased_at` — le jour où la marchandise est arrivée, que le
      // commerçant peut corriger. Le mouvement, lui, est horodaté par le
      // serveur au moment de l'envoi : une livraison de lundi notée mercredi
      // tombait dans la mauvaise période, et les ventes présumées
      // s'effondraient sans explication. Sur un deuxième téléphone c'était
      // pire encore, la date étant celle de la synchro.
      //
      // Les lignes d'arrivage sont toujours écrites en mode inventaire :
      // l'écran d'ajout y impose un prix d'achat, avec repli sur le prix connu.
      final purchases = productPurchases
          .where(
            (a) =>
                a.purchasedAt.isAfter(previousAt) &&
                !a.purchasedAt.isAfter(last.countedAt),
          )
          .fold<int>(0, (sum, a) => sum + a.quantity);

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

    // Ce que le premier comptage rend à jamais incomptable. Indépendant de la
    // période affichée : ce n'est pas « pas dans CETTE période », c'est
    // « dans AUCUNE période, jamais ».
    final recettesOrphelines = toutPremierComptage == null
        ? 0
        : takings.where((t) {
            final jourRecette = DateTime(t.date.year, t.date.month, t.date.day);
            final jourPremierComptage = DateTime(
              toutPremierComptage.year,
              toutPremierComptage.month,
              toutPremierComptage.day,
            );
            // Comparaison au jour près : le premier comptage porte une
            // heure, une recette du même jour ne doit pas être exclue.
            return jourRecette.isBefore(jourPremierComptage);
          }).length;

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
      // Aujourd'hui ne compte pas : la recette se note le soir, et un
      // comptage fait dans la journée accusait le jour même d'être un oubli.
      // L'accueil applique déjà cette règle — les deux écrans se
      // contredisaient sur le même chiffre.
      final maintenant = DateTime.now();
      final aujourdhui = DateTime(
        maintenant.year,
        maintenant.month,
        maintenant.day,
      );
      // La borne de départ suit EXACTEMENT la règle des recettes ci-dessus :
      // le jour d'ouverture appartient à la période précédente, sauf s'il n'y
      // a rien avant lui.
      //
      // Sans cette symétrie, chaque période à partir de la deuxième réclamait
      // la recette de son jour d'ouverture — déjà encaissée dans la période
      // qui se ferme, et volontairement exclue de ce total-ci. La noter n'y
      // changeait donc rien : elle était filtrée avant d'entrer dans
      // `notedDays`, et le jour restait manquant pour toujours.
      //
      // Tant que ce n'était qu'un bandeau, le défaut passait pour un détail.
      // Depuis que `verdictFinancierFiable` s'appuie dessus, il bloquait le
      // bénéfice de TOUTES les périodes suivantes, définitivement.
      final premierJourAVerifier = ouvertureIncluse
          ? from
          : from.add(const Duration(days: 1));
      for (
        var day = premierJourAVerifier;
        !day.isAfter(to);
        day = day.add(const Duration(days: 1))
      ) {
        if (day == aujourdhui) continue;
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
      produitsAFinirDeCompter: produitsAFinir,
      periodesDisponibles: periodesDisponibles,
      recettesAvantLePremierComptage: recettesOrphelines,
    );
  },
);
