/// Sorties qui vident le tiroir sans rien coûter.
///
/// Verser sa recette à la banque ou se payer soi-même n'est pas une dépense :
/// l'argent existe toujours, il a changé de place. Le déduire du bénéfice
/// affichait un résultat négatif chez un commerçant qui met simplement sa
/// caisse en sécurité chaque soir.
///
/// Les autres catégories — repas, transport, fournisseur, personnel — sortent
/// de la caisse **et** du résultat : ce sont de vraies dépenses.
///
/// Comparé au libellé affiché, pas à un code : ces valeurs sont celles que
/// `cash_screen.dart` propose et enregistre telles quelles. Les renommer là-bas
/// sans les changer ici ferait redevenir des déplacements en dépenses, en
/// silence — le test `daily_cash_calculator_test` les fige donc des deux côtés.
const categoriesSansImpactSurLeBenefice = {
  'Versement banque',
  'Retrait patron',
};

class CashMovementValue {
  const CashMovementValue({
    required this.type,
    required this.amount,
    required this.createdAt,
    this.category,
  });

  final String type;
  final double amount;
  final DateTime createdAt;

  /// Ce que le commerçant a choisi dans la liste : « Transport »,
  /// « Versement banque »… Nul pour les mouvements qui n'en portent pas.
  final String? category;
}

class SaleValue {
  const SaleValue({
    required this.amount,
    required this.profit,
    required this.createdAt,
  });

  final double amount;
  final double profit;
  final DateTime createdAt;
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
    double openingBalance = 0,
    required Iterable<SaleValue> sales,
    required Iterable<CashMovementValue> movements,
  }) {
    final movementList = movements.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // `morning_balance` reste le nom technique du tout premier solde saisi
    // pour compatibilité avec les données déjà synchronisées. En caisse
    // continue, ce n'est plus une opération quotidienne : la ligne la plus
    // récente est un point de départ, puis chaque mouvement suivant s'ajoute.
    final checkpoint = movementList
        .where((movement) => movement.type == 'morning_balance')
        .lastOrNull;
    final checkpointAt = checkpoint?.createdAt;
    final effectiveMovements = movementList.where(
      (movement) =>
          movement.type != 'morning_balance' &&
          (checkpointAt == null || movement.createdAt.isAfter(checkpointAt)),
    );
    final effectiveSales = sales.where(
      (sale) => checkpointAt == null || !sale.createdAt.isBefore(checkpointAt),
    );

    final morningBalance = checkpoint?.amount ?? openingBalance;
    final totalWithdrawals = effectiveMovements
        .where((movement) => movement.type == 'withdrawal')
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalIncoming = effectiveMovements
        .where(
          (movement) =>
              movement.type == 'incoming' || movement.type == 'adjustment_in',
        )
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalAdjustmentOut = effectiveMovements
        .where((movement) => movement.type == 'adjustment_out')
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    // Sortir de l'argent n'est pas toujours le DÉPENSER.
    //
    // Un versement à la banque ou un prélèvement du patron vident le tiroir
    // sans rien coûter : l'argent existe toujours, il a changé de place. Les
    // retrancher du bénéfice affichait un résultat négatif chez un commerçant
    // qui met simplement sa recette en sécurité chaque soir — vu le 29/08 :
    // 4 000 F de marge, 20 000 F versés à la banque, « bénéfice −16 000 F ».
    //
    // Repas, transport, fournisseur, personnel restent des dépenses : elles
    // sortent de la caisse ET du résultat.
    final totalDeplacements = effectiveMovements
        .where(
          (movement) =>
              movement.type == 'withdrawal' &&
              categoriesSansImpactSurLeBenefice.contains(movement.category),
        )
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final totalDepenses = totalWithdrawals - totalDeplacements;

    final totalSales = effectiveSales.fold<double>(
      0,
      (sum, sale) => sum + sale.amount,
    );
    final grossProfit = effectiveSales.fold<double>(
      0,
      (sum, sale) => sum + sale.profit,
    );

    return DailyCashTotals(
      morningBalance: morningBalance,
      totalSales: totalSales,
      // La caisse, elle, perd tout ce qui sort — déplacement compris.
      totalWithdrawals: totalWithdrawals,
      calculatedCash:
          morningBalance +
          totalSales +
          totalIncoming -
          totalWithdrawals -
          totalAdjustmentOut,
      grossProfit: grossProfit,
      netProfit: grossProfit - totalDepenses,
    );
  }
}
