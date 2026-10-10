import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local comparison of supplier quotations. It does not verify vendors
/// or send messages, orders, or payments.
class AurenSupplierOfferComparisonScreen extends StatefulWidget {
  const AurenSupplierOfferComparisonScreen({super.key});

  @override
  State<AurenSupplierOfferComparisonScreen> createState() =>
      _AurenSupplierOfferComparisonScreenState();
}

class _AurenSupplierOfferComparisonScreenState
    extends State<AurenSupplierOfferComparisonScreen> {
  static const _currencies = ['USD', 'EUR', 'SDG', 'KES', 'AED', 'NGN'];
  static const _statuses = [
    'وصل العرض',
    'قيد المراجعة',
    'بانتظار توضيح',
    'تم اختياره',
    'مرفوض',
    'منتهي الصلاحية',
  ];
  final _formKey = GlobalKey<FormState>();
  final _supplier = TextEditingController();
  final _price = TextEditingController();
  final _shipping = TextEditingController(text: '0');
  final _leadTime = TextEditingController();
  final _minimumOrder = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _validUntil = TextEditingController();
  String _currency = 'USD';
  String _status = 'وصل العرض';
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  String _message = 'جارٍ تحميل العروض…';
  StreamSubscription<User?>? _authSubscription;
  String? _observedUserId;
  int _loadGeneration = 0;
  Future<void> _writeQueue = Future<void>.value();

  String get _key =>
      'auren_supplier_offers_v1_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _observedUserId = FirebaseAuth.instance.currentUser?.uid;
    _load();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _observedUserId) return;
      _observedUserId = user?.uid;
      _loadGeneration++;
      setState(() {
        _offers = [];
        _loading = true;
        _message = 'تغيّر الحساب؛ جارٍ تحميل عروضه المحفوظة…';
      });
      _load();
    });
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final storageKey = 'auren_supplier_offers_v1_' + (userId ?? 'guest');
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      if (!mounted || generation != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != userId) return;
      setState(() {
        _offers = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where(_isValidStoredOffer)
            .toList();
        _loading = false;
        _message = _offers.isEmpty
            ? 'أضف العروض التي استلمتها فعلياً للمقارنة.'
            : 'تم تحميل ${_offers.length} عرض محفوظ على هذا الجهاز.';
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != userId) return;
      setState(() {
        _loading = false;
        _message = 'تعذر قراءة العروض المحفوظة؛ يمكنك إضافة عرض جديد.';
      });
    }
  }

  bool _isValidStoredOffer(Map<String, dynamic> offer) {
    return (offer['id'] is String) &&
        (offer['supplier'] is String) &&
        (offer['price'] is num) &&
        (offer['shipping'] is num) &&
        _currencies.contains(offer['currency']) &&
        _statuses.contains(offer['status']);
  }

  double? _number(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '').replaceAll(' ', ''));
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    return parsed;
  }

  Future<void> _persist() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final storageKey = 'auren_supplier_offers_v1_' + (userId ?? 'guest');
    final snapshot = jsonEncode(_offers.map((offer) => Map<String, dynamic>.from(offer)).toList());
    final write = _writeQueue.catchError((Object _) {}).then((_) async {
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      final prefs = await SharedPreferences.getInstance();
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      await prefs.setString(storageKey, snapshot);
    });
    _writeQueue = write;
    try {
      await write;
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == userId) {
        setState(() => _message = 'تعذر حفظ التغيير على الجهاز. تحقق من المساحة ثم أعد المحاولة.');
      }
    }
  }

  Future<void> _addOffer() async {
    if (!_formKey.currentState!.validate()) return;
    final price = _number(_price.text);
    final shipping = _number(_shipping.text);
    if (price == null || shipping == null) return;
    final offer = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'supplier': _supplier.text.trim(),
      'price': price,
      'shipping': shipping,
      'currency': _currency,
      'leadTime': _leadTime.text.trim(),
      'minimumOrder': _minimumOrder.text.trim(),
      'paymentTerms': _paymentTerms.text.trim(),
      'validUntil': _validUntil.text.trim(),
      'status': _status,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _offers = [..._offers, offer];
      _message = 'تمت إضافة العرض للمقارنة؛ تأكد من أن بياناته من المورد فعلاً.';
      _supplier.clear();
      _price.clear();
      _shipping.text = '0';
      _leadTime.clear();
      _minimumOrder.clear();
      _paymentTerms.clear();
      _validUntil.clear();
      _currency = 'USD';
      _status = 'وصل العرض';
    });
    await _persist();
  }

  Future<void> _changeStatus(String id, String status) async {
    setState(() {
      _offers = _offers.map((offer) => offer['id'] == id
          ? {...offer, 'status': status, 'updatedAt': DateTime.now().toIso8601String()}
          : offer).toList();
      _message = 'تم تحديث حالة العرض.';
    });
    await _persist();
  }

  Future<void> _deleteOffer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العرض؟'),
        content: const Text('سيُحذف هذا العرض من قائمة المقارنة على هذا الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _offers = _offers.where((offer) => offer['id'] != id).toList();
      _message = 'تم حذف العرض.';
    });
    await _persist();
  }

  Future<void> _copyComparison() async {
    final rows = _sortedOffers.map((offer) {
      final total = (offer['price'] as num).toDouble() +
          (offer['shipping'] as num).toDouble();
      return '${offer['supplier']} | ${offer['status']} | السعر: ${offer['price']} ${offer['currency']} | الشحن: ${offer['shipping']} ${offer['currency']} | الإجمالي المبدئي: $total ${offer['currency']} | التسليم: ${offer['leadTime']} | الحد الأدنى: ${offer['minimumOrder']} | الدفع: ${offer['paymentTerms']} | الصلاحية: ${offer['validUntil']}';
    }).join('\n');
    final text = 'مقارنة عروض الموردين (مدخلات يدوية غير متحقق منها)\n$rows\n\nالإجمالي لا يشمل بالضرورة الضرائب والتأمين والجمارك والرسوم الأخرى.';
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ ملخص المقارنة. راجع كل الرسوم قبل اتخاذ القرار.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر النسخ؛ يمكنك مراجعة العروض في القائمة.');
    }
  }

  List<Map<String, dynamic>> get _sortedOffers {
    final list = List<Map<String, dynamic>>.from(_offers);
    list.sort((a, b) {
      if (a['currency'] != b['currency']) {
        return (a['supplier'] as String).compareTo(b['supplier'] as String);
      }
      final totalA = (a['price'] as num).toDouble() + (a['shipping'] as num).toDouble();
      final totalB = (b['price'] as num).toDouble() + (b['shipping'] as num).toDouble();
      return totalA.compareTo(totalB);
    });
    return list;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loadGeneration++;
    _supplier.dispose();
    _price.dispose();
    _shipping.dispose();
    _leadTime.dispose();
    _minimumOrder.dispose();
    _paymentTerms.dispose();
    _validUntil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة عروض الموردين'),
        actions: [
          IconButton(
            tooltip: 'نسخ ملخص المقارنة',
            onPressed: _offers.isEmpty ? null : _copyComparison,
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'سجّل الأسعار والشحن وشروط كل عرض، ثم قارن العروض بالعملة نفسها. هذه بيانات تدخلها يدوياً وليست عروضاً موثقة؛ تحقق من المورد والرسوم والشروط قبل الدفع.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_message, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Text('إضافة عرض مستلم', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _supplier,
                        maxLength: 160,
                        decoration: const InputDecoration(labelText: 'اسم المورد', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'أدخل اسم المورد' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'سعر العرض', border: OutlineInputBorder()),
                          validator: (v) => _number(v ?? '') == null ? 'أدخل رقماً غير سالب' : null,
                        )),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _currency,
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _currency = v); },
                        ),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _shipping,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'الشحن والتوصيل (اكتب 0 إن لم تعرفه)', border: OutlineInputBorder()),
                        validator: (v) => _number(v ?? '') == null ? 'أدخل رقماً غير سالب' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(controller: _leadTime, maxLength: 120, decoration: const InputDecoration(labelText: 'مدة التجهيز والتسليم', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextFormField(controller: _minimumOrder, maxLength: 120, decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextFormField(controller: _paymentTerms, maxLength: 200, decoration: const InputDecoration(labelText: 'شروط الدفع', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextFormField(controller: _validUntil, maxLength: 80, decoration: const InputDecoration(labelText: 'صلاحية العرض / تاريخ الانتهاء', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'حالة العرض', border: OutlineInputBorder()),
                        items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _status = v); },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addOffer,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة العرض للمقارنة'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Text('العروض المسجلة (${_offers.length})', style: theme.textTheme.titleLarge)),
                  if (_offers.isNotEmpty) IconButton(onPressed: _copyComparison, tooltip: 'نسخ المقارنة', icon: const Icon(Icons.copy)),
                ]),
                if (_offers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('لا توجد عروض بعد. أضف عرضاً واحداً أو أكثر للمقارنة.'),
                  ),
                ..._sortedOffers.map((offer) {
                  final total = (offer['price'] as num).toDouble() + (offer['shipping'] as num).toDouble();
                  final sameCurrency = _offers.where((item) => item['currency'] == offer['currency']).length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Text(offer['supplier'] as String, style: theme.textTheme.titleMedium)),
                          IconButton(onPressed: () => _deleteOffer(offer['id'] as String), tooltip: 'حذف العرض', icon: const Icon(Icons.delete_outline)),
                        ]),
                        Text('السعر: ${offer['price']} ${offer['currency']}  •  الشحن: ${offer['shipping']} ${offer['currency']}'),
                        Text('الإجمالي المبدئي: $total ${offer['currency']}', style: theme.textTheme.titleSmall),
                        if (sameCurrency > 1) Text('تُرتّب العروض ذات العملة نفسها حسب السعر + الشحن.', style: theme.textTheme.bodySmall),
                        if ((offer['leadTime'] as String).isNotEmpty) Text('التسليم: ${offer['leadTime']}'),
                        if ((offer['minimumOrder'] as String).isNotEmpty) Text('الحد الأدنى: ${offer['minimumOrder']}'),
                        if ((offer['paymentTerms'] as String).isNotEmpty) Text('الدفع: ${offer['paymentTerms']}'),
                        if ((offer['validUntil'] as String).isNotEmpty) Text('الصلاحية: ${offer['validUntil']}'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: offer['status'] as String,
                          decoration: const InputDecoration(labelText: 'تحديث الحالة', border: OutlineInputBorder()),
                          items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (value) { if (value != null) _changeStatus(offer['id'] as String, value); },
                        ),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text('تنبيه: لا تقارن عملات مختلفة مباشرة. الإجمالي المعروض = السعر + الشحن فقط، ولا يشمل بالضرورة الضرائب أو التأمين أو الجمارك أو رسوم التحويل.'),
              ],
            ),
    );
  }
}
