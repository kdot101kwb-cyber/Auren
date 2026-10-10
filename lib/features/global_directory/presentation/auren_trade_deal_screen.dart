import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local draft tracker for organizing a trade opportunity.
/// It persists on this device only and never contacts external parties.
class AurenTradeDealScreen extends StatefulWidget {
  const AurenTradeDealScreen({super.key});

  @override
  State<AurenTradeDealScreen> createState() => _AurenTradeDealScreenState();
}

class _AurenTradeDealScreenState extends State<AurenTradeDealScreen> {
  final _product = TextEditingController();
  final _counterparty = TextEditingController();
  final _quantity = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();

  static const _stages = <String>[
    'تحديد الاحتياج',
    'طلب عروض الأسعار',
    'مقارنة العروض',
    'التحقق من الطرف',
    'التفاوض والاتفاق',
    'الشحن والمستندات',
    'اكتملت الصفقة',
  ];

  int _stage = 0;
  String _currency = 'USD';
  bool _loaded = false;
  String _status = 'جارٍ تحميل بيانات الصفقة…';

  String get _storageKey => 'auren_trade_deal_v1';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_storageKey);
      if (!mounted) return;
      if (values != null && values.length >= 8) {
        _product.text = values[0];
        _counterparty.text = values[1];
        _quantity.text = values[2];
        _value.text = values[3];
        _notes.text = values[4];
        _currency = values[5];
        _stage = (int.tryParse(values[6]) ?? 0).clamp(0, _stages.length - 1).toInt();
      }
      setState(() { _loaded = true; _status = values == null ? 'لا توجد صفقة محفوظة بعد.' : 'تم تحميل المسودة المحفوظة على هذا الجهاز.'; });
    } catch (_) {
      if (mounted) setState(() { _loaded = true; _status = 'تعذر تحميل المسودة المحلية.'; });
    }
  }

  Future<void> _saveDraft() async {
    if (!_loaded) return;
    final values = <String>[_product.text, _counterparty.text, _quantity.text, _value.text, _notes.text, _currency, '$_stage', DateTime.now().toIso8601String()];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, values);
      if (mounted) setState(() => _status = 'تم حفظ المسودة على هذا الجهاز.');
    } catch (_) {
      if (mounted) setState(() => _status = 'تعذر حفظ المسودة؛ انسخ الملخص للاحتفاظ به.');
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (!mounted) return;
    _product.clear(); _counterparty.clear(); _quantity.clear(); _value.clear(); _notes.clear();
    setState(() { _stage = 0; _currency = 'USD'; _status = 'تم مسح المسودة المحلية.'; });
  }

  @override
  void dispose() {
    _product.dispose();
    _counterparty.dispose();
    _quantity.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('متابعة صفقة تجارية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'نظّم رحلة الصفقة من تحديد المنتج إلى إغلاقها. تُحفظ المسودة على هذا الجهاز فقط؛ لا تُرسل رسائل ولا تُزامَن مع حسابك أو أجهزة أخرى.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_status, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _product,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'المنتج أو الخدمة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _counterparty,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'اسم المورد أو المشتري (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'الكمية',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _value,
                  onChanged: (_) => _saveDraft(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'قيمة الصفقة التقديرية',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _currency,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                  DropdownMenuItem(value: 'KES', child: Text('KES')),
                  DropdownMenuItem(value: 'AED', child: Text('AED')),
                  DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _currency = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            onChanged: (_) => _saveDraft(),
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظات وشروط ومواعيد',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('مرحلة الصفقة', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_stage + 1) / _stages.length),
          const SizedBox(height: 8),
          ...List.generate(_stages.length, (index) {
            return RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: index,
              groupValue: _stage,
              title: Text(_stages[index]),
              secondary: Icon(
                index < _stage
                    ? Icons.check_circle
                    : index == _stage
                        ? Icons.radio_button_checked
                        : Icons.circle_outlined,
              ),
              onChanged: (value) {
                if (value != null) setState(() => _stage = value);
                _saveDraft();
              },
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final details = [
                'متابعة صفقة تجارية',
                'المنتج/الخدمة: ${_product.text.trim().isEmpty ? 'غير محدد' : _product.text.trim()}',
                'الطرف: ${_counterparty.text.trim().isEmpty ? 'لم يحدد بعد' : _counterparty.text.trim()}',
                'الكمية: ${_quantity.text.trim().isEmpty ? 'غير محددة' : _quantity.text.trim()}',
                'القيمة التقديرية: ${_value.text.trim().isEmpty ? 'غير محددة' : '${_value.text.trim()} $_currency'}',
                'المرحلة: ${_stages[_stage]}',
                if (_notes.text.trim().isNotEmpty) 'ملاحظات: ${_notes.text.trim()}',
              ].join('\n');
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ملخص الصفقة'),
                  content: SingleChildScrollView(child: SelectableText(details)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.summarize_outlined),
            label: const Text('عرض ملخص الصفقة'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _clearDraft,
            icon: const Icon(Icons.delete_outline),
            label: const Text('مسح المسودة المحفوظة'),
          ),
          const SizedBox(height: 12),
          const Text(
            'قبل الدفع أو الشحن، تحقق بشكل مستقل من هوية الطرف، والعقد، وشروط الدفع، والتراخيص والمستندات المطلوبة.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
