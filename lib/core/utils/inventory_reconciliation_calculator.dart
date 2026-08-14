// Module B (inventaire périodique) — voir docs/ARCHITECTURE_MODULES.md §2.
//
// Principe : le commerçant n'enregistre aucune vente. On déduit ce qui est
// sorti de son stock en comparant deux comptages, puis on croise avec
// l'argent qu'il a réellement encaissé.
//
// Un comptage ne distingue JAMAIS une vente d'un vol : il dit seulement que
// la marchandise n'est plus là. D'où la séparation en niveaux — sorties
// totales, pertes déclarées, ventes présumées — et le refus d'appeler
// « ventes » tout ce qui a disparu.

/// Un achat : une quantité, le prix payé ce jour-là.
class PurchaseLine {
  const PurchaseLine({required this.quantity, required this.unitCost});

  final int quantity;
  final double unitCost;
}

/// Coût unitaire à retenir pour valoriser ce qui est sorti.
///
/// Moyenne pondérée mobile : le stock d'ouverture au coût connu avant la
/// période, plus les achats de la période à leur prix réel. Ce n'est pas du
/// FIFO — on ne sait pas quel exemplaire est parti — mais c'est stable : une
/// fois la période close, aucun changement de prix ne peut la réécrire.
///
/// Sans ligne d'achat, on retombe exactement sur le prix du produit, donc
/// l'historique déjà saisi garde le comportement d'avant.
double weightedUnitCost({
  required int openingStock,
  required List<PurchaseLine> purchasesInPeriod,
  required List<PurchaseLine> purchasesBefore,
  required double productBuyPrice,
}) {
  double averageOf(List<PurchaseLine> lines, double fallback) {
    var quantity = 0;
    var total = 0.0;
    for (final line in lines) {
      quantity += line.quantity;
      total += line.quantity * line.unitCost;
    }
    return quantity > 0 ? total / quantity : fallback;
  }

  final openingCost = averageOf(purchasesBefore, productBuyPrice);
  if (purchasesInPeriod.isEmpty) return openingCost;

  var quantity = openingStock < 0 ? 0 : openingStock;
  var total = quantity * openingCost;
  for (final line in purchasesInPeriod) {
    quantity += line.quantity;
    total += line.quantity * line.unitCost;
  }
  return quantity > 0 ? total / quantity : openingCost;
}

/// Ce qu'on sait d'un produit sur une période, entre deux comptages.
class InventoryProductInput {
  const InventoryProductInput({
    required this.productId,
    required this.productName,
    required this.openingStock,
    required this.countedStock,
    required this.purchases,
    required this.transfersIn,
    required this.transfersOut,
    required this.declaredLosses,
    required this.unitCost,
    required this.unitSellPrice,
  });

  final String productId;
  final String productName;

  /// Comptage précédent : le point de repère d'où part la période.
  final int openingStock;

  /// Comptage d'aujourd'hui.
  final int countedStock;

  final int purchases;
  final int transfersIn;
  final int transfersOut;

  /// Casse, péremption, invendu — déclarés par le commerçant.
  final int declaredLosses;

  /// Dernier prix d'achat connu (le client revalorise au prix du marché).
  final double unitCost;
  final double unitSellPrice;
}

/// Résultat pour un produit. Les quantités restent séparées des montants :
/// la quantité est certaine, la valorisation dépend d'un prix qui a pu bouger.
class InventoryProductResult {
  const InventoryProductResult({
    required this.productId,
    required this.productName,
    required this.totalOutflow,
    required this.declaredLosses,
    required this.presumedSales,
    required this.expectedRevenue,
    required this.costOfGoodsSold,
    required this.lossValue,
  });

  final String productId;
  final String productName;

  /// Ce qui est parti, sans savoir pourquoi.
  final int totalOutflow;

  final int declaredLosses;

  /// Sorties moins les pertes déclarées. « Présumées », jamais certaines.
  final int presumedSales;

  /// Ce que ces ventes auraient dû rapporter.
  final double expectedRevenue;

  final double costOfGoodsSold;
  final double lossValue;

  /// Ce que ce produit a rapporté : ce qu'il vaut moins ce qu'il a coûté.
  /// Par produit, contrairement au bénéfice de la boutique qui part des
  /// recettes réelles — ici on ne sait pas quelle part de l'argent encaissé
  /// vient de quel produit.
  double get margin => expectedRevenue - costOfGoodsSold;

  /// Signale une incohérence de saisie : on a compté plus que ce qui pouvait
  /// rester (achat oublié, comptage erroné). Le résultat n'est pas fiable.
  bool get hasNegativeOutflow => totalOutflow < 0;

  /// Plus de pertes déclarées que de marchandise sortie : impossible.
  bool get lossesExceedOutflow => declaredLosses > totalOutflow;
}

/// Résultat de la période pour une boutique.
class InventoryPeriodResult {
  const InventoryPeriodResult({
    required this.products,
    required this.expectedRevenue,
    required this.actualTakings,
    required this.unexplainedGap,
    required this.costOfGoodsSold,
    required this.lossValue,
    required this.profit,
    required this.daysWithoutTakings,
  });

  final List<InventoryProductResult> products;

  /// Somme de ce que les ventes présumées auraient dû rapporter.
  final double expectedRevenue;

  /// Somme des recettes réellement notées, jour par jour.
  final double actualTakings;

  /// Encaissé − attendu. Négatif = de l'argent manque. C'est la démarque
  /// inconnue du commerce de détail : l'app ne dit pas « on t'a volé »,
  /// elle dit « ceci ne s'explique pas ».
  final double unexplainedGap;

  final double costOfGoodsSold;
  final double lossValue;

  /// Recettes réelles − coût des marchandises sorties. On part de l'argent
  /// encaissé, pas de l'attendu : c'est le seul chiffre certain.
  final double profit;

  /// Jours de la période sans recette notée. Un oubli ressemble à un
  /// manquant : il faut le dire au lieu de laisser accuser un vendeur.
  final int daysWithoutTakings;

  bool get hasUnexplainedGap => unexplainedGap.abs() >= 1;

  /// Produits dont la saisie est incohérente — le résultat les inclut mais
  /// l'écran doit les signaler plutôt que de les présenter comme fiables.
  List<InventoryProductResult> get inconsistentProducts => products
      .where((p) => p.hasNegativeOutflow || p.lossesExceedOutflow)
      .toList();
}

class InventoryReconciliationCalculator {
  const InventoryReconciliationCalculator._();

  static InventoryProductResult calculateProduct(
    InventoryProductInput input,
  ) {
    final totalOutflow =
        input.openingStock +
        input.purchases +
        input.transfersIn -
        input.transfersOut -
        input.countedStock;

    // Les pertes ne peuvent pas dépasser ce qui est sorti.
    final losses = input.declaredLosses.clamp(
      0,
      totalOutflow < 0 ? 0 : totalOutflow,
    );

    // Jamais de ventes négatives dans les montants. Un comptage supérieur au
    // stock possible (approvisionnement oublié, erreur de saisie) donnerait
    // sinon un chiffre d'affaires négatif qui empoisonnerait le total de la
    // boutique — un seul produit mal saisi fausserait tout le rapport.
    // L'anomalie reste visible via `hasNegativeOutflow`.
    final presumedSales = (totalOutflow - losses).clamp(0, 1 << 31);

    return InventoryProductResult(
      productId: input.productId,
      productName: input.productName,
      totalOutflow: totalOutflow,
      declaredLosses: input.declaredLosses,
      presumedSales: presumedSales,
      expectedRevenue: presumedSales * input.unitSellPrice,
      costOfGoodsSold: presumedSales * input.unitCost,
      lossValue: losses * input.unitCost,
    );
  }

  static InventoryPeriodResult calculatePeriod({
    required Iterable<InventoryProductInput> products,
    required double actualTakings,
    int daysWithoutTakings = 0,
  }) {
    final results = products.map(calculateProduct).toList()
      // Les plus gros en premier : sur une centaine de produits, le commerçant
      // ne lit que le haut de la liste, et c'est là que doit se trouver ce qui
      // pèse sur son résultat. L'ordre d'entrée ne veut rien dire pour lui.
      ..sort((a, b) => b.expectedRevenue.compareTo(a.expectedRevenue));

    final expectedRevenue = results.fold<double>(
      0,
      (sum, r) => sum + r.expectedRevenue,
    );
    final costOfGoodsSold = results.fold<double>(
      0,
      (sum, r) => sum + r.costOfGoodsSold,
    );
    final lossValue = results.fold<double>(0, (sum, r) => sum + r.lossValue);

    return InventoryPeriodResult(
      products: results,
      expectedRevenue: expectedRevenue,
      actualTakings: actualTakings,
      unexplainedGap: actualTakings - expectedRevenue,
      costOfGoodsSold: costOfGoodsSold,
      lossValue: lossValue,
      profit: actualTakings - costOfGoodsSold - lossValue,
      daysWithoutTakings: daysWithoutTakings,
    );
  }
}
