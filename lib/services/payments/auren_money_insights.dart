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
      final currency = (transaction['currency'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) continue;
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
      throw ArgumentError.value(minimumOccurrences, 'minimumOccurrences',
          'Must be between 2 and 24.');
    }
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final transaction in transactions) {
      if (!_isOutgoing(transaction)) continue;
      final rawLabel = transaction['merchant'] ??
          transaction['title'] ??
          transaction['description'];
      if (rawLabel is! String || rawLabel.trim().isEmpty) continue;
      final label = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
      final currency =
          (transaction['currency'] ?? '').toString().trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) continue;
      final amount = transaction['amountMinor'];
      final date = _dateOf(transaction['createdAt']);
      if (amount is! int || amount <= 0 || date == null) continue;
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
      records.sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      final amounts = records.map((r) => r['amountMinor'] as int).toList();
      final sortedAmounts = [...amounts]..sort();
      candidates.add({
        'label': records.first['label'],
        'currency': records.first['currency'],
        'occurrences': records.length,
        'averageAmountMinor': amounts.reduce((a, b) => a + b) ~/ amounts.length,
        'medianAmountMinor': sortedAmounts[sortedAmounts.length ~/ 2],
        'confidence': 'possible',
      });
    }
    candidates.sort((a, b) =>
        (b['occurrences'] as int).compareTo(a['occurrences'] as int));
    return List.unmodifiable(candidates);
  }

  bool _isOutgoing(Map<String, dynamic> transaction) {
    final direction = transaction['direction']?.toString().toLowerCase();
    if (const {'expense', 'outgoing', 'debit'}.contains(direction)) return true;
    if (const {'income', 'incoming', 'credit'}.contains(direction)) return false;
    final type = transaction['type']?.toString().toLowerCase() ?? '';
    return const {'expense', 'debit', 'payment', 'purchase', 'withdrawal'}
        .contains(type);
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
