import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ledgerStorageKey = 'nova.wallet.ledger.v1';
const _ledgerAccent = Color(0xFF9B87FF);

class NovaWalletLedgerScreen extends StatefulWidget {
  const NovaWalletLedgerScreen({super.key});

  @override
  State<NovaWalletLedgerScreen> createState() => _NovaWalletLedgerScreenState();
}

class _NovaWalletLedgerScreenState extends State<NovaWalletLedgerScreen> {
  static const _wallets = <String, String>{
    'bravo': 'Bravo',
    'mycashi': 'MyCashi',
    'trust_wallet': 'Trust Wallet',
    'paypal': 'PayPal',
  };

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _wallet = 'bravo';
  String _type = 'income';
  String _currency = 'SDG';
  bool _loading = true;
  List<_LedgerEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _defaultCurrency(String wallet) => switch (wallet) {
        'bravo' || 'mycashi' => 'SDG',
        'paypal' => 'USD',
        _ => 'USDT',
      };

  void _onWalletChanged(String? value) {
    if (value == null) return;
    setState(() {
      _wallet = value;
      _currency = _defaultCurrency(value);
    });
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_ledgerStorageKey) ?? <String>[];
      final parsed = <_LedgerEntry>[];
      for (final item in raw) {
        try {
          parsed.add(_LedgerEntry.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ));
        } catch (_) {
          // Ignore malformed legacy entries rather than breaking the screen.
        }
      }
      if (!mounted) return;
      setState(() {
        _entries = parsed..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _persistEntries(List<_LedgerEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = entries.map((e) => jsonEncode(e.toJson())).toList();
      return await prefs.setStringList(_ledgerStorageKey, values);
    } catch (_) {
      return false;
    }
  }

  Future<void> _addEntry() async {
    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(rawAmount);
    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً أكبر من صفر.')),
      );
      return;
    }
    final note = _noteController.text.trim();
    final entry = _LedgerEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      walletId: _wallet,
      type: _type,
      amount: amount,
      currency: _currency,
      note: note,
      createdAt: DateTime.now(),
    );
    final next = [entry, ..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final saved = await _persistEntries(next);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ العملية محلياً. لم تُضف للسجل.')),
      );
      return;
    }
    setState(() {
      _entries = next;
      _amountController.clear();
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سُجلت العملية محلياً فقط؛ لم يحدث تحويل مالي.')),
    );
  }

  Future<void> _deleteEntry(_LedgerEntry entry) async {
    final next = _entries.where((e) => e.id != entry.id).toList();
    final saved = await _persistEntries(next);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث السجل المحلي.')),
      );
      return;
    }
    setState(() => _entries = next);
  }

  String _money(double value) =>
      value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 2);

  Map<String, double> _totalsFor(String wallet, String type) {
    final totals = <String, double>{};
    for (final entry in _entries.where(
      (e) => e.walletId == wallet && e.type == type,
    )) {
      totals.update(entry.currency, (value) => value + entry.amount,
          ifAbsent: () => entry.amount);
    }
    return totals;
  }

  Widget _summaryCard(String title, String type, IconData icon) {
    final totals = _totalsFor(_wallet, type);
    final text = totals.isEmpty
        ? 'لا توجد عمليات'
        : totals.entries.map((e) => '${_money(e.value)} ${e.key}').join(' • ');
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _ledgerAccent),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 5),
              Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries =
        _entries.where((entry) => entry.walletId == _wallet).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('دفتر الدخل والمصروفات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'سجل شخصي محلي للمحافظ الأربع. هذه القيود لا تقرأ أرصدة الحسابات ولا تنفذ حوالات، ولا تُرسل إلى خادم. اختر العملة الصحيحة لكل عملية ولا تجمع عملات مختلفة في رقم واحد.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _wallet,
                  decoration: const InputDecoration(
                    labelText: 'المحفظة',
                    border: OutlineInputBorder(),
                  ),
                  items: _wallets.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _onWalletChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('دخل'),
                        value: 'income',
                        groupValue: _type,
                        onChanged: (v) => setState(() => _type = v ?? 'income'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('مصروف'),
                        value: 'expense',
                        groupValue: _type,
                        onChanged: (v) => setState(() => _type = v ?? 'expense'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'العملة',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['SDG', 'USD', 'USDT', 'EUR', 'SAR']
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة أو مرجع إيصال (اختياري)',
                    hintText: 'مثال: دخل من خدمة تصميم',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل العملية'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _summaryCard('إجمالي الدخل', 'income', Icons.south_west),
                    _summaryCard('إجمالي المصروف', 'expense', Icons.north_east),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'سجل ${_wallets[_wallet]}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (visibleEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('لا توجد عمليات مسجلة لهذه المحفظة بعد.')),
                  ),
                for (final entry in visibleEntries)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: entry.type == 'income'
                            ? const Color(0xFF1D4937)
                            : const Color(0xFF4A2C35),
                        child: Icon(
                          entry.type == 'income'
                              ? Icons.south_west
                              : Icons.north_east,
                        ),
                      ),
                      title: Text(
                        '${entry.type == 'income' ? 'دخل' : 'مصروف'} • ${_money(entry.amount)} ${entry.currency}',
                      ),
                      subtitle: Text(
                        '${entry.note.isEmpty ? 'بدون ملاحظة' : entry.note}\n${entry.createdAt.toLocal().toString().substring(0, 16)}',
                        textDirection: TextDirection.rtl,
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'حذف القيد',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(entry),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LedgerEntry {
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String currency;
  final String note;
  final DateTime createdAt;

  const _LedgerEntry({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _LedgerEntry.fromJson(Map<String, dynamic> json) => _LedgerEntry(
        id: json['id'] as String,
        walletId: json['walletId'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
