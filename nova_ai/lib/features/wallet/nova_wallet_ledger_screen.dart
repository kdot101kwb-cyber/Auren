import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nova_finance_models.dart';
import 'nova_finance_repository.dart';

const _ledgerAccent = Color(0xFF9B87FF);

class NovaWalletLedgerScreen extends StatefulWidget {
  const NovaWalletLedgerScreen({super.key});

  @override
  State<NovaWalletLedgerScreen> createState() => _NovaWalletLedgerScreenState();
}

class _NovaWalletLedgerScreenState extends State<NovaWalletLedgerScreen> {
  final NovaFinanceRepository _repository = SharedPreferencesNovaFinanceRepository();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  final _counterpartyController = TextEditingController();

  String _wallet = NovaFinanceRegistry.providers.first.id;
  String _type = 'income';
  String _currency = NovaFinanceRegistry.providers.first.defaultCurrency;
  String _category = 'services';
  bool _loading = true;
  List<NovaFinanceTransaction> _entries = [];

  NovaFinanceProvider get _selectedProvider =>
      NovaFinanceRegistry.provider(_wallet)!;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    _counterpartyController.dispose();
    super.dispose();
  }

  void _onWalletChanged(String? value) {
    if (value == null) return;
    final provider = NovaFinanceRegistry.provider(value);
    if (provider == null) return;
    setState(() {
      _wallet = value;
      _currency = provider.defaultCurrency;
    });
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _repository.loadTransactions();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addEntry() async {
    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(rawAmount);
    if (amount == null || !amount.isFinite || amount <= 0 || amount > 1e12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً صالحاً أكبر من صفر.')),
      );
      return;
    }
    final now = DateTime.now();
    final entry = NovaFinanceTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      walletId: _wallet,
      type: _type,
      amount: amount,
      currency: _currency,
      categoryId: _category,
      note: _noteController.text.trim(),
      reference: _referenceController.text.trim(),
      counterparty: _counterpartyController.text.trim(),
      occurredAt: now,
      createdAt: now,
      status: 'recorded_by_user',
      providerVerified: false,
    );
    final next = [entry, ..._entries]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final saved = await _repository.saveTransactions(next);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ العملية على الجهاز.')),
      );
      return;
    }
    setState(() {
      _entries = next;
      _amountController.clear();
      _noteController.clear();
      _referenceController.clear();
      _counterpartyController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل العملية محلياً؛ لم يحدث تحويل مالي.')),
    );
  }

  Future<void> _deleteEntry(NovaFinanceTransaction entry) async {
    final next = _entries.where((e) => e.id != entry.id).toList();
    final saved = await _repository.saveTransactions(next);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث السجل المحلي.')),
      );
      return;
    }
    setState(() => _entries = next);
  }

  Future<void> _exportJson() async {
    try {
      final json = await _repository.exportJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نُسخت نسخة JSON احتياطية إلى الحافظة. احفظها في مكان آمن.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تجهيز النسخة الاحتياطية.')),
      );
    }
  }

  String _money(double value) =>
      value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 2);

  String _categoryName(String id) {
    for (final category in NovaFinanceRegistry.categories) {
      if (category.id == id) return category.name;
    }
    return 'أخرى';
  }

  Map<String, double> _totalsFor(String type, {bool currentMonthOnly = false}) {
    final now = DateTime.now();
    final totals = <String, double>{};
    for (final entry in _entries.where((e) =>
        e.walletId == _wallet &&
        e.type == type &&
        (!currentMonthOnly ||
            (e.occurredAt.year == now.year && e.occurredAt.month == now.month)))) {
      totals.update(entry.currency, (value) => value + entry.amount,
          ifAbsent: () => entry.amount);
    }
    return totals;
  }

  String _formatTotals(Map<String, double> totals) => totals.isEmpty
      ? '0'
      : totals.entries.map((e) => '${_money(e.value)} ${e.key}').join(' • ');

  Widget _summaryCard(String title, String type, IconData icon,
      {bool month = false}) {
    final totals = _totalsFor(type, currentMonthOnly: month);
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
              Text(_formatTotals(totals),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: const Text('دفتر الدخل والمصروفات'),
        actions: [
          IconButton(
            tooltip: 'نسخ نسخة احتياطية JSON',
            onPressed: _exportJson,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'النواة المالية قابلة للتوسع: مزوّدات وتصنيفات وحقول قابلة للإضافة. البيانات الحالية يدوية ومحلية؛ ليست أرصدة أو معاملات مؤكدة من مزوّد خدمة.',
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
                  items: NovaFinanceRegistry.providers
                      .map((provider) => DropdownMenuItem(
                            value: provider.id,
                            child: Text(provider.name),
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
                        onChanged: (v) => setState(() {
                          _type = v ?? 'income';
                          _category = _type == 'income' ? 'services' : 'other';
                        }),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('مصروف'),
                        value: 'expense',
                        groupValue: _type,
                        onChanged: (v) => setState(() {
                          _type = v ?? 'expense';
                          _category = _type == 'expense' ? 'food' : 'services';
                        }),
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
                  items: _selectedProvider.supportedCurrencies
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
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    border: OutlineInputBorder(),
                  ),
                  items: NovaFinanceRegistry.categories
                      .where((category) =>
                          category.appliesTo == 'both' ||
                          category.appliesTo == _type)
                      .map((category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _counterpartyController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'الجهة أو العميل (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _referenceController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'مرجع إيصال أو رقم عملية (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
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
                    _summaryCard('الدخل الكلي', 'income', Icons.south_west),
                    _summaryCard('المصروف الكلي', 'expense', Icons.north_east),
                  ],
                ),
                Row(
                  children: [
                    _summaryCard('دخل الشهر', 'income', Icons.calendar_month, month: true),
                    _summaryCard('مصروف الشهر', 'expense', Icons.event_busy, month: true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'سجل ${_selectedProvider.name}',
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
                        child: Icon(entry.type == 'income'
                            ? Icons.south_west
                            : Icons.north_east),
                      ),
                      title: Text(
                        '${entry.type == 'income' ? 'دخل' : 'مصروف'} • ${_money(entry.amount)} ${entry.currency}',
                      ),
                      subtitle: Text(
                        '${_categoryName(entry.categoryId)} • ${entry.note.isEmpty ? 'بدون ملاحظة' : entry.note}\n'
                        '${entry.reference.isEmpty ? '' : 'مرجع: ${entry.reference} • '}'
                        '${entry.counterparty.isEmpty ? '' : 'الجهة: ${entry.counterparty} • '}'
                        '${entry.occurredAt.toLocal().toString().substring(0, 16)}',
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
