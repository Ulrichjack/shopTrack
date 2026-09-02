import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/daily_cash_calculator.dart';

void main() {
  group('DailyCashCalculator', () {
    test('utilise uniquement le dernier solde du matin', () {
      final totals = DailyCashCalculator.calculate(
        sales: [
          SaleValue(
            amount: 10000,
            profit: 3000,
            createdAt: DateTime(2026, 7, 27, 10),
          ),
        ],
        movements: [
          CashMovementValue(
            type: 'morning_balance',
            amount: 5000,
            createdAt: DateTime(2026, 7, 27, 7),
          ),
          CashMovementValue(
            type: 'morning_balance',
            amount: 7000,
            createdAt: DateTime(2026, 7, 27, 8),
          ),
          CashMovementValue(
            type: 'withdrawal',
            amount: 1000,
            createdAt: DateTime(2026, 7, 27, 12),
          ),
        ],
      );

      expect(totals.morningBalance, 7000);
      expect(totals.calculatedCash, 16000);
      expect(totals.netProfit, 2000);
    });

    test('sépare le chiffre d’affaires du bénéfice', () {
      final totals = DailyCashCalculator.calculate(
        sales: [
          SaleValue(
            amount: 5000,
            profit: 1200,
            createdAt: DateTime(2026, 7, 27, 10),
          ),
          SaleValue(
            amount: 3000,
            profit: 800,
            createdAt: DateTime(2026, 7, 27, 11),
          ),
        ],
        movements: const [],
      );

      expect(totals.totalSales, 8000);
      expect(totals.grossProfit, 2000);
      expect(totals.calculatedCash, 8000);
    });

    test('retourne zéro pour une journée vide', () {
      final totals = DailyCashCalculator.calculate(
        sales: const [],
        movements: const [],
      );

      expect(totals.morningBalance, 0);
      expect(totals.totalSales, 0);
      expect(totals.totalWithdrawals, 0);
      expect(totals.calculatedCash, 0);
      expect(totals.netProfit, 0);
    });

    test('une boutique sans clôture ni mouvement démarre à zéro', () {
      final totals = DailyCashCalculator.calculate(
        openingBalance: 0,
        sales: const [],
        movements: const [],
      );

      expect(totals.calculatedCash, 0);
    });

    test('le solde continu traverse une journée vide sans remise à zéro', () {
      final totals = DailyCashCalculator.calculate(
        openingBalance: 50000,
        sales: const [],
        movements: const [],
      );

      expect(totals.morningBalance, 50000);
      expect(totals.calculatedCash, 50000);
    });

    test(
      'les entrées, sorties et ajustements modifient la caisse continue',
      () {
        final totals = DailyCashCalculator.calculate(
          openingBalance: 50000,
          sales: [
            SaleValue(
              amount: 10000,
              profit: 2500,
              createdAt: DateTime(2026, 8, 28, 10),
            ),
          ],
          movements: [
            CashMovementValue(
              type: 'incoming',
              amount: 5000,
              createdAt: DateTime(2026, 8, 28, 11),
            ),
            CashMovementValue(
              type: 'withdrawal',
              amount: 3000,
              createdAt: DateTime(2026, 8, 28, 12),
            ),
            CashMovementValue(
              type: 'adjustment_out',
              amount: 10000,
              createdAt: DateTime(2026, 8, 28, 13),
            ),
          ],
        );

        expect(totals.calculatedCash, 52000);
        expect(totals.totalWithdrawals, 3000);
        expect(totals.netProfit, -500);
      },
    );
    test(
      'un versement à la banque vide la caisse sans amputer le bénéfice',
      () {
        // Sortir de l'argent n'est pas le dépenser : verser sa recette à la
        // banque ou se payer soi-même déplace l'argent, ne le consomme pas.
        // Retranché du bénéfice, un commerçant qui met sa caisse en sécurité
        // chaque soir affichait un résultat négatif — vu le 29/08/2026 :
        // 4 000 F de marge, 20 000 F versés, « bénéfice −16 000 F ».
        final totals = DailyCashCalculator.calculate(
          openingBalance: 30000,
          sales: [
            SaleValue(
              amount: 25000,
              profit: 4000,
              createdAt: DateTime(2026, 8, 24, 10),
            ),
          ],
          movements: [
            CashMovementValue(
              type: 'withdrawal',
              amount: 20000,
              category: 'Versement banque',
              createdAt: DateTime(2026, 8, 24, 18),
            ),
            CashMovementValue(
              type: 'withdrawal',
              amount: 1500,
              category: 'Transport',
              createdAt: DateTime(2026, 8, 24, 12),
            ),
          ],
        );

        // La caisse perd TOUT ce qui sort : 30 000 + 25 000 − 21 500.
        expect(totals.calculatedCash, 33500);
        expect(totals.totalWithdrawals, 21500);

        // Le bénéfice ne perd que la vraie dépense : 4 000 − 1 500.
        expect(
          totals.netProfit,
          2500,
          reason: 'le versement bancaire ne coûte rien, il déplace',
        );
      },
    );

    test('les catégories sans impact sont les mêmes des deux côtés', () {
      // Ce test existe pour un renommage : changer « Versement banque » dans
      // l'écran de saisie sans le changer ici referait des déplacements de
      // simples dépenses, sans qu'aucun test n'échoue.
      expect(categoriesSansImpactSurLeBenefice, {
        'Versement banque',
        'Retrait patron',
        'Remise à la patronne',
        // Écrite par le module commandes, pas par l'écran de caisse : rendre un
        // acompte n'est pas une dépense, l'argent avancé n'était jamais entré
        // dans le bénéfice.
        'Remboursement commande',
        'Entrée depuis un compte',
      });
    });

    test('rendre un acompte vide la caisse sans creuser le bénéfice', () {
      // L'acompte est entré en `incoming`, pas en vente : il n'a jamais gonflé
      // le bénéfice. Le rendre en `withdrawal` ordinaire l'aurait donc rendu
      // négatif — la même erreur que le versement à la banque, sur un module
      // neuf.
      final totals = DailyCashCalculator.calculate(
        sales: [
          SaleValue(
            amount: 12000,
            profit: 3000,
            createdAt: DateTime(2026, 8, 31, 10),
          ),
        ],
        movements: [
          CashMovementValue(
            type: 'morning_balance',
            amount: 20000,
            createdAt: DateTime(2026, 8, 31, 7),
          ),
          CashMovementValue(
            type: 'incoming',
            amount: 40000,
            category: 'Acompte commande',
            createdAt: DateTime(2026, 8, 31, 11),
          ),
          CashMovementValue(
            type: 'withdrawal',
            amount: 40000,
            category: 'Remboursement commande',
            createdAt: DateTime(2026, 8, 31, 16),
          ),
        ],
      );

      expect(
        totals.calculatedCash,
        32000,
        reason: '20 000 + 12 000 + 40 000 − 40 000',
      );
      expect(
        totals.netProfit,
        3000,
        reason: 'seule la vente compte : l\'acompte entre et ressort intact',
      );
    });
  });
}
