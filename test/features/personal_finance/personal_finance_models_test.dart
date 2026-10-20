import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/personal_finance/domain/personal_finance_models.dart';

void main() {
  FinanceEntry entry({
    String id = 'entry-1',
    FinanceEntryType type = FinanceEntryType.expense,
    double amount = 10,
    String currency = 'SDG',
    String category = 'food',
    DateTime? occurredAt,
    String? note,
  }) =>
      FinanceEntry(
        id: id,
        type: type,
        amount: amount,
        currency: currency,
        category: category,
        occurredAt: occurredAt ?? DateTime(2026, 10, 12),
        note: note,
      );

  FinanceBudget budget({
    DateTime? month,
    double limit = 100,
    String currency = 'SDG',
  }) =>
      FinanceBudget(
        month: month ?? DateTime(2026, 10, 1),
        limit: limit,
        currency: currency,
      );

  group('FinanceEntry validation', () {
    test('rejects empty identifiers and categories', () {
      expect(
        () => entry(id: ' '),
        throwsArgumentError,
      );
      expect(
        () => entry(category: ''),
        throwsArgumentError,
      );
    });

    test('rejects non-positive and non-finite amounts', () {
      for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => entry(amount: amount),
          throwsArgumentError,
          reason: 'amount=$amount',
        );
      }
    });

    test('accepts currency codes without case sensitivity', () {
      expect(entry(currency: 'usd').currency, 'usd');
      expect(() => entry(currency: 'US'), throwsArgumentError);
      expect(() => entry(currency: 'US1'), throwsArgumentError);
    });

    test('bounds optional notes', () {
      expect(() => entry(note: 'x' * 501), throwsArgumentError);
      expect(entry(note: 'x' * 500).note, hasLength(500));
    });
  });

  group('FinanceBudget validation', () {
    test('requires a positive finite limit and currency code', () {
      expect(() => budget(limit: 0), throwsArgumentError);
      expect(() => budget(limit: -1), throwsArgumentError);
      expect(() => budget(limit: double.infinity), throwsArgumentError);
      expect(() => budget(currency: 'US'), throwsArgumentError);
    });
  });

  group('PersonalFinanceSummary.calculate', () {
    test('summarizes income, all expenses, and current-month budget', () {
      final summary = PersonalFinanceSummary.calculate(
        budget: budget(limit: 100),
        entries: [
          entry(id: 'income', type: FinanceEntryType.income, amount: 500),
          entry(id: 'food', amount: 35),
          entry(id: 'transport', amount: 15),
          entry(
            id: 'old-expense',
            amount: 90,
            occurredAt: DateTime(2026, 9, 30),
          ),
        ],
      );

      expect(summary.currency, 'SDG');
      expect(summary.income, 500);
      expect(summary.expenses, 140);
      expect(summary.net, 360);
      expect(summary.expensesInBudgetMonth, 50);
      expect(summary.budgetRemaining, 50);
      expect(summary.isOverBudget, isFalse);
    });

    test('marks a budget exceeded only when current-month expenses go over', () {
      final summary = PersonalFinanceSummary.calculate(
        budget: budget(limit: 20),
        entries: [entry(amount: 20), entry(id: 'extra', amount: 0.01)],
      );

      expect(summary.budgetRemaining, closeTo(-0.01, 0.000001));
      expect(summary.isOverBudget, isTrue);
    });

    test('accepts equivalent currency casing but rejects mixed currencies', () {
      final summary = PersonalFinanceSummary.calculate(
        budget: budget(currency: 'usd'),
        entries: [entry(currency: 'USD', amount: 5)],
      );
      expect(summary.currency, 'USD');

      expect(
        () => PersonalFinanceSummary.calculate(
          budget: budget(currency: 'USD'),
          entries: [entry(currency: 'EUR')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects totals that overflow the finite numeric range', () {
      expect(
        () => PersonalFinanceSummary.calculate(
          budget: budget(limit: 100),
          entries: [
            entry(id: 'a', amount: double.maxFinite),
            entry(id: 'b', amount: double.maxFinite),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('empty history produces zero totals and full remaining budget', () {
      final summary = PersonalFinanceSummary.calculate(
        budget: budget(limit: 75),
        entries: const [],
      );

      expect(summary.income, 0);
      expect(summary.expenses, 0);
      expect(summary.net, 0);
      expect(summary.expensesInBudgetMonth, 0);
      expect(summary.budgetRemaining, 75);
      expect(summary.isOverBudget, isFalse);
    });
  });
}
