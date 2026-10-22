/// Lightweight, offline-friendly financial insights for the AUREN wallet.
///
/// This layer analyses transaction records already available to the user. It
/// never initiates payments, moves money, or contacts a financial provider.
class AurenMoneyInsights {
  const AurenMoneyInsights();

  /// Summarizes outgoing transactions for the current calendar month.
  Map<String, int> monthlySpendByCurrency(
    Iterable<Map<String, dynamic>> transactions, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final totals = <String, int>{};
    for (final transaction in transactions) {
      if (!_isOutgoing(transaction)) continue;
      final date = _dateOf(transaction['createdAt']);
      if (date == null ||
          date.year != current.year ||
          date.month != current.month) {
        continue;
      }
      final amount = transaction['amountMinor'];
      if (amount is! int || amount <= 0) continue;
      final currency = _currencyOf(transaction['currency']);
      if (currency == null) continue;
      totals[currency] = (totals[currency] ?? 0) + amount;
    }
    return Map.unmodifiable(totals);
  }

  /// Finds repeated expense labels as candidates, not confirmed subscriptions.
  List<Map<String, dynamic>> recurringExpenseCandidates(
    Iterable<Map<String, dynamic>> transactions, {
    int minimumOccurrences = 3,
  }) {
    if (minimumOccurrences < 2 || minimumOccurrences > 24) {
      throw ArgumentError.value(
        minimumOccurrences,
        'minimumOccurrences',
        'Must be between 2 and 24.',
      );
    }
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final transaction in transactions) {
      if (!_isOutgoing(transaction)) continue;
      final rawLabel = transaction['merchant'] ??
          transaction['title'] ??
          transaction['description'];
      if (rawLabel is! String || rawLabel.trim().isEmpty) continue;
      final label = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
      final currency = _currencyOf(transaction['currency']);
      final amount = transaction['amountMinor'];
      final date = _dateOf(transaction['createdAt']);
      if (currency == null || amount is! int || amount <= 0 || date == null) {
        continue;
      }
      final key = '${label.toLowerCase()}|$currency';
      groups.putIfAbsent(key, () => []).add({
        'label': label,
        'currency': currency,
        'amountMinor': amount,
        'date': date,
      });
    }
    final candidates = <Map<String, dynamic>>[];
    for (final records in groups.values) {
      if (records.length < minimumOccurrences) continue;
      records.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );
      final amounts = records.map((r) => r['amountMinor'] as int).toList();
      final sortedAmounts = [...amounts]..sort();
      candidates.add({
        'label': records.first['label'],
        'currency': records.first['currency'],
        'occurrences': records.length,
        'averageAmountMinor':
            amounts.reduce((a, b) => a + b) ~/ amounts.length,
        'medianAmountMinor': sortedAmounts[sortedAmounts.length ~/ 2],
        'confidence': 'possible',
      });
    }
    candidates.sort(
      (a, b) => (b['occurrences'] as int).compareTo(a['occurrences'] as int),
    );
    return List.unmodifiable(candidates);
  }

  /// Groups current-month outgoing spend by currency and user-entered category.
  /// Missing categories remain visible as "غير مصنّف" instead of being dropped.
  Map<String, Map<String, int>> monthlySpendByCategory(
    Iterable<Map<String, dynamic>> transactions, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final totals = <String, Map<String, int>>{};
    for (final transaction in transactions) {
      if (!_isOutgoing(transaction)) continue;
      final date = _dateOf(transaction['createdAt']);
      if (date == null ||
          date.year != current.year ||
          date.month != current.month) {
        continue;
      }
      final amount = transaction['amountMinor'];
      if (amount is! int || amount <= 0) continue;
      final currency = _currencyOf(transaction['currency']);
      if (currency == null) continue;
      final rawCategory = transaction['category'];
      final normalizedCategory = rawCategory is String
          ? rawCategory.trim().replaceAll(RegExp(r'\s+'), ' ')
          : '';
      final category = normalizedCategory.isEmpty
          ? 'غير مصنّف'
          : normalizedCategory.length > 60
              ? normalizedCategory.substring(0, 60)
              : normalizedCategory;
      final byCategory = totals.putIfAbsent(currency, () => <String, int>{});
      byCategory[category] = (byCategory[category] ?? 0) + amount;
    }
    return Map.unmodifiable({
      for (final entry in totals.entries)
        entry.key: Map<String, int>.unmodifiable(entry.value),
    });
  }

  /// Compares current and previous calendar-month outgoing spend by currency.
  /// Values are minor units; no exchange-rate conversion is attempted.
  Map<String, Map<String, int>> monthlySpendTrendByCurrency(
    Iterable<Map<String, dynamic>> transactions, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final previousMonth = DateTime(current.year, current.month - 1, 1);
    final totals = <String, Map<String, int>>{};
    for (final transaction in transactions) {
      if (!_isOutgoing(transaction)) continue;
      final date = _dateOf(transaction['createdAt']);
      if (date == null) continue;
      final isCurrent =
          date.year == current.year && date.month == current.month;
      final isPrevious = date.year == previousMonth.year &&
          date.month == previousMonth.month;
      if (!isCurrent && !isPrevious) continue;
      final amount = transaction['amountMinor'];
      if (amount is! int || amount <= 0) continue;
      final currency = _currencyOf(transaction['currency']);
      if (currency == null) continue;
      final entry = totals.putIfAbsent(
        currency,
        () => {'currentMinor': 0, 'previousMinor': 0},
      );
      final key = isCurrent ? 'currentMinor' : 'previousMinor';
      entry[key] = entry[key]! + amount;
    }
    return Map.unmodifiable({
      for (final entry in totals.entries)
        entry.key: Map<String, int>.unmodifiable({
          ...entry.value,
          'deltaMinor':
              entry.value['currentMinor']! - entry.value['previousMinor']!,
        }),
    });
  }

  bool _isOutgoing(Map<String, dynamic> transaction) {
    final direction = transaction['direction']?.toString().toLowerCase();
    if (const {'expense', 'outgoing', 'debit'}.contains(direction)) return true;
    if (const {'income', 'incoming', 'credit'}.contains(direction)) return false;
    final type = transaction['type']?.toString().toLowerCase() ?? '';
    return const {'expense', 'debit', 'payment', 'purchase', 'withdrawal'}
        .contains(type);
  }

  String? _currencyOf(dynamic rawValue) {
    final currency = (rawValue ?? '').toString().trim().toUpperCase();
    return RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : null;
  }

  DateTime? _dateOf(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Supports Firestore Timestamp without coupling this pure helper to Firebase.
    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Unsupported or missing date.
    }
    return null;
  }
}
