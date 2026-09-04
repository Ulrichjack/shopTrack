// L'argent qui arrive APRÈS la clôture ne doit pas disparaître.
//
// Trouvé le 03/09 sur une question toute simple : « clôturer permet encore de
// recevoir de l'argent en caisse ? » Oui — et il tombait dans un trou.
//
//   18h   clôture, elle compte 100 000
//   19h   une cliente verse 20 000 → le tiroir contient 120 000
//         le lendemain, l'application repartait de 100 000
//
// Le solde du lendemain part du dernier comptage puis n'ajoute que ce qui suit
// la frontière. Quand cette frontière était « minuit », six heures de recettes
// s'évaporaient chaque soir.

import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/daily_cash_calculator.dart';

void main() {
  /// Reproduit ce que fait `soldeCaisseAvant` : on repart du comptage, et on
  /// n'ajoute que les mouvements postérieurs à la frontière.
  double soldeDuLendemain({
    required double compte,
    required DateTime frontiere,
    required List<CashMovementValue> mouvements,
  }) {
    return DailyCashCalculator.calculate(
      openingBalance: compte,
      sales: const [],
      movements: mouvements
          .where((m) => !m.createdAt.isBefore(frontiere))
          .toList(),
    ).calculatedCash;
  }

  final cloture = DateTime(2026, 9, 3, 18);
  final acompteDuSoir = CashMovementValue(
    type: 'incoming',
    amount: 20000,
    category: 'Acompte commande',
    createdAt: DateTime(2026, 9, 3, 19),
  );

  test('la frontière à MINUIT perdait la recette du soir', () {
    // L'ancien comportement, gardé ici pour que personne ne le rétablisse en
    // croyant simplifier.
    final minuit = DateTime(2026, 9, 4);
    expect(
      soldeDuLendemain(
        compte: 100000,
        frontiere: minuit,
        mouvements: [acompteDuSoir],
      ),
      100000,
      reason: 'les 20 000 du soir étaient hors fenêtre : ils disparaissaient',
    );
  });

  test('la frontière à L\'HEURE DE CLÔTURE les garde', () {
    expect(
      soldeDuLendemain(
        compte: 100000,
        frontiere: cloture,
        mouvements: [acompteDuSoir],
      ),
      120000,
      reason: 'le tiroir contient 120 000, l\'application doit dire 120 000',
    );
  });

  test('ce qui précède la clôture n\'est PAS recompté', () {
    // L'erreur symétrique, et elle serait pire : elle inventerait de l'argent.
    // Ces 30 000 sont déjà dans les 100 000 comptés à 18h.
    final venteDuMatin = CashMovementValue(
      type: 'incoming',
      amount: 30000,
      category: 'Acompte commande',
      createdAt: DateTime(2026, 9, 3, 10),
    );
    expect(
      soldeDuLendemain(
        compte: 100000,
        frontiere: cloture,
        mouvements: [venteDuMatin, acompteDuSoir],
      ),
      120000,
      reason: 'seuls les 20 000 d\'après la clôture s\'ajoutent',
    );
  });

  test('une sortie après la clôture retire bien du tiroir', () {
    final remboursement = CashMovementValue(
      type: 'withdrawal',
      amount: 5000,
      category: 'Remboursement commande',
      createdAt: DateTime(2026, 9, 3, 20),
    );
    expect(
      soldeDuLendemain(
        compte: 100000,
        frontiere: cloture,
        mouvements: [acompteDuSoir, remboursement],
      ),
      115000,
      reason: '100 000 + 20 000 − 5 000',
    );
  });
}
