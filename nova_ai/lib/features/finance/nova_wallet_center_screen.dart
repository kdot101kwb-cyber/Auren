import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _storageKey = 'nova.wallet_center.entries.v1';

enum _WalletProvider {
  bravo('Bravo', 'برافو', 'https://play.google.com/store/apps/details?id=istinara.bravocash'),
  myCashi('MyCashi', 'ماي كاشي', 'https://play.google.com/store/apps/details?id=com.alsoug.mycashi'),
  other('Other', 'أخرى', '');

  const _WalletProvider(this.englishName, this.arabicName, this.storeUrl);
  final String englishName;
  final String arabicName;
  final String storeUrl;
}

class _WalletEntry {
  const _WalletEntry({
    required this.id,
    required this.provider,
    required this.amountMinor,
    required this.currency,
    required this.kind,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final _WalletProvider provider;
  final int amountMinor;
  final String currency;
  final String kind;
  final String note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'provider': provider.name,
        'amountMinor': amountMinor,
        'currency': currency,
        'kind': kind,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _WalletEntry.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider']?.toString();
    final provider = _WalletProvider.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => _WalletProvider.other,
    );
    final amount = json['amountMinor'];
    final parsedDate = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    return _WalletEntry(
      id: json['id']?.toString() ?? '',
      provider: provider,
      amountMinor: amount is int ? amount : 0,
      currency: (json['currency']?.toString() ?? 'SDG').toUpperCase(),
      kind: json['kind'] == 'expense' ? 'expense' : 'income',
      note: json['note']?.toString() ?? '',
      createdAt: parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Local, manual ledger only. It does not connect to wallet accounts or move money.
class NovaWalletCenterScreen extends StatefulWidget {
  const NovaWalletCenterScreen({super.key});

  @override
  State<NovaWalletCenterScreen> createState() => _NovaWalletCenterScreenState();
}

class _NovaWalletCenterScreenState extends State<NovaWalletCenterScreen> {
  List<_WalletEntry> _entries = <_WalletEntry>[];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? <String>[];
      final entries = <_WalletEntry>[];
      for (final item in raw) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map<String, dynamic>) entries.add(_WalletEntry.fromJson(decoded));
        } catch (_) {
          // Ignore a malformed local row rather than losing the rest of the ledger.
        }
      }
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveEntries(List<_WalletEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _addEntry() async {
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    var provider = _WalletProvider.bravo;
    var kind = 'income';
    var currency = 'SDG';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_WalletEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل حركة مالية'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<_WalletProvider>(
                    value: provider,
                    decoration: const InputDecoration(labelText: 'المحفظة'),
                    items: _WalletProvider.values
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.arabicName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => provider = value);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: kind,
                    decoration: const InputDecoration(labelText: 'نوع الحركة'),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('دخل مستلم')),
                      DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => kind = value);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: currency,
                    decoration: const InputDecoration(labelText: 'العملة'),
                    items: const [
                      DropdownMenuItem(value: 'SDG', child: Text('جنيه سوداني (SDG)')),
                      DropdownMenuItem(value: 'USD', child: Text('دولار (USD)')),
                      DropdownMenuItem(value: 'EUR', child: Text('يورو (EUR)')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => currency = value);
                    },
                  ),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      return amount == null || !amount.isFinite || amount <= 0
                          ? 'أدخل مبلغاً صحيحاً أكبر من صفر'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: noteController,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      hintText: 'مثال: دفعة من عميل',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سجل يدوي محلي فقط. لا تدخل كلمة مرور أو رمز تحقق أو رقم بطاقة.',
                    style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final amount = double.parse(amountController.text.trim());
                final minor = (amount * 100).round();
                Navigator.pop(
                  dialogContext,
                  _WalletEntry(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    provider: provider,
                    amountMinor: minor,
                    currency: currency,
                    kind: kind,
                    note: noteController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('حفظ الحركة'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    amountController.dispose();
    if (result == null || !mounted) return;
    final updated = <_WalletEntry>[result, ..._entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    try {
      await _saveEntries(updated);
      if (mounted) setState(() => _entries = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الحركة على هذا الجهاز.')),
        );
      }
    }
  }

  Future<void> _openProvider(_WalletProvider provider) async {
    if (provider.storeUrl.isEmpty) return;
    final uri = Uri.parse(provider.storeUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة التطبيق.')),
      );
    }
  }

  String _money(int minor, String currency) =>
      '${(minor / 100).toStringAsFixed(2)} $currency';

  @override
  Widget build(BuildContext context) {
    final filtered = _entries.where((entry) {
      if (_filter == 'all') return true;
      if (_filter == 'income') return entry.kind == 'income';
      if (_filter == 'expense') return entry.kind == 'expense';
      return entry.provider.name == _filter;
    }).toList();
    final income = _totalsByCurrency('income');
    final expenses = _totalsByCurrency('expense');

    return Scaffold(
      appBar: AppBar(title: const Text('محافظ NOVA المالية')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل حركة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.greenAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'وضع آمن: هذه الصفحة تسجل الحركات يدوياً على جهازك. لا يوجد ربط مباشر بالحسابات أو تنفيذ تحويلات مالية.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _providerCard(_WalletProvider.bravo),
                _providerCard(_WalletProvider.myCashi),
                const SizedBox(height: 12),
                const Text('ملخص السجل المحلي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _summary('الدخل المسجل', income, Colors.greenAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _summary('المصروفات المسجلة', expenses, Colors.orangeAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filter,
                  decoration: const InputDecoration(
                    labelText: 'تصفية الحركات',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كل الحركات')),
                    DropdownMenuItem(value: 'income', child: Text('الدخل فقط')),
                    DropdownMenuItem(value: 'expense', child: Text('المصروفات فقط')),
                    DropdownMenuItem(value: 'bravo', child: Text('برافو فقط')),
                    DropdownMenuItem(value: 'myCashi', child: Text('ماي كاشي فقط')),
                    DropdownMenuItem(value: 'other', child: Text('محافظ أخرى')),
                  ],
                  onChanged: (value) => setState(() => _filter = value ?? 'all'),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('لا توجد حركات مسجلة. استخدم «تسجيل حركة» لإضافة دخل أو مصروف.'),
                    ),
                  ),
                ...filtered.map(_entryTile),
              ],
            ),
    );
  }

  Widget _providerCard(_WalletProvider provider) => Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(provider == _WalletProvider.bravo
                ? Icons.account_balance_wallet_outlined
                : Icons.payments_outlined),
          ),
          title: Text(provider.arabicName),
          subtitle: Text(provider == _WalletProvider.bravo
              ? 'دفعات وتحويلات وفق خدمات التطبيق الرسمية'
              : 'محفظة دفع وتحويلات وفق خدمات التطبيق الرسمية'),
          trailing: provider.storeUrl.isEmpty
              ? null
              : IconButton(
                  tooltip: 'فتح صفحة التطبيق',
                  onPressed: () => _openProvider(provider),
                  icon: const Icon(Icons.open_in_new),
                ),
        ),
      );

  Map<String, int> _totalsByCurrency(String kind) {
    final totals = <String, int>{};
    for (final entry in _entries.where((entry) => entry.kind == kind)) {
      totals.update(entry.currency, (value) => value + entry.amountMinor,
          ifAbsent: () => entry.amountMinor);
    }
    return totals;
  }

  Widget _summary(String label, Map<String, int> totals, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              if (totals.isEmpty) Text(_money(0, 'SDG'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
              ...totals.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      _money(entry.value, entry.key),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                    ),
                  )),
              const Text('كل عملة محسوبة منفصلة؛ لا يوجد تحويل بسعر صرف.',
                  style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );

  Widget _entryTile(_WalletEntry entry) => Card(
        child: ListTile(
          leading: Icon(
            entry.kind == 'income' ? Icons.south_west : Icons.north_east,
            color: entry.kind == 'income' ? Colors.greenAccent : Colors.orangeAccent,
          ),
          title: Text(entry.note.isEmpty ? entry.provider.arabicName : entry.note),
          subtitle: Text(
            '${entry.provider.arabicName} • ${entry.createdAt.toLocal().toString().substring(0, 16)}',
          ),
          trailing: Text(
            '${entry.kind == 'income' ? '+' : '−'}${_money(entry.amountMinor, entry.currency)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: entry.kind == 'income' ? Colors.greenAccent : Colors.orangeAccent,
            ),
          ),
        ),
      );
}
