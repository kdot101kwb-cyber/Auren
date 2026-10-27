import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first manual tracker for Bravo and MyCashi.
///
/// This screen deliberately does not log into wallet providers or move money.
/// Balances and entries are user-entered records stored on this device.
class NovaWalletTrackerScreen extends StatefulWidget {
  const NovaWalletTrackerScreen({super.key});

  @override
  State<NovaWalletTrackerScreen> createState() => _NovaWalletTrackerScreenState();
}

class _NovaWalletTrackerScreenState extends State<NovaWalletTrackerScreen> {
  static const _storageKey = 'nova.wallet.tracker.entries.v1';
  static const _violet = Color(0xFF9B87FF);
  static const _providers = <String, String>{
    'bravo_sudan': 'Bravo',
    'mycashi_sudan': 'MyCashi',
  };
  static const _types = <String, String>{
    'income': 'دخل',
    'expense': 'مصروف',
    'transfer': 'تحويل (تسجيل فقط)',
    'balance_adjustment': 'تعديل رصيد',
  };

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _walletId = 'bravo_sudan';
  String _type = 'income';
  String _currency = 'SDG';
  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _saving = false;
  String? _storageWarning;

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
    super.dispose();
  }

  Future<void> _loadEntries() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _entries = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    } catch (_) {
      _storageWarning = 'تعذرت قراءة السجل المحلي؛ يمكنك متابعة الاستخدام لكن راجع مساحة التخزين.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _persistEntries(List<Map<String, dynamic>> next) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final ok = await preferences.setString(_storageKey, jsonEncode(next));
      if (!ok) throw StateError('Local storage write returned false.');
      if (mounted) setState(() => _storageWarning = null);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _storageWarning = 'تعذر حفظ التغيير على الهاتف. لم نؤكد حفظه؛ تحقق من مساحة التخزين.');
      }
      return false;
    }
  }

  double get _incomeTotal => _totalFor('income');
  double get _expenseTotal => _totalFor('expense');

  double _totalFor(String type) => _entries
      .where((entry) => entry['type'] == type && entry['currency'] == _currency)
      .fold<double>(0, (sum, entry) => sum + ((entry['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _addEntry() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final amount = double.parse(_amountController.text.trim());
    setState(() => _saving = true);
    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'walletId': _walletId,
      'walletName': _providers[_walletId],
      'type': _type,
      'amount': amount,
      'currency': _currency,
      'note': _noteController.text.trim(),
      'reference': _referenceController.text.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'status': _type == 'transfer' ? 'manual_record_only_approval_required' : 'user_entered',
      'executionMode': 'manual_only',
    };
    final next = <Map<String, dynamic>>[entry, ..._entries];
    final saved = await _persistEntries(next);
    if (mounted) {
      setState(() {
        if (saved) _entries = next;
        _saving = false;
      });
      if (saved) {
        _amountController.clear();
        _noteController.clear();
        _referenceController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظ السجل محلياً على هذا الجهاز.')),
        );
      }
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السجل؟'),
        content: const Text('سيُحذف هذا السجل من الجهاز. لا يؤثر ذلك على حساب Bravo أو MyCashi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    final next = _entries.where((item) => item['id'] != entry['id']).toList();
    final saved = await _persistEntries(next);
    if (saved && mounted) setState(() => _entries = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: _violet, size: 30),
                      SizedBox(height: 10),
                      Text('محافظ NOVA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('متابعة يدوية لـ Bravo وMyCashi حتى عند انقطاع الإنترنت.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_storageWarning != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: Text(_storageWarning!),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ملخص السجلات المدخلة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(labelText: 'عملة عرض الملخص', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'SDG', child: Text('SDG — جنيه سوداني')),
                            DropdownMenuItem(value: 'USD', child: Text('USD — دولار أمريكي')),
                            DropdownMenuItem(value: 'SAR', child: Text('SAR — ريال سعودي')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR — يورو')),
                          ],
                          onChanged: (value) => setState(() => _currency = value ?? 'SDG'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _SummaryTile(label: 'الدخل المسجّل', value: _incomeTotal, currency: _currency, icon: Icons.south_west, color: Colors.greenAccent)),
                            const SizedBox(width: 10),
                            Expanded(child: _SummaryTile(label: 'المصروف المسجّل', value: _expenseTotal, currency: _currency, icon: Icons.north_east, color: Colors.orangeAccent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'هذه مجاميع السجلات التي أدخلتها، وليست رصيداً حياً مؤكداً من مزوّد المحفظة.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إضافة سجل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _walletId,
                            decoration: const InputDecoration(labelText: 'المحفظة', border: OutlineInputBorder()),
                            items: _providers.entries.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value))).toList(),
                            onChanged: (value) => setState(() => _walletId = value ?? 'bravo_sudan'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _type,
                            decoration: const InputDecoration(labelText: 'نوع السجل', border: OutlineInputBorder()),
                            items: _types.entries.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value))).toList(),
                            onChanged: (value) => setState(() => _type = value ?? 'income'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                            validator: (value) {
                              final amount = double.tryParse((value ?? '').trim());
                              if (amount == null || !amount.isFinite || amount <= 0) return 'أدخل مبلغاً صحيحاً أكبر من صفر';
                              if (amount > 1e12) return 'المبلغ أكبر من الحد المسموح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'SDG', child: Text('SDG — جنيه سوداني')),
                              DropdownMenuItem(value: 'USD', child: Text('USD — دولار أمريكي')),
                              DropdownMenuItem(value: 'SAR', child: Text('SAR — ريال سعودي')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR — يورو')),
                            ],
                            onChanged: (value) => setState(() => _currency = value ?? 'SDG'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(controller: _noteController, maxLength: 500, decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextFormField(controller: _referenceController, maxLength: 120, decoration: const InputDecoration(labelText: 'رقم إيصال/مرجع (اختياري)', border: OutlineInputBorder())),
                          if (_type == 'transfer')
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'تنبيه: هذا يسجل نيتك للتحويل فقط. NOVA لا تنفذ أي تحويل؛ أكمل العملية بنفسك داخل التطبيق الرسمي بعد التحقق.',
                                style: TextStyle(color: Colors.orangeAccent),
                              ),
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _addEntry,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ السجل على الهاتف'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Text('آخر السجلات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                    Text('${_entries.length}'),
                  ],
                ),
                const SizedBox(height: 8),
                if (_entries.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد سجلات بعد. أضف أول دخل أو مصروف.')))
                else
                  ..._entries.map(_entryCard),
                const SizedBox(height: 12),
                const Text(
                  'الخصوصية: البيانات محفوظة محلياً في تفضيلات التطبيق على هذا الجهاز. لا توجد مزامنة سحابية أو قراءة تلقائية للأرصدة في هذه النسخة.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
    );
  }

  Widget _entryCard(Map<String, dynamic> entry) {
    final type = entry['type']?.toString() ?? 'income';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(entry['createdAt']?.toString() ?? '')?.toLocal();
    final isIncome = type == 'income';
    final icon = type == 'income'
        ? Icons.south_west
        : type == 'expense'
            ? Icons.north_east
            : type == 'transfer'
                ? Icons.swap_horiz
                : Icons.tune;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, color: isIncome ? Colors.greenAccent : _violet)),
        title: Text('${entry['walletName'] ?? _providers[entry['walletId']] ?? 'محفظة'} • ${_types[type] ?? type}'),
        subtitle: Text([
          if ((entry['note'] ?? '').toString().isNotEmpty) entry['note'].toString(),
          if ((entry['reference'] ?? '').toString().isNotEmpty) 'مرجع: ${entry['reference']}',
          if (createdAt != null) '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
          if (type == 'transfer') 'تسجيل فقط — لا يوجد تحويل فعلي',
        ].join(' • ')),
        isThreeLine: true,
        trailing: SizedBox(
          width: 105,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text('${amount.toStringAsFixed(2)} ${entry['currency'] ?? 'SDG'}', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.greenAccent : Colors.white))),
              IconButton(
                tooltip: 'حذف السجل',
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteEntry(entry),
                icon: const Icon(Icons.delete_outline, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text(currency, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}
