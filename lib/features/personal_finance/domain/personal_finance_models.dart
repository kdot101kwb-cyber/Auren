enum FinanceEntryType { income, expense }

/// A user-entered income or expense. This model does not move money or connect
/// to a bank; amounts are recorded assumptions supplied by the user.
class FinanceEntry {
  FinanceEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    required this.occurredAt,
    this.note,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be finite and greater than zero.');
    }
    if (!_isCurrencyCode(currency)) {
      throw ArgumentError.value(currency, 'currency', 'Must be a three-letter currency code.');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError.value(category, 'category', 'Must not be empty.');
    }
    if (note != null && note!.length > 500) {
      throw ArgumentError.value(note, 'note', 'Must be at most 500 characters.');
    }
  }

  final String id;
  final FinanceEntryType type;
  final double amount;
  final String currency;
  final String category;
  final DateTime occurredAt;
  final String? note;

  static bool _isCurrencyCode(String value) =>
      RegExp(r'^[A-Za-z]{3}$').hasMatch(value);
}

/// A spending limit for one currency. It is advisory and never blocks a
/// payment or authorizes a transfer.
class FinanceBudget {
  FinanceBudget({
    required this.month,
    required this.limit,
    required this.currency,
  }) {
    if (!limit.isFinite || limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be finite and greater than zero.');
    }
    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currency)) {
      throw ArgumentError.value(currency, 'currency', 'Must be a three-letter currency code.');
    }
  }

  /// Any date within the budget month; comparisons use year and month only.
  final DateTime month;
  final double limit;
  final String currency;
}

class PersonalFinanceSummary {
  const PersonalFinanceSummary({
    required this.currency,
    required this.income,
    required this.expenses,
    required this.net,
    required this.budgetLimit,
    required this.budgetRemaining,
    required this.expensesInBudgetMonth,
  });

  final String currency;
  final double income;
  final double expenses;
  final double net;
  final double budgetLimit;

  /// May be negative when spending exceeds the budget.
  final double budgetRemaining;
  final double expensesInBudgetMonth;

  bool get isOverBudget => budgetRemaining < 0;

  factory PersonalFinanceSummary.calculate({
    required Iterable<FinanceEntry> entries,
    required FinanceBudget budget,
  }) {
    final normalizedCurrency = budget.currency.toUpperCase();
    var income = 0.0;
    var expenses = 0.0;
    var monthlyExpenses = 0.0;

    for (final entry in entries) {
      if (entry.currency.toUpperCase() != normalizedCurrency) {
        throw ArgumentError(
          'Cannot combine ${entry.currency} entries with $normalizedCurrency budget.',
        );
      }

      if (entry.type == FinanceEntryType.income) {
        income += entry.amount;
      } else {
        expenses += entry.amount;
        if (entry.occurredAt.year == budget.month.year &&
            entry.occurredAt.month == budget.month.month) {
          monthlyExpenses += entry.amount;
        }
      }

      if (!income.isFinite || !expenses.isFinite || !monthlyExpenses.isFinite) {
        throw ArgumentError('Finance totals exceed the supported numeric range.');
      }
    }

    return PersonalFinanceSummary(
      currency: normalizedCurrency,
      income: income,
      expenses: expenses,
      net: income - expenses,
      budgetLimit: budget.limit,
      budgetRemaining: budget.limit - monthlyExpenses,
      expensesInBudgetMonth: monthlyExpenses,
    );
  }
}
