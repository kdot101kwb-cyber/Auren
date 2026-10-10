import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auren_supplier_rfq_draft_screen.dart';

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
  Timer? _saveTimer;
  Future<void> _localWriteQueue = Future<void>.value();
  StreamSubscription<User?>? _authSubscription;
  String? _observedUserId;
  int _loadGeneration = 0;
  String _status = 'جارٍ تحميل بيانات الصفقة…';

  String get _storageKey {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'auren_trade_deal_v1_$userId';
  }

  @override
  void initState() {
    super.initState();
    _observedUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadDraft();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _observedUserId) return;
      _observedUserId = user?.uid;
      _saveTimer?.cancel();
      // Remove the previous account's values before loading the new identity.
      _product.clear();
      _counterparty.clear();
      _quantity.clear();
      _value.clear();
      _notes.clear();
      setState(() {
        _loaded = false;
        _stage = 0;
        _currency = 'USD';
        _status = 'تم تغيير الحساب؛ جارٍ تحميل مسودته…';
      });
      _loadDraft();
    });
  }

  Future<void> _loadDraft() async {
    final loadGeneration = ++_loadGeneration;
    // Bind this load to the identity present when it starts. If auth changes
    // while Firestore is responding, never apply the previous user's draft.
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final localStorageKey = 'auren_trade_deal_v1_${userId ?? 'guest'}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(localStorageKey);
      if (!mounted || loadGeneration != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != userId) return;
      if (values != null && values.length >= 8) {
        _applyValues(values);
      }

      if (user != null) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('trade_deals')
              .doc('active_draft')
              .get();
          if (!mounted || loadGeneration != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != userId) return;
          if (snapshot.exists) {
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
            // Cloud data is already loaded; a failed local mirror must not
            // turn a successful load into a misleading load failure.
            try {
              await _persistLocalSilently(storageKey: localStorageKey);
            } catch (_) {
              // Keep the cloud-backed draft usable for this session.
            }
            return;
          }
        } catch (_) {
          // Keep the local draft available if cloud access is unavailable.
        }
      }

      if (!mounted || loadGeneration != _loadGeneration || FirebaseAuth.instance.currentUser?.uid != userId) return;
      setState(() {
        _loaded = true;
        _status = values == null
            ? (user == null
                ? 'لا توجد مسودة محفوظة بعد. سجّل الدخول للمزامنة مع حسابك.'
                : 'لا توجد مسودة سحابية؛ يمكنك حفظ المسودة الحالية في حسابك.')
            : 'تم تحميل المسودة المحفوظة على هذا الجهاز.';
      });
    } catch (_) {
      if (mounted &&
          loadGeneration == _loadGeneration &&
          FirebaseAuth.instance.currentUser?.uid == userId) {
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

  List<String> _draftValues() => <String>[
        _product.text,
        _counterparty.text,
        _quantity.text,
        _value.text,
        _notes.text,
        _currency,
        '$_stage',
        DateTime.now().toIso8601String(),
      ];

  Future<void> _persistLocalSilently({
    String? storageKey,
    List<String>? draftValues,
  }) async {
    // Capture both the account key and immutable snapshot before queuing.
    final key = storageKey ?? _storageKey;
    final values = List<String>.from(draftValues ?? _draftValues());
    final write = _localWriteQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, values);
    });
    _localWriteQueue = write.catchError((Object _) {});
    await write;
  }

  void _saveDraft() {
    if (!_loaded) return;
    // Debounce rapid keystrokes so overlapping writes cannot restore an older
    // snapshot after a newer edit.
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _writeDraft);
  }

  Future<void> _writeDraft() async {
    if (!_loaded) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final storageKey = 'auren_trade_deal_v1_${userId ?? 'guest'}';
    final values = _draftValues();
    try {
      // Serialize writes: a slower earlier platform write must not finish
      // after and overwrite a newer snapshot.
      final write = _localWriteQueue.then((_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(storageKey, values);
      });
      _localWriteQueue = write.catchError((Object _) {});
      await write;
      if (mounted && FirebaseAuth.instance.currentUser?.uid == userId) {
        setState(() => _status = 'تم حفظ المسودة على هذا الجهاز.');
      }
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == userId) {
        setState(() => _status = 'تعذر حفظ المسودة؛ انسخ الملخص للاحتفاظ به.');
      }
    }
  }

  bool _hasValidEstimatedValue() {
    final raw = _value.text.trim();
    if (raw.isEmpty) return true;
    final normalized = raw.replaceAll(',', '').replaceAll(' ', '');
    final amount = double.tryParse(normalized);
    return amount != null && amount.isFinite && amount >= 0;
  }

  Future<void> _saveToAccount() async {
    _saveTimer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    final localStorageKey = _storageKey;
    final draftValues = _draftValues();
    if (user == null) {
      setState(() => _status = 'سجّل الدخول أولاً لحفظ الصفقة في حسابك. المسودة المحلية ما زالت متاحة.');
      return;
    }
    if (_product.text.trim().isEmpty) {
      setState(() => _status = 'أدخل المنتج أو الخدمة قبل الحفظ في حسابك.');
      return;
    }
    if (!_hasValidEstimatedValue()) {
      setState(() => _status = 'قيمة الصفقة يجب أن تكون رقماً صفرياً أو موجباً، ويمكن استخدام الفاصلة للفصل بين الآلاف.');
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
        'product': draftValues[0].trim(),
        'counterparty': draftValues[1].trim(),
        'quantity': draftValues[2].trim(),
        'estimatedValue': draftValues[3].trim(),
        'currency': draftValues[5],
        'notes': draftValues[4].trim(),
        'stage': int.tryParse(draftValues[6]) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      var localMirrorSaved = true;
      try {
        await _persistLocalSilently(
          storageKey: localStorageKey,
          draftValues: draftValues,
        );
      } catch (_) {
        localMirrorSaved = false;
      }
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() => _status = localMirrorSaved
            ? 'تم حفظ مسودة الصفقة في حسابك وعلى هذا الجهاز.'
            : 'تم حفظ الصفقة في حسابك، لكن تعذرت مزامنة نسخة الجهاز.');
      }
    } on FirebaseException catch (error) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() => _status = error.code == 'permission-denied'
            ? 'رفضت قواعد Firestore الحفظ؛ تأكد من نشر قواعد الأمان الجديدة.'
            : 'تعذر الحفظ السحابي (${error.code})؛ بيانات الجهاز لم تُحذف.');
      }
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() => _status = 'تعذر الحفظ السحابي؛ بيانات الجهاز لم تُحذف.');
      }
    }
  }

  Future<void> _clearDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح مسودة الصفقة؟'),
        content: const Text(
          'سيتم حذف المسودة المحلية، ومحاولة حذف النسخة المحفوظة في حسابك إن كنت مسجلاً للدخول. لا يمكن التراجع عن الحذف المحلي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح المسودة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _saveTimer?.cancel();
    // Keep the delete bound to the identity that initiated the action.
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final localStorageKey = 'auren_trade_deal_v1_${userId ?? 'guest'}';
    try {
      // Wait for any in-flight autosave before removing the key, otherwise
      // an earlier write could recreate the draft immediately after clearing.
      final clearLocal = _localWriteQueue.then((_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(localStorageKey);
      });
      _localWriteQueue = clearLocal.catchError((Object _) {});
      await clearLocal;

      var cloudDraftCleared = true;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('trade_deals')
              .doc('active_draft')
              .delete();
        } catch (_) {
          // Keep the local clear, but never claim the cloud copy was removed.
          cloudDraftCleared = false;
        }
      }

      // A slow clear from account A must not erase account B's visible form.
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != userId) return;
      _product.clear();
      _counterparty.clear();
      _quantity.clear();
      _value.clear();
      _notes.clear();
      setState(() {
        _stage = 0;
        _currency = 'USD';
        _status = cloudDraftCleared
            ? 'تم مسح المسودة من هذا الجهاز${user == null ? '.' : ' وحسابك.'}'
            : 'تم مسح المسودة من الجهاز، لكن تعذر حذف النسخة السحابية. تحقق من الاتصال والصلاحيات ثم أعد المحاولة.';
      });
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == userId) {
        setState(() => _status = 'تعذر مسح المسودة المحلية بالكامل.');
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loadGeneration++;
    _saveTimer?.cancel();
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
            maxLength: 200,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'المنتج أو الخدمة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _counterparty,
            maxLength: 200,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              labelText: 'اسم المورد أو المشتري (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            maxLength: 100,
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
                  maxLength: 50,
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
                  _saveDraft();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLength: 3000,
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AurenSupplierRfqDraftScreen(
                    initialSupplier: _counterparty.text.trim().isEmpty
                        ? null
                        : _counterparty.text.trim(),
                    initialProduct: _product.text.trim(),
                    initialQuantity: _quantity.text.trim(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('إنشاء طلب عرض سعر من بيانات الصفقة'),
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
