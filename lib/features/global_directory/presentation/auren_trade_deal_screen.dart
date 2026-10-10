import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        _applyValues(values);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('trade_deals')
              .doc('active_draft')
              .get();
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            _product.text = data['product'] as String? ?? '';
            _counterparty.text = data['counterparty'] as String? ?? '';
            _quantity.text = data['quantity'] as String? ?? '';
            _value.text = data['estimatedValue'] as String? ?? '';
            _notes.text = data['notes'] as String? ?? '';
            final currency = data['currency'] as String? ?? 'USD';
            _currency = const ['USD', 'EUR', 'SDG', 'KES', 'AED', 'NGN']
                    .contains(currency)
                ? currency
                : 'USD';
            _stage = ((data['stage'] as num?)?.toInt() ?? 0)
                .clamp(0, _stages.length - 1)
                .toInt();
            setState(() {
              _loaded = true;
              _status = 'تم تحميل مسودة الصفقة من حسابك.';
            });
            await _persistLocalSilently();
            return;
          }
        } catch (_) {
          // Keep the local draft available if cloud access is unavailable.
        }
      }

      setState(() {
        _loaded = true;
        _status = values == null
            ? (user == null
                ? 'لا توجد مسودة محفوظة بعد. سجّل الدخول للمزامنة مع حسابك.'
                : 'لا توجد مسودة سحابية؛ يمكنك حفظ المسودة الحالية في حسابك.')
            : 'تم تحميل المسودة المحفوظة على هذا الجهاز.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _status = 'تعذر تحميل المسودة المحلية.';
        });
      }
    }
  }

  void _applyValues(List<String> values) {
    _product.text = values[0];
    _counterparty.text = values[1];
    _quantity.text = values[2];
    _value.text = values[3];
    _notes.text = values[4];
    final currency = values[5];
    _currency = const ['USD', 'EUR', 'SDG', 'KES', 'AED', 'NGN']
            .contains(currency)
        ? currency
        : 'USD';
    _stage = (int.tryParse(values[6]) ?? 0)
        .clamp(0, _stages.length - 1)
        .toInt();
  }

  Future<void> _persistLocalSilently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, <String>[
      _product.text,
      _counterparty.text,
      _quantity.text,
      _value.text,
      _notes.text,
      _currency,
      '$_stage',
      DateTime.now().toIso8601String(),
    ]);
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

  Future<void> _saveToAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = 'سجّل الدخول أولاً لحفظ الصفقة في حسابك. المسودة المحلية ما زالت متاحة.');
      return;
    }
    if (_product.text.trim().isEmpty) {
      setState(() => _status = 'أدخل المنتج أو الخدمة قبل الحفظ في حسابك.');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trade_deals')
          .doc('active_draft')
          .set(<String, dynamic>{
        'ownerId': user.uid,
        'product': _product.text.trim(),
        'counterparty': _counterparty.text.trim(),
        'quantity': _quantity.text.trim(),
        'estimatedValue': _value.text.trim(),
        'currency': _currency,
        'notes': _notes.text.trim(),
        'stage': _stage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _persistLocalSilently();
      if (mounted) setState(() => _status = 'تم حفظ مسودة الصفقة في حسابك وعلى هذا الجهاز.');
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _status = error.code == 'permission-denied'
            ? 'رفضت قواعد Firestore الحفظ؛ تأكد من نشر قواعد الأمان الجديدة.'
            : 'تعذر الحفظ السحابي (${error.code})؛ بيانات الجهاز لم تُحذف.');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'تعذر الحفظ السحابي؛ بيانات الجهاز لم تُحذف.');
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
                'نظّم رحلة الصفقة من تحديد المنتج إلى إغلاقها. تُحفظ المسودة محلياً تلقائياً. يمكنك حفظ نسخة في حسابك عند تسجيل الدخول؛ لا تُرسل رسائل أو أوامر شراء.',
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
            onPressed: _saveToAccount,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('حفظ الصفقة في حسابي'),
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
