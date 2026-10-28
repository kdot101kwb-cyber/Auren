import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'nova_finance_models.dart';

abstract interface class NovaFinanceRepository {
  Future<List<NovaFinanceTransaction>> loadTransactions();
  Future<bool> saveTransactions(List<NovaFinanceTransaction> transactions);
  Future<String> exportJson();
}

/// Device-local implementation; later repositories can implement this interface.
class SharedPreferencesNovaFinanceRepository implements NovaFinanceRepository {
  static const storageKey = 'nova.finance.transactions.v2';
  static const legacyStorageKey = 'nova.wallet.ledger.v1';

  @override
  Future<List<NovaFinanceTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(storageKey);
    final raw = current ?? prefs.getStringList(legacyStorageKey) ?? const <String>[];
    final transactions = <NovaFinanceTransaction>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final transaction = NovaFinanceTransaction.fromJson(decoded);
        if (NovaFinanceRegistry.provider(transaction.walletId) != null && transaction.amount > 0) {
          transactions.add(transaction);
        }
      } catch (_) {
        // Skip malformed records without breaking other valid entries.
      }
    }
    if (current == null && transactions.isNotEmpty) {
      await saveTransactions(transactions);
    }
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return transactions;
  }

  @override
  Future<bool> saveTransactions(List<NovaFinanceTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = transactions.map((item) => jsonEncode(item.toJson())).toList();
    return prefs.setStringList(storageKey, encoded);
  }

  @override
  Future<String> exportJson() async {
    final entries = await loadTransactions();
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': NovaFinanceTransaction.currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'verifiedProviderData': false,
      'transactions': entries.map((entry) => entry.toJson()).toList(),
    });
  }
}
