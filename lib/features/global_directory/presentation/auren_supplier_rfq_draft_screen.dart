import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prepares an editable RFQ draft. It never sends a message to a supplier.
class AurenSupplierRfqDraftScreen extends StatefulWidget {
  const AurenSupplierRfqDraftScreen({super.key, this.initialSupplier});

  /// Optional discovery platform/source name; it is not a verified supplier.
  final String? initialSupplier;

  @override
  State<AurenSupplierRfqDraftScreen> createState() =>
      _AurenSupplierRfqDraftScreenState();
}

class _AurenSupplierRfqDraftScreenState
    extends State<AurenSupplierRfqDraftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _contactController = TextEditingController();
  String _currency = 'USD';
  String _delivery = 'شحن إلى العنوان';
  String? _draft;
  Timer? _saveTimer;
  StreamSubscription<User?>? _authSubscription;
  String? _observedUserId;
  int _loadGeneration = 0;
  bool _loaded = false;
  Future<void> _writeQueue = Future<void>.value();

  String _storageKey(String? userId) =>
      'auren_supplier_rfq_draft_v1_${userId ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _observedUserId = FirebaseAuth.instance.currentUser?.uid;
    final initialSupplier = widget.initialSupplier?.trim();
    if (initialSupplier != null && initialSupplier.isNotEmpty) {
      _targetController.text = initialSupplier;
    }
    _loadSavedDraft();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _observedUserId) return;
      _observedUserId = user?.uid;
      _saveTimer?.cancel();
      _loadGeneration++;
      _targetController.clear();
      _productController.clear();
      _quantityController.clear();
      _destinationController.clear();
      _specificationsController.clear();
      _budgetController.clear();
      _contactController.clear();
      setState(() {
        _currency = 'USD';
        _delivery = 'شحن إلى العنوان';
        _draft = null;
        _loaded = false;
      });
      _loadSavedDraft();
    });
  }

  Future<void> _loadSavedDraft() async {
    final generation = ++_loadGeneration;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final key = _storageKey(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (!mounted || generation != _loadGeneration ||
          FirebaseAuth.instance.currentUser?.uid != userId) return;
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _targetController.text = (decoded['target'] as String?) ?? _targetController.text;
          _productController.text = (decoded['product'] as String?) ?? '';
          _quantityController.text = (decoded['quantity'] as String?) ?? '';
          _destinationController.text = (decoded['destination'] as String?) ?? '';
          _specificationsController.text = (decoded['specifications'] as String?) ?? '';
          _budgetController.text = (decoded['budget'] as String?) ?? '';
          _contactController.text = (decoded['contact'] as String?) ?? '';
          _currency = (decoded['currency'] as String?) ?? 'USD';
          _delivery = (decoded['delivery'] as String?) ?? 'شحن إلى العنوان';
          final savedDraft = decoded['draft'];
          _draft = savedDraft is String ? savedDraft : null;
        }
      }
    } catch (_) {
      // A malformed local draft should not prevent creating a new RFQ.
    } finally {
      if (mounted && generation == _loadGeneration &&
          FirebaseAuth.instance.currentUser?.uid == userId) {
        setState(() => _loaded = true);
      }
    }
  }

  void _scheduleSave() {
    if (!_loaded) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _persistDraft);
  }

  Future<void> _persistDraft() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final key = _storageKey(userId);
    final snapshot = <String, Object?>{
      'target': _targetController.text,
      'product': _productController.text,
      'quantity': _quantityController.text,
      'destination': _destinationController.text,
      'specifications': _specificationsController.text,
      'budget': _budgetController.text,
      'contact': _contactController.text,
      'currency': _currency,
      'delivery': _delivery,
      'draft': _draft,
    };
    _writeQueue = _writeQueue.catchError((_) {}).then((_) async {
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      final prefs = await SharedPreferences.getInstance();
      if (FirebaseAuth.instance.currentUser?.uid != userId) return;
      await prefs.setString(key, jsonEncode(snapshot));
    });
    await _writeQueue;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _authSubscription?.cancel();
    _targetController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _destinationController.dispose();
    _specificationsController.dispose();
    _budgetController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _buildDraft() {
    final budget = _budgetController.text.trim();
    final specs = _specificationsController.text.trim();
    final contact = _contactController.text.trim();
    return '''
طلب عرض سعر (RFQ)

مرحباً،
نرغب في الحصول على عرض سعر للمنتج/الخدمة التالية:
- المنصة/الجهة المستهدفة: ${_targetController.text.trim().isEmpty ? 'لم تُحدد' : _targetController.text.trim()}
- المنتج أو الخدمة: ${_productController.text.trim()}
- الكمية المطلوبة: ${_quantityController.text.trim()}
- المواصفات: ${specs.isEmpty ? 'يرجى اقتراح الخيارات المتاحة' : specs}
- الوجهة: ${_destinationController.text.trim()}
- طريقة التسليم: $_delivery
- الميزانية المستهدفة: ${budget.isEmpty ? 'يرجى توضيح الأسعار المتاحة' : '$budget $_currency'}
${contact.isEmpty ? '' : '- وسيلة التواصل التي سنستخدمها: $contact'}

يرجى إرسال السعر التفصيلي، والحد الأدنى للطلب، ومدة التجهيز والتسليم، وشروط الدفع والضمان، ومدة صلاحية العرض. يرجى توضيح أي رسوم إضافية.

شكراً لكم.
'''.trim();
  }

  Future<void> _copyDraft() async {
    final draft = _draft;
    if (draft == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: draft));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر النسخ؛ يمكنك تحديد نص المسودة ونسخه يدوياً.')),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ مسودة طلب عرض السعر. لم يتم إرسالها لأي جهة.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب عرض سعر من مورد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: const Text(
              'أدخل تفاصيل طلبك لتجهيز مسودة واضحة يمكنك مراجعتها وتعديلها ثم نسخها. لن يتم التواصل مع أي مورد تلقائياً.',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _targetController,
            maxLength: 200,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'المنصة أو الجهة المستهدفة (اختياري)',
              hintText: 'مثال: Alibaba.com — ليس تأكيداً لهوية المورد',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _scheduleSave(),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _productController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'المنتج أو الخدمة *',
                    hintText: 'مثال: أقمشة قطنية أو معدات تعبئة',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  onChanged: (_) => _scheduleSave(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب اسم المنتج أو الخدمة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الكمية المطلوبة *',
                    hintText: 'مثال: 500 قطعة',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  onChanged: (_) => _scheduleSave(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الكمية المطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'مدينة وبلد التسليم *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  onChanged: (_) => _scheduleSave(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'حدد وجهة التسليم'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specificationsController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1500,
                  onChanged: (_) => _scheduleSave(),
                  decoration: const InputDecoration(
                    labelText: 'المواصفات المطلوبة (اختياري)',
                    hintText: 'المقاس، المادة، الجودة، الموديل، الشهادات...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _delivery,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التسليم',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'شحن إلى العنوان',
                      child: Text('شحن إلى العنوان'),
                    ),
                    DropdownMenuItem(
                      value: 'استلام من المورد',
                      child: Text('استلام من المورد'),
                    ),
                    DropdownMenuItem(
                      value: 'يُحدّد لاحقاً',
                      child: Text('يُحدّد لاحقاً'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _delivery = value);
                    _scheduleSave();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _budgetController,
                        maxLength: 50,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _scheduleSave(),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final amount = double.tryParse(raw.replaceAll(',', '').replaceAll(' ', ''));
                          if (amount == null || !amount.isFinite || amount < 0) {
                            return 'أدخل ميزانية رقمية غير سالبة';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'الميزانية (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          labelText: 'العملة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                          DropdownMenuItem(value: 'KES', child: Text('KES')),
                          DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _currency = value);
                          _scheduleSave();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  maxLength: 200,
                  onChanged: (_) => _scheduleSave(),
                  decoration: const InputDecoration(
                    labelText: 'وسيلة التواصل التي ستستخدمها (اختياري)',
                    hintText: 'بريد عمل أو رقم هاتف مخصص',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _draft = _buildDraft());
                    _scheduleSave();
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('إنشاء مسودة طلب السعر'),
                ),
              ],
            ),
          ),
          if (_draft != null) ...[
            const SizedBox(height: 24),
            Text('راجع المسودة', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(_draft!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyDraft,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ المسودة'),
            ),
            const SizedBox(height: 8),
            const Text(
              'قبل الإرسال، تحقق من هوية المورد وسجله وشروط الدفع والشحن. لا ترسل مستندات حساسة أو دفعات قبل التحقق.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
