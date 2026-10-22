import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/family/auren_family_wallet_insights.dart';

void main() {
  const insights = AurenFamilyWalletInsights();

  group('monthlyCashFlowByCurrency', () {
    test('totals current-month income and expenses per currency', () {
      final result = insights.monthlyCashFlowByCurrency([
        {'kind': 'income', 'amountMinor': 10000, 'currency': 'usd', 'createdAt': DateTime(2026, 10, 1)},
        {'kind': 'expense', 'amountMinor': 2500, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 2)},
        {'kind': 'expense', 'amountMinor': 100, 'currency': 'SDG', 'createdAt': DateTime(2026, 10, 3)},
        {'kind': 'expense', 'amountMinor': 900, 'currency': 'USD', 'createdAt': DateTime(2026, 9, 30)},
        {'kind': 'expense', 'amountMinor': 800, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 3), 'amount': 'bad'},
      ], now: DateTime(2026, 10, 15));

      expect(result['USD'], {'incomeMinor': 10000, 'expenseMinor': 2500, 'netMinor': 7500});
      expect(result['SDG'], {'incomeMinor': 0, 'expenseMinor': 100, 'netMinor': -100});
    });

    test('ignores invalid amounts, unsupported kinds and currencies', () {
      final result = insights.monthlyCashFlowByCurrency([
        {'kind': 'transfer', 'amountMinor': 100, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 1)},
        {'kind': 'expense', 'amountMinor': -1, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 1)},
        {'kind': 'income', 'amountMinor': 10, 'currency': 'US dollars', 'createdAt': DateTime(2026, 10, 1)},
      ], now: DateTime(2026, 10, 15));
      expect(result, isEmpty);
    });
  });

  group('largestExpenseLabels', () {
    test('groups normalized labels per currency and orders by total', () {
      final result = insights.largestExpenseLabels([
        {'kind': 'expense', 'title': ' Groceries ', 'amountMinor': 100, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 1)},
        {'kind': 'expense', 'title': 'groceries', 'amountMinor': 300, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 2)},
        {'kind': 'expense', 'title': 'Rent', 'amountMinor': 250, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 3)},
        {'kind': 'income', 'title': 'Salary', 'amountMinor': 5000, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 3)},
      ], now: DateTime(2026, 10, 15));

      expect(result.first['title'], 'Groceries');
      expect(result.first['totalMinor'], 400);
      expect(result.first['occurrences'], 2);
    });

    test('rejects out-of-range result limits', () {
      expect(() => insights.largestExpenseLabels([], limit: 0), throwsArgumentError);
    });
  });
}
