import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/personal_finance_models.dart';

/// Persisted snapshot of the user's personal finance data.
class PersonalFinanceSnapshot {
  const PersonalFinanceSnapshot({
    required this.entries,
    required this.currency,
    required this.budgetLimit,
  });

  final List<FinanceEntry> entries;
  final String currency;
  final double budgetLimit;

  Map<String, Object?> toJson() => {
        'version': 1,
        'currency': currency,
        'budgetLimit': budgetLimit,
        'entries': entries
            .map((entry) => {
                  'id': entry.id,
                  'type': entry.type.name,
                  'amount': entry.amount,
                  'currency': entry.currency,
                  'category': entry.category,
                  'occurredAt': entry.occurredAt.toIso8601String(),
                  'note': entry.note,
                })
            .toList(growable: false),
      };

  factory PersonalFinanceSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported personal finance data version.');
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('Invalid personal finance entries.');
    }
    final currency = json['currency'];
    final budgetLimit = json['budgetLimit'];
    if (currency is! String || budgetLimit is! num) {
      throw const FormatException('Invalid personal finance settings.');
    }

    final entries = rawEntries.map((raw) {
      if (raw is! Map) {
        throw const FormatException('Invalid personal finance entry.');
      }
      final map = Map<String, dynamic>.from(raw);
      final typeName = map['type'];
      final type = FinanceEntryType.values.where((value) => value.name == typeName);
      if (type.isEmpty ||
          map['id'] is! String ||
          map['amount'] is! num ||
          map['currency'] is! String ||
          map['category'] is! String ||
          map['occurredAt'] is! String ||
          (map['note'] != null && map['note'] is! String)) {
        throw const FormatException('Invalid personal finance entry fields.');
      }
      return FinanceEntry(
        id: map['id'] as String,
        type: type.first,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        category: map['category'] as String,
        occurredAt: DateTime.parse(map['occurredAt'] as String),
        note: map['note'] as String?,
      );
    }).toList(growable: false);

    // Reuse domain validation before accepting persisted settings or entries.
    FinanceBudget(month: DateTime.now(), limit: budgetLimit.toDouble(), currency: currency);
    PersonalFinanceSummary.calculate(
      entries: entries,
      budget: FinanceBudget(month: DateTime.now(), limit: budgetLimit.toDouble(), currency: currency),
    );
    return PersonalFinanceSnapshot(
      entries: List.unmodifiable(entries),
      currency: currency.toUpperCase(),
      budgetLimit: budgetLimit.toDouble(),
    );
  }
}

abstract interface class PersonalFinanceStore {
  Future<PersonalFinanceSnapshot?> load();
  Future<void> save(PersonalFinanceSnapshot snapshot);
}

/// Device-local encrypted storage. No bank connection, sync, or money transfer.
class SecurePersonalFinanceStore implements PersonalFinanceStore {
  SecurePersonalFinanceStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auren.personal_finance.snapshot.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<PersonalFinanceSnapshot?> load() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved personal finance data.');
    }
    return PersonalFinanceSnapshot.fromJson(decoded);
  }

  @override
  Future<void> save(PersonalFinanceSnapshot snapshot) async {
    await _storage.write(key: _key, value: jsonEncode(snapshot.toJson()));
  }
}
