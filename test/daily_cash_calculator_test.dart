import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/daily_cash_calculator.dart';

void main() {
  group('DailyCashCalculator', () {
    test('utilise uniquement le dernier solde du matin', () {
      final totals = DailyCashCalculator.calculate(
        sales: const [SaleValue(amount: 10000, profit: 3000)],
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
        sales: const [
          SaleValue(amount: 5000, profit: 1200),
          SaleValue(amount: 3000, profit: 800),
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
  });
}
