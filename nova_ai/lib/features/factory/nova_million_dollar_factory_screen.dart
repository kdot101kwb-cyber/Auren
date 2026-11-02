import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first workspace for validating NOVA's first zero-budget service.
class NovaMillionDollarFactoryScreen extends StatefulWidget {
  const NovaMillionDollarFactoryScreen({super.key});

  @override
  State<NovaMillionDollarFactoryScreen> createState() =>
      _NovaMillionDollarFactoryScreenState();
}

class _NovaMillionDollarFactoryScreenState
    extends State<NovaMillionDollarFactoryScreen> {
  static const _storageKey = 'nova.factory.workspace.v1';
  static const _starterOffer =
      'Sudanese Arabic AI localization and quality review';
  final _leadController = TextEditingController();
  final _amountController = TextEditingController();
  final List<String> _leads = [];
  final List<String> _workItems = [
    'Prepare a 10-line Sudanese Arabic sample with English meaning.',
    'Compare two AI translations and mark meaning/tone errors.',
    'Create a one-page service description and quality checklist.',
    'Find five potential buyers and verify their country/payment terms.',
  ];
  final Set<int> _completed = {};
  double _receivedUsd = 0;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _leadController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final leads = data['leads'];
          final completed = data['completed'];
          final amount = data['receivedUsd'];
          if (leads is List) {
            _leads.addAll(leads.whereType<String>().take(100));
          }
          if (completed is List) {
            _completed.addAll(completed.whereType<int>().where(
                  (i) => i >= 0 && i < _workItems.length,
                ));
          }
          if (amount is num && amount.isFinite && amount >= 0) {
            _receivedUsd = amount.toDouble();
          }
        }
      }
    } catch (_) {
      _message = 'تعذر استرجاع نسخة محلية سليمة؛ يمكنك متابعة العمل من جديد.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode({
        'leads': _leads,
        'completed': _completed.toList(),
        'receivedUsd': _receivedUsd,
      }));
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'تعذر حفظ التغيير على الهاتف.');
      }
    }
  }

  Future<void> _addLead() async {
    final value = _leadController.text.trim();
    if (value.isEmpty || _leads.length >= 100) return;
    setState(() {
      _leads.add(value);
      _leadController.clear();
      _message = 'أُضيف العميل المحتمل محلياً؛ لم يتم التواصل معه.';
    });
    await _persist();
  }

  Future<void> _recordReceived() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0 || amount > 1000000) {
      setState(() => _message = 'أدخل مبلغاً مستلماً صحيحاً أكبر من صفر.');
      return;
    }
    setState(() {
      _receivedUsd += amount;
      _amountController.clear();
      _message = 'سُجل المبلغ الذي أدخلته كدفعة مستلمة يدوياً.';
    });
    await _persist();
  }

  Future<void> _toggleWork(int index, bool value) async {
    setState(() {
      if (value) {
        _completed.add(index);
      } else {
        _completed.remove(index);
      }
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completed.length / _workItems.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF392B70), Color(0xFF155E59)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rocket_launch, color: Color(0xFFB9F3E8), size: 32),
                SizedBox(height: 10),
                Text(
                  'NOVA AI MILLION DOLLAR FACTORY',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'مصنع مشاريع يبدأ بتجربة صغيرة بلا رأس مال، ويكبر فقط عندما يثبت الطلب والجودة والربح.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'الدخل المستلم',
                  'USD ${_receivedUsd.toStringAsFixed(2)}',
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  'عملاء محتملون',
                  _leads.length.toString(),
                  Icons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'المشروع الأول قيد الاختبار',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(_starterOffer,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'خدمة تجريبية لمراجعة الترجمة والتوطين باللهجة السودانية: وضوح المعنى، طبيعية التعبير، المصطلحات، ونبرة الكلام. لا نعلن عن خبرة أو اعتماد غير مثبت.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'العميل المحتمل: شركات AI، فرق بيانات اللغة، ومطورو التطبيقات الذين يحتاجون مراجعة عربية سودانية.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قبل البيع: أنشئ عينة أصلية، اختبر الجودة، ثم تحقق من أهلية البلد وطريقة الدفع لدى المشتري. لا توجد أرباح مضمونة.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('خطة التحقق المجانية',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Text('${_completed.length} من ${_workItems.length} خطوات مكتملة'),
          for (var i = 0; i < _workItems.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _completed.contains(i),
              onChanged: _loading
                  ? null
                  : (value) => _toggleWork(i, value ?? false),
              title: Text(_workItems[i]),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 12),
          const Text('سجل العملاء المحتملين',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          TextField(
            controller: _leadController,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'اسم شركة أو رابط فرصة (للتتبع فقط)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _addLead,
            icon: const Icon(Icons.add),
            label: const Text('إضافة إلى القائمة المحلية'),
          ),
          for (final lead in _leads)
            Card(
              child: ListTile(
                leading: const Icon(Icons.business_outlined),
                title: Text(lead),
                subtitle: const Text('لم يتم إرسال طلب أو رسالة'),
              ),
            ),
          const SizedBox(height: 16),
          const Text('دفعات مؤكدة يدوياً',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const Text(
            'لا يُسجل أي دخل تلقائياً. أدخل المبلغ فقط بعد استلامه فعلياً.',
          ),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'مبلغ مستلم بالدولار',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _recordReceived,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('تسجيل دفعة مستلمة'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!, style: const TextStyle(color: Colors.amberAccent)),
          ],
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'حدود الأمان: لا دفع لاشتراك أو رصيد أو رسوم تقديم. لا رسائل أو نشر أو عقود تلقائية. لا تداول أو تحويلات. بيانات العملاء والدخل محفوظة محلياً على هذا الهاتف فقط.',
              ),
            ),
          ),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(label),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
