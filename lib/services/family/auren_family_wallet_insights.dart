/// Local analysis of manually recorded family-wallet entries only.
/// This service never moves money or claims to see unrecorded accounts.
class AurenFamilyWalletInsights {
  const AurenFamilyWalletInsights();

  Map<String, Map<String, int>> monthlyCashFlowByCurrency(
    Iterable<Map<String, dynamic>> entries, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final totals = <String, Map<String, int>>{};
    for (final entry in entries) {
      final date = _dateOf(entry['createdAt']);
      if (date == null || date.year != current.year || date.month != current.month) continue;
      final kind = entry['kind']?.toString().toLowerCase();
      if (kind != 'income' && kind != 'expense') continue;
      final amount = entry['amountMinor'];
      if (amount is! int || amount <= 0) continue;
      final currency = (entry['currency'] ?? '').toString().trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) continue;
      final row = totals.putIfAbsent(currency, () => {'incomeMinor': 0, 'expenseMinor': 0});
      final key = kind == 'income' ? 'incomeMinor' : 'expenseMinor';
      row[key] = row[key]! + amount;
    }
    return Map.unmodifiable({
      for (final entry in totals.entries)
        entry.key: Map<String, int>.unmodifiable({
          ...entry.value,
          'netMinor': entry.value['incomeMinor']! - entry.value['expenseMinor']!,
        }),
    });
  }

  List<Map<String, dynamic>> largestExpenseLabels(
    Iterable<Map<String, dynamic>> entries, {
    int limit = 5,
    DateTime? now,
  }) {
    if (limit < 1 || limit > 20) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 20.');
    }
    final current = now ?? DateTime.now();
    final groups = <String, Map<String, dynamic>>{};
    for (final entry in entries) {
      if (entry['kind']?.toString().toLowerCase() != 'expense') continue;
      final date = _dateOf(entry['createdAt']);
      if (date == null || date.year != current.year || date.month != current.month) continue;
      final amount = entry['amountMinor'];
      if (amount is! int || amount <= 0) continue;
      final currency = (entry['currency'] ?? '').toString().trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) continue;
      final rawTitle = entry['title'];
      if (rawTitle is! String || rawTitle.trim().isEmpty) continue;
      final title = rawTitle.trim().replaceAll(RegExp(r'\s+'), ' ');
      final key = '${title.toLowerCase()}|$currency';
      final group = groups.putIfAbsent(key, () => {
        'title': title.length > 80 ? title.substring(0, 80) : title,
        'currency': currency,
        'occurrences': 0,
        'totalMinor': 0,
      });
      group['occurrences'] = (group['occurrences'] as int) + 1;
      group['totalMinor'] = (group['totalMinor'] as int) + amount;
    }
    final result = groups.values.toList()
      ..sort((a, b) => (b['totalMinor'] as int).compareTo(a['totalMinor'] as int));
    return List.unmodifiable(result.take(limit).map(Map<String, dynamic>.unmodifiable));
  }

  DateTime? _dateOf(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Unknown timestamp representations are excluded from the monthly summary.
    }
    return null;
  }
}
