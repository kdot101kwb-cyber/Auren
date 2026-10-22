import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/payments/auren_money_insights.dart';

void main() {
  const insights = AurenMoneyInsights();

  group('monthlySpendByCurrency', () {
    test('totals current-month outgoing records by currency only', () {
      final result = insights.monthlySpendByCurrency([
        {'type': 'expense', 'amountMinor': 250, 'currency': 'sdg',
          'createdAt': DateTime(2026, 10, 2)},
        {'direction': 'debit', 'amountMinor': 100, 'currency': 'SDG',
          'createdAt': DateTime(2026, 10, 3)},
        {'type': 'income', 'amountMinor': 900, 'currency': 'SDG',
          'createdAt': DateTime(2026, 10, 4)},
        {'type': 'expense', 'amountMinor': 700, 'currency': 'USD',
          'createdAt': DateTime(2026, 9, 30)},
      ], now: DateTime(2026, 10, 15));

      expect(result, {'SDG': 350});
    });

    test('ignores invalid amount, currency and date', () {
      final result = insights.monthlySpendByCurrency([
        {'type': 'expense', 'amountMinor': -1, 'currency': 'USD',
          'createdAt': DateTime(2026, 10, 2)},
        {'type': 'expense', 'amountMinor': 50, 'currency': 'US',
          'createdAt': DateTime(2026, 10, 2)},
        {'type': 'expense', 'amountMinor': 50, 'currency': 'USD',
          'createdAt': 'not-a-date'},
      ], now: DateTime(2026, 10, 15));

      expect(result, isEmpty);
    });
  });


  group('monthlySpendByCategory', () {
    test('groups current-month expenses by category without mixing currencies', () {
      final result = insights.monthlySpendByCategory([
        {'type': 'expense', 'amountMinor': 200, 'currency': 'SDG', 'category': 'Food', 'createdAt': DateTime(2026, 10, 2)},
        {'type': 'debit', 'amountMinor': 300, 'currency': 'SDG', 'category': 'Food', 'createdAt': DateTime(2026, 10, 3)},
        {'type': 'expense', 'amountMinor': 150, 'currency': 'USD', 'category': 'Food', 'createdAt': DateTime(2026, 10, 4)},
        {'type': 'expense', 'amountMinor': 500, 'currency': 'SDG', 'createdAt': DateTime(2026, 10, 5)},
        {'type': 'income', 'amountMinor': 900, 'currency': 'SDG', 'category': 'Salary', 'createdAt': DateTime(2026, 10, 4)},
      ], now: DateTime(2026, 10, 15));
      expect(result['SDG'], {'Food': 500, 'غير مصنّف': 500});
      expect(result['USD'], {'Food': 150});
    });

    test('normalizes category whitespace and bounds long labels', () {
      final result = insights.monthlySpendByCategory([
        {'type': 'expense', 'amountMinor': 10, 'currency': 'USD', 'category': '  Home   bills  ', 'createdAt': DateTime(2026, 10, 1)},
      ], now: DateTime(2026, 10, 15));
      expect(result['USD'], {'Home bills': 10});
    });
  });

  group('monthlySpendTrendByCurrency', () {
    test('compares current and previous month without FX conversion', () {
      final result = insights.monthlySpendTrendByCurrency([
        {'type': 'expense', 'amountMinor': 200, 'currency': 'USD', 'createdAt': DateTime(2026, 9, 3)},
        {'type': 'payment', 'amountMinor': 450, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 3)},
        {'type': 'income', 'amountMinor': 900, 'currency': 'USD', 'createdAt': DateTime(2026, 10, 4)},
        {'type': 'expense', 'amountMinor': 100, 'currency': 'SDG', 'createdAt': DateTime(2026, 10, 4)},
      ], now: DateTime(2026, 10, 15));
      expect(result['USD'], {'currentMinor': 450, 'previousMinor': 200, 'deltaMinor': 250});
      expect(result['SDG'], {'currentMinor': 100, 'previousMinor': 0, 'deltaMinor': 100});
    });

    test('handles January by comparing against December of the prior year', () {
      final result = insights.monthlySpendTrendByCurrency([
        {'type': 'expense', 'amountMinor': 70, 'currency': 'USD', 'createdAt': DateTime(2025, 12, 12)},
        {'type': 'expense', 'amountMinor': 30, 'currency': 'USD', 'createdAt': DateTime(2026, 1, 2)},
      ], now: DateTime(2026, 1, 15));
      expect(result['USD'], {'currentMinor': 30, 'previousMinor': 70, 'deltaMinor': -40});
    });
  });

  group('recurringExpenseCandidates', () {
    test('detects repeated normalized labels as possible recurring expenses', () {
      final result = insights.recurringExpenseCandidates([
        {'type': 'payment', 'title': ' Internet Bill ', 'amountMinor': 100,
          'currency': 'USD', 'createdAt': DateTime(2026, 8, 1)},
        {'type': 'payment', 'title': 'internet bill', 'amountMinor': 120,
          'currency': 'USD', 'createdAt': DateTime(2026, 9, 1)},
        {'type': 'payment', 'title': 'INTERNET BILL', 'amountMinor': 110,
          'currency': 'USD', 'createdAt': DateTime(2026, 10, 1)},
      ]);

      expect(result, hasLength(1));
      expect(result.single['label'], 'Internet Bill');
      expect(result.single['occurrences'], 3);
      expect(result.single['confidence'], 'possible');
      expect(result.single['averageAmountMinor'], 110);
    });

    test('does not label a single transaction as recurring', () {
      final result = insights.recurringExpenseCandidates([
        {'type': 'expense', 'title': 'Groceries', 'amountMinor': 200,
          'currency': 'SDG', 'createdAt': DateTime(2026, 10, 1)},
      ]);
      expect(result, isEmpty);
    });

    test('rejects unreasonable occurrence thresholds', () {
      expect(
        () => insights.recurringExpenseCandidates([], minimumOccurrences: 1),
        throwsArgumentError,
      );
    });
  });
}
