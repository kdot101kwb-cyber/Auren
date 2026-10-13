import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/supplier_offer_comparison_logic.dart';
import '../domain/supplier_ranking_logic.dart';
import 'auren_supplier_rfq_draft_screen.dart';

/// Local, account-scoped-on-device comparison of supplier quotes.
/// It does not verify suppliers or send external messages.
class AurenSupplierOfferComparisonScreen extends StatefulWidget {
  const AurenSupplierOfferComparisonScreen({
    super.key,
    this.auth,
    this.firestore,
    this.initialProduct,
    this.initialQuantity,
    this.initialDestination,
    this.initialBudget,
    this.initialCurrency,
  });

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final String? initialProduct;
  final String? initialQuantity;
  final String? initialDestination;
  final String? initialBudget;
  final String? initialCurrency;

  @override
  State<AurenSupplierOfferComparisonScreen> createState() =>
      _AurenSupplierOfferComparisonScreenState();
}

class _AurenSupplierOfferComparisonScreenState
    extends State<AurenSupplierOfferComparisonScreen> {
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;
  static const _statuses = <String, String>{
    'received': 'وصل العرض',
    'verify': 'بحاجة للتحقق',
    'shortlist': 'ضمن القائمة المختصرة',
    'accepted': 'اختير مبدئياً',
    'rejected': 'مرفوض',
  };

  List<_Offer> _offers = [];
  bool _loading = true;
  String _filterStatus = 'all';
  String _filterValidity = 'all';
  String? _selectedRankingCurrency;
  String? _budgetCurrency;
  final _rankingBudgetController = TextEditingController();
  final _rankingLeadTimeController = TextEditingController();
  final _rankingMinimumOrderController = TextEditingController();
  String _message = 'جارٍ تحميل العروض…';
  StreamSubscription<User?>? _authSubscription;
  String? _observedUid;
  int _loadGeneration = 0;
  Future<void> _writeQueue = Future<void>.value();
  bool _cloudBusy = false;

  @override
  void initState() {
    super.initState();
    _rankingBudgetController.text = widget.initialBudget?.trim() ?? '';
    final requestedQuantity = widget.initialQuantity?.trim() ?? '';
    if (requestedQuantity.isNotEmpty && _parseMoq(requestedQuantity) != null) {
      _rankingMinimumOrderController.text = requestedQuantity;
    }
    _selectedRankingCurrency = widget.initialCurrency?.trim().toUpperCase();
    _budgetCurrency = _rankingBudgetController.text.isEmpty
        ? null
        : widget.initialCurrency?.trim().toUpperCase();
    _observedUid = _auth.currentUser?.uid;
    _load();
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _observedUid) return;
      _observedUid = user?.uid;
      ++_loadGeneration;
      setState(() {
        _offers = [];
        _loading = true;
        _message = 'تغير الحساب؛ جارٍ تحميل عروضه المحلية…';
      });
      _load();
    });
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final uid = _auth.currentUser?.uid;
    final key = 'auren_supplier_offers_v1_${uid ?? 'guest'}';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || generation != _loadGeneration || _auth.currentUser?.uid != uid) return;
      final raw = prefs.getString(key);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Stored supplier offers must be a list.');
      }
      if (decoded.length > 10) {
        throw const FormatException('Stored supplier offers exceed the limit.');
      }
      if (decoded.any((item) => item is! Map)) {
        throw const FormatException('Stored supplier offer record is malformed.');
      }
      const localOfferKeys = {
        'id', 'supplier', 'price', 'currency', 'shipping', 'moq',
        'leadTime', 'payment', 'validity', 'notes', 'status', 'receivedAt',
      };
      final items = decoded.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map.keys.toSet().difference(localOfferKeys).isNotEmpty ||
            !map.keys.toSet().containsAll(localOfferKeys) ||
            map.values.any((value) => value is! String)) {
          throw const FormatException('Stored supplier offer fields are malformed.');
        }
        return _Offer.fromJson(map);
      }).toList();
      final validationError = _cloudValidationError(items);
      if (validationError != null) {
        throw const FormatException('Stored supplier offer values are invalid.');
      }
      if (!mounted || generation != _loadGeneration || _auth.currentUser?.uid != uid) return;
      setState(() {
        _offers = items;
        _loading = false;
        _message = items.isEmpty ? 'أضف عروضاً استلمتها فعلياً لمقارنتها.' : 'تم تحميل ${items.length} عروض من هذا الجهاز.';
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration && _auth.currentUser?.uid == uid) {
        setState(() { _loading = false; _message = 'تعذر قراءة المسودة المحلية؛ يمكنك إضافة عروض جديدة.'; });
      }
    }
  }

  Future<void> _persist({String? expectedUid}) async {
    final uid = _auth.currentUser?.uid;
    // Cloud restore must never persist the previous account's data under a
    // newly active account if auth changes between restore and local save.
    if (expectedUid != null && uid != expectedUid) return;
    final key = 'auren_supplier_offers_v1_${uid ?? 'guest'}';
    final snapshot = jsonEncode(_offers.map((o) => o.toJson()).toList());
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_auth.currentUser?.uid != uid) return;
      final write = _writeQueue.then((_) async {
        if (_auth.currentUser?.uid != uid) return;
        await prefs.setString(key, snapshot);
      });
      _writeQueue = write.catchError((Object _) {});
      await write;
      if (mounted && _auth.currentUser?.uid == uid) {
        setState(() => _message = 'تم حفظ العروض على هذا الجهاز.');
      }
    } catch (_) {
      if (mounted && _auth.currentUser?.uid == uid) {
        setState(() => _message = 'تعذر حفظ العروض محلياً.');
      }
    }
  }

  double? _parseNonNegativeAmount(String value) =>
      SupplierOfferComparisonLogic.parseNonNegativeAmount(value);

  String? _cloudValidationError([List<_Offer>? candidates]) {
    final offers = candidates ?? _offers;
    if (offers.length > 10) return 'لا يمكن حفظ أكثر من 10 عروض.';
    const currencies = {'USD', 'EUR', 'SDG', 'KES', 'AED', 'NGN'};
    const statuses = {'received', 'verify', 'shortlist', 'accepted', 'rejected'};
    final seenIds = <String>{};
    for (var i = 0; i < offers.length; i++) {
      final offer = offers[i];
      final receivedAt = DateTime.tryParse(offer.receivedAt);
      if (offer.id.isEmpty || offer.id.length > 40 ||
          !seenIds.add(offer.id) || receivedAt == null ||
          offer.supplier.trim().isEmpty || offer.supplier.length > 200 ||
          offer.price.isEmpty || offer.price.length > 50 ||
          _parseNonNegativeAmount(offer.price) == null ||
          offer.shipping.length > 50 ||
          (offer.shipping.isNotEmpty && _parseNonNegativeAmount(offer.shipping) == null) ||
          offer.moq.length > 100 || offer.leadTime.length > 100 ||
          offer.payment.length > 300 || offer.validity.length > 100 ||
          offer.notes.length > 500 ||
          !currencies.contains(offer.currency) ||
          !statuses.contains(offer.status) || offer.receivedAt.isEmpty ||
          offer.receivedAt.length > 40) {
        return 'العرض رقم ${i + 1} يحتوي بيانات غير صالحة. تأكد من السعر والشحن والعملة والحقول المطلوبة.';
      }
    }
    return null;
  }

  Future<void> _saveToAccount() async {
    final user = _auth.currentUser;
    if (user == null) { _snack('سجّل الدخول أولاً لحفظ العروض في حسابك.'); return; }
    final validationError = _cloudValidationError();
    if (validationError != null) { _snack(validationError); return; }
    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد حفظ العروض'),
        content: const Text('سيستبدل هذا النسخة السحابية الحالية إن وُجدت. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('متابعة')),
        ],
      ),
    );
    if (shouldReplace != true || !mounted || _auth.currentUser?.uid != user.uid) return;
    if (validationError != null) { _snack(validationError); return; }
    if (_cloudBusy) return;
    setState(() { _cloudBusy = true; _message = 'جارٍ حفظ العروض في حسابك…'; });
    try {
      await _firestore.collection('users').doc(user.uid)
          .collection('supplier_offer_comparisons').doc('active_draft').set({
        'ownerId': user.uid,
        'offers': _offers.map((offer) => offer.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted || _auth.currentUser?.uid != user.uid) return;
      setState(() => _message = 'تم حفظ العروض في حسابك.');
      _snack('تم حفظ العروض في حسابك.');
    } on FirebaseException catch (error) {
      if (mounted && _auth.currentUser?.uid == user.uid) {
        setState(() => _message = 'تعذر الحفظ السحابي: ' + error.code);
        _snack('تعذر الحفظ السحابي؛ تحقق من قواعد Firestore والاتصال.');
      }
    } catch (_) {
      if (mounted && _auth.currentUser?.uid == user.uid) setState(() => _message = 'تعذر الحفظ السحابي.');
    } finally {
      if (mounted) setState(() => _cloudBusy = false);
    }
  }

  Future<void> _loadFromAccount() async {
    final user = _auth.currentUser;
    if (user == null) { _snack('سجّل الدخول أولاً لاستعادة عروض حسابك.'); return; }
    if (_cloudBusy) return;
    if (_offers.isNotEmpty) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('تأكيد استعادة العروض'),
          content: const Text('سيستبدل هذا عروضك المحلية الحالية بالعروض المحفوظة في الحساب. هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('استعادة')),
          ],
        ),
      );
      if (shouldReplace != true || !mounted || _auth.currentUser?.uid != user.uid) return;
    }
    setState(() { _cloudBusy = true; _message = 'جارٍ استعادة عروض الحساب…'; });
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid)
          .collection('supplier_offer_comparisons').doc('active_draft').get();
      if (!mounted || _auth.currentUser?.uid != user.uid) return;
      final data = snapshot.data();
      final rawOffers = data?['offers'];
      if (!snapshot.exists || data?['ownerId'] != user.uid || rawOffers is! List) {
        setState(() => _message = 'لا توجد نسخة سحابية صالحة لاستعادتها.');
        return;
      }
      if (rawOffers.length > 10) {
        setState(() => _message = 'نسخة الحساب تتجاوز الحد المسموح؛ لم يتم استبدال عروضك المحلية.');
        return;
      }
      if (rawOffers.any((item) => item is! Map)) {
        setState(() => _message = 'نسخة الحساب تحتوي سجلات تالفة؛ احتفظنا بالعروض المحلية.');
        _snack('تعذر استعادة النسخة لأن بعض سجلات العروض غير صالحة.');
        return;
      }
      const cloudOfferKeys = {
        'id', 'supplier', 'price', 'currency', 'shipping', 'moq',
        'leadTime', 'payment', 'validity', 'notes', 'status', 'receivedAt',
      };
      for (final item in rawOffers) {
        final map = Map<String, dynamic>.from(item as Map);
        if (map.keys.toSet().difference(cloudOfferKeys).isNotEmpty ||
            !map.keys.toSet().containsAll(cloudOfferKeys) ||
            map.values.any((value) => value is! String)) {
          setState(() => _message = 'نسخة الحساب تحتوي حقولاً غير صالحة؛ احتفظنا بالعروض المحلية.');
          _snack('تعذر استعادة النسخة لأن بنية أحد العروض غير صالحة.');
          return;
        }
      }
      final restored = rawOffers
          .map((item) => _Offer.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      final validationError = _cloudValidationError(restored);
      if (validationError != null) {
        setState(() => _message = 'تعذر استعادة النسخة: تحتوي بيانات غير صالحة.');
        _snack(validationError);
        return;
      }
      setState(() => _offers = restored);
      await _persist(expectedUid: user.uid);
      if (!mounted || _auth.currentUser?.uid != user.uid) return;
      setState(() => _message = 'تم استعادة ' + restored.length.toString() + ' عروض من حسابك.');
    } on FirebaseException catch (error) {
      if (mounted && _auth.currentUser?.uid == user.uid) setState(() => _message = 'تعذرت الاستعادة: ' + error.code);
    } catch (_) {
      if (mounted && _auth.currentUser?.uid == user.uid) setState(() => _message = 'تعذرت استعادة العروض السحابية.');
    } finally {
      if (mounted) setState(() => _cloudBusy = false);
    }
  }

  Future<void> _add() async {
    if (_offers.length >= 10) {
      _snack('الحد الأقصى 10 عروض في هذه المسودة.');
      return;
    }
    final offer = await showDialog<_Offer>(context: context, builder: (_) => _OfferDialog());
    if (offer == null || !mounted) return;
    setState(() => _offers = [..._offers, offer]);
    await _persist();
  }

  Future<void> _edit(_Offer offer) async {
    final updated = await showDialog<_Offer>(
      context: context,
      builder: (_) => _OfferDialog(initialOffer: offer),
    );
    if (updated == null || !mounted) return;
    setState(() => _offers = _offers.map((item) => item.id == offer.id ? updated : item).toList());
    await _persist();
  }

  Future<void> _setStatus(_Offer offer, String? status) async {
    if (status == null) return;
    setState(() => _offers = _offers.map((o) => o.id == offer.id ? o.copyWith(status: status) : o).toList());
    await _persist();
  }

  Future<void> _delete(_Offer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العرض؟'),
        content: Text('سيُحذف عرض ${offer.supplier} من المسودة المحلية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _offers = _offers.where((o) => o.id != offer.id).toList());
    await _persist();
  }

  String? _validityNotice(String validity) {
    final days = SupplierOfferComparisonLogic.daysUntilValidity(validity);
    if (days == null) return null;
    if (days < 0) return 'انتهت صلاحية العرض منذ ${-days} يوم';
    if (days == 0) return 'تنتهي صلاحية العرض اليوم';
    if (days <= 7) return 'تنتهي صلاحية العرض خلال ${days} يوم';
    return 'تاريخ الانتهاء المسجل: ${validity.trim()}';
  }

  Color _validityColor(String validity) {
    final days = SupplierOfferComparisonLogic.daysUntilValidity(validity);
    if (days == null) return Colors.grey;
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.deepOrange;
    return Colors.green;
  }

  Future<void> _copySummary(List<_Offer> offers) async {
    final lines = <String>[
      'ملخص مقارنة عروض الموردين',
      'ملاحظة: بيانات مدخلة يدوياً ولم يتم التحقق من الموردين.',
      ...offers.map((offer) {
        final total = _total(offer);
        return [
          'المورد: ${offer.supplier}',
          'السعر: ${offer.price} ${offer.currency}',
          'الشحن والرسوم: ${offer.shipping.isEmpty ? 'غير معروف' : '${offer.shipping} ${offer.currency}'}',
          'الإجمالي التقديري: ${total == null ? 'غير مكتمل — الشحن غير معروف أو البيانات غير صالحة' : '${total.toStringAsFixed(2)} ${offer.currency}'}',
          'الحالة: ${_statuses[offer.status] ?? offer.status}',
          'صلاحية العرض: ${offer.validity.isEmpty ? 'غير محددة' : offer.validity}',
          if (_validityNotice(offer.validity) != null) _validityNotice(offer.validity)!,
          'شروط الدفع: ${offer.payment.isEmpty ? 'غير محددة' : offer.payment}',
          'ملاحظات: ${offer.notes.isEmpty ? 'لا توجد' : offer.notes}',
          '',
        ].join('\n');
      }),
    ];
    try {
      await Clipboard.setData(ClipboardData(text: lines.join('\n')));
      if (mounted) _snack('تم نسخ ملخص العروض إلى الحافظة.');
    } catch (_) {
      if (mounted) _snack('تعذر نسخ الملخص؛ حاول مرة أخرى.');
    }
  }

  Future<void> _copyCsv(List<_Offer> offers) async {
    final rows = <String>[
      SupplierOfferComparisonLogic.csvRow([
        'Supplier',
        'Price',
        'Currency',
        'Shipping and fees',
        'Estimated total',
        'Status',
        'Validity date',
        'Validity warning',
        'Minimum order',
        'Lead time',
        'Payment terms',
        'Notes',
        'Recorded at',
      ]),
      ...offers.map((offer) {
        final total = _total(offer);
        return SupplierOfferComparisonLogic.csvRow([
          offer.supplier,
          offer.price,
          offer.currency,
          offer.shipping,
          total == null ? '' : total.toStringAsFixed(2),
          _statuses[offer.status] ?? offer.status,
          offer.validity,
          _validityNotice(offer.validity) ?? '',
          offer.moq,
          offer.leadTime,
          offer.payment,
          offer.notes,
          offer.receivedAt,
        ]);
      }),
    ];
    try {
      await Clipboard.setData(ClipboardData(text: rows.join('\n')));
      if (mounted) _snack('تم نسخ CSV؛ يمكنك لصقه في جدول بيانات.');
    } catch (_) {
      if (mounted) _snack('تعذر نسخ ملف CSV؛ حاول مرة أخرى.');
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  double? _total(_Offer offer) =>
      SupplierOfferComparisonLogic.total(offer.price, offer.shipping);

  bool _isRankable(_Offer offer) =>
      offer.status != 'rejected' &&
      SupplierOfferComparisonLogic.validityCategory(offer.validity) != 'expired';

  bool _isLowest(_Offer candidate) =>
      _isRankable(candidate) && SupplierOfferComparisonLogic.isLowest(
        currency: candidate.currency,
        price: candidate.price,
        shipping: candidate.shipping,
        offers: _offers.where(_isRankable).map((offer) => <String, String>{
          'currency': offer.currency,
          'price': offer.price,
          'shipping': offer.shipping,
        }),
      );

  String _normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var normalized = value;
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return normalized;
  }

  double? _parseOptionalQuantity(String value) {
    final raw = _normalizeDigits(value).trim();
    if (raw.isEmpty) return null;
    return _parseNonNegativeAmount(raw);
  }

  double? _parseMoq(String value) {
    final raw = _normalizeDigits(value).trim();
    if (raw.isEmpty) return null;
    final match = RegExp(r'^([0-9][0-9,]*(?:\.[0-9]+)?)(?:\s|$)').firstMatch(raw);
    return match == null ? null : _parseNonNegativeAmount(match.group(1)!);
  }

  int? _parseOptionalDays(String value) {
    final raw = _normalizeDigits(value).trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final pattern = r'^([0-9]+)(d|day|days|wk|wks|week|weeks|يوم|أيام|ايام|أسبوع|أسابيع|اسبوع|اسابيع)?' + r'$';
    final match = RegExp(pattern).firstMatch(raw);
    if (match == null) return null;
    final amount = int.tryParse(match.group(1)!);
    if (amount == null) return null;
    final unit = match.group(2);
    final isWeeks = unit == 'wk' || unit == 'wks' ||
        unit == 'week' || unit == 'weeks' ||
        unit == 'أسبوع' || unit == 'أسابيع' ||
        unit == 'اسبوع' || unit == 'اسابيع';
    if (amount > 100000) return null;
    return isWeeks ? amount * 7 : amount;
  }

  List<SupplierRankingResult> _rankedOffers(String currency) =>
      SupplierRankingLogic.rank(
        _offers.where(_isRankable).map((offer) => SupplierRankingCandidate(
          id: offer.id, name: offer.supplier, currency: offer.currency,
          price: _parseNonNegativeAmount(offer.price),
          shipping: _parseNonNegativeAmount(offer.shipping),
          leadTimeDays: _parseOptionalDays(offer.leadTime),
          minimumOrder: _parseMoq(offer.moq),
          // No evidence workflow or rating field exists here; never infer them.
          verified: false, rating: null,
        )),
        currency: currency,
        maxBudget: _budgetCurrency == currency
            ? _parseOptionalQuantity(_rankingBudgetController.text)
            : null,
        maxLeadTimeDays: _parseOptionalDays(_rankingLeadTimeController.text),
        maxMinimumOrder: _parseMoq(_rankingMinimumOrderController.text),
      );

  List<_Offer> get _sorted {
    final result = List<_Offer>.from(_offers);
    result.sort((a, b) => SupplierOfferComparisonLogic.compare(
          aCurrency: a.currency,
          aSupplier: a.supplier,
          aPrice: a.price,
          aShipping: a.shipping,
          bCurrency: b.currency,
          bSupplier: b.supplier,
          bPrice: b.price,
          bShipping: b.shipping,
        ));
    return result;
  }

  @override
  void dispose() {
    _loadGeneration++;
    _authSubscription?.cancel();
    _rankingBudgetController.dispose();
    _rankingLeadTimeController.dispose();
    _rankingMinimumOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _offers.map((o) => o.currency).toSet();
    final filteredOffers = _sorted.where((offer) {
      final statusMatches = _filterStatus == 'all' || offer.status == _filterStatus;
      final validityMatches = _filterValidity == 'all' ||
          SupplierOfferComparisonLogic.validityCategory(offer.validity) == _filterValidity;
      return statusMatches && validityMatches;
    }).toList(growable: false);
    final duplicateSupplierKeys = SupplierOfferComparisonLogic.duplicateSupplierNames(
      _offers.map((offer) => offer.supplier),
    );
    final duplicateSupplierOfferCount = _offers.where((offer) =>
      duplicateSupplierKeys.contains(SupplierOfferComparisonLogic.normalizeSupplierName(offer.supplier)),
    ).length;
    final incompleteQuoteCount = _offers.where((offer) =>
      SupplierOfferComparisonLogic.missingDecisionFields(
        moq: offer.moq,
        leadTime: offer.leadTime,
        payment: offer.payment,
        validity: offer.validity,
      ).isNotEmpty,
    ).length;
    final expiredCount = _offers.where((o) => SupplierOfferComparisonLogic.validityCategory(o.validity) == 'expired').length;
    final expiringCount = _offers.where((o) {
      final category = SupplierOfferComparisonLogic.validityCategory(o.validity);
      return category == 'today' || category == 'soon';
    }).length;
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة عروض الموردين')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _add,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عرض'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('قارن قبل اتخاذ القرار', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('أدخل عروضاً استلمتها بنفسك. الترتيب حسب السعر والرسوم المسجلة وبالعملة نفسها فقط. لا يوجد تحويل عملات تلقائي أو تحقق من المورد.'),
                    const SizedBox(height: 8),
                    Text(_message, style: Theme.of(context).textTheme.bodySmall),
                    Wrap(spacing: 8, children: [
                      Chip(label: Text('${_offers.length}/10 عروض')),
                      Chip(label: Text('${_offers.where((o) => o.status == 'verify').length} بحاجة للتحقق')),
                      Chip(label: Text('${_offers.where((o) => o.status == 'shortlist').length} بالقائمة المختصرة')),
                      Chip(label: Text('$expiredCount عروض منتهية'), avatar: const Icon(Icons.error_outline, size: 18)),
                      Chip(label: Text('$expiringCount عروض قاربت على الانتهاء'), avatar: const Icon(Icons.schedule, size: 18)),
                      if (duplicateSupplierOfferCount > 0)
                        Chip(
                          label: Text('$duplicateSupplierOfferCount عروض بأسماء موردين مكررة'),
                          avatar: const Icon(Icons.content_copy_outlined, size: 18),
                        ),
                      if (incompleteQuoteCount > 0)
                        Chip(
                          label: Text('$incompleteQuoteCount عروض ناقصة الشروط'),
                          avatar: const Icon(Icons.rule_outlined, size: 18),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'تصفية العروض حسب الحالة',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('كل العروض')),
                        ..._statuses.entries.map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            )),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _filterStatus = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _filterValidity,
                      decoration: const InputDecoration(
                        labelText: 'تصفية حسب صلاحية العرض',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('كل الصلاحيات')),
                        DropdownMenuItem(value: 'expired', child: Text('منتهي الصلاحية')),
                        DropdownMenuItem(value: 'today', child: Text('ينتهي اليوم')),
                        DropdownMenuItem(value: 'soon', child: Text('ينتهي خلال 7 أيام')),
                        DropdownMenuItem(value: 'valid', child: Text('ساري لأكثر من 7 أيام')),
                        DropdownMenuItem(value: 'unknown', child: Text('تاريخ غير محدد أو نصي')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _filterValidity = value);
                      },
                    ),
                    if (currencies.length > 1)
                      const Text('توجد عملات مختلفة؛ لا تقارن أسعارها مباشرة.', style: TextStyle(color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: filteredOffers.isEmpty ? null : () => _copySummary(filteredOffers),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('نسخ ملخص العروض'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: filteredOffers.isEmpty ? null : () => _copyCsv(filteredOffers),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('نسخ CSV للجدول'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                        onPressed: _cloudBusy ? null : _saveToAccount,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('حفظ في حسابي'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _cloudBusy ? null : _loadFromAccount,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('استعادة من حسابي'),
                      ),
                    ]),
                  ]),
                )),
                if (_hasInitialRequestContext) _requestContextCard(),
                if (_offers.isNotEmpty) _rankingCard(),
                if (_offers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'عرض ${filteredOffers.length} من ${_offers.length} عروض',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_offers.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد عروض بعد. اضغط «إضافة عرض» لتسجيل أول عرض.')))
                else if (filteredOffers.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد عروض بالحالة المحددة. غيّر التصفية لعرض عروض أخرى.')))
                else
                  ...filteredOffers.map((offer) => _card(offer, isLowest: _isLowest(offer))),
                const SizedBox(height: 12),
                const Text('قبل الدفع: تحقق مستقلاً من تسجيل الشركة، وعينة المنتج، والمراجع التجارية، وشروط الدفع والشحن والتأمين والمستندات.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
    );
  }

  bool get _hasInitialRequestContext =>
      (widget.initialProduct?.trim().isNotEmpty ?? false) ||
      (widget.initialQuantity?.trim().isNotEmpty ?? false) ||
      (widget.initialDestination?.trim().isNotEmpty ?? false) ||
      (widget.initialBudget?.trim().isNotEmpty ?? false);

  Widget _requestContextCard() {
    final details = <String>[
      if (widget.initialProduct?.trim().isNotEmpty ?? false)
        'المنتج: ${widget.initialProduct!.trim()}',
      if (widget.initialQuantity?.trim().isNotEmpty ?? false)
        'الكمية: ${widget.initialQuantity!.trim()}',
      if (widget.initialDestination?.trim().isNotEmpty ?? false)
        'وجهة التسليم: ${widget.initialDestination!.trim()}',
      if (widget.initialBudget?.trim().isNotEmpty ?? false)
        'الميزانية المطلوبة: ${widget.initialBudget!.trim()} ${widget.initialCurrency?.trim().toUpperCase() ?? ''}'.trim(),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('احتياجك للمقارنة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'هذه بيانات طلبك كمرجع للمراجعة؛ لا تعني أن العروض تطابق مواصفات المنتج أو وجهة الشحن تلقائياً.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(detail),
            )),
          ],
        ),
      ),
    );
  }

  Widget _rankingCard() {
    final currencies = _offers.where(_isRankable)
        .map((offer) => offer.currency)
        .toSet()
        .toList()
      ..sort();
    if (currencies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('كل العروض مرفوضة أو منتهية.'),
        ),
      );
    }
    final currency = currencies.contains(_selectedRankingCurrency)
        ? _selectedRankingCurrency!
        : currencies.first;
    final ranked = _rankedOffers(currency);
    String reasonLabel(String key) => switch (key) {
      'competitive_total_cost' => 'تكلفة متقاربة',
      'lowest_comparable_total_cost' => 'أقل تكلفة قابلة للمقارنة',
      'meets_lead_time' => 'يلتزم بمدة التسليم',
      'within_budget' => 'داخل الميزانية',
      'meets_minimum_order' => 'يلائم الحد الأدنى للطلب',
      'marked_verified' => 'موسوم كمورد موثّق',
      'rating_available' => 'التقييم متوفر',
      _ => key,
    };
    String warningLabel(String key) => switch (key) {
      'missing_or_invalid_cost' => 'السعر أو الشحن ناقص/غير صالح',
      'missing_or_invalid_lead_time' => 'مدة التسليم غير محددة',
      'missing_or_invalid_minimum_order' => 'الحد الأدنى غير محدد',
      'supplier_not_verified' => 'لم يتم التحقق من المورد',
      'missing_or_invalid_rating' => 'لا يوجد تقييم موثوق',
      'over_budget_or_invalid_budget' => 'يتجاوز الميزانية أو الميزانية غير صالحة',
      'minimum_order_exceeds_requirement' => 'الحد الأدنى أعلى من المطلوب',
      'invalid_max_minimum_order_constraint' => 'شرط الحد الأقصى للطلب غير صالح',
      'invalid_max_lead_time_constraint' => 'شرط أقصى مدة التسليم غير صالح',
      _ => key,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ترتيب الموردين المبدئي',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'ترتيب إرشادي حسب البيانات المسجلة فقط؛ لا يعني توثيق المورد أو ضمان العرض.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rankingBudgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'الميزانية القصوى ($currency)',
                hintText: 'اختياري',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() => _budgetCurrency = currency),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rankingLeadTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أقصى مدة للتسليم بالأيام',
                hintText: 'اختياري',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rankingMinimumOrderController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: (widget.initialQuantity?.trim().isNotEmpty ?? false)
                    ? 'كمية طلبك / أقصى حد أدنى للطلب'
                    : 'أقصى حد أدنى للطلب',
                hintText: 'اختياري',
                helperText: (widget.initialQuantity?.trim().isNotEmpty ?? false)
                    ? 'يُستخدم الرقم لتفضيل العروض التي لا يتجاوز حدها الأدنى كمية طلبك.'
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if ((widget.initialQuantity?.trim().isNotEmpty ?? false) &&
                _parseMoq(widget.initialQuantity!) == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'تعذر قراءة كمية الطلب كرقم؛ لم تُستخدم لتصفية الحد الأدنى للطلب. أدخل الكمية رقمياً أدناه.',
                  style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                ),
              ),
            if ((_rankingBudgetController.text.trim().isNotEmpty &&
                    _parseOptionalQuantity(_rankingBudgetController.text) == null) ||
                (_rankingLeadTimeController.text.trim().isNotEmpty &&
                    _parseOptionalDays(_rankingLeadTimeController.text) == null) ||
                (_rankingMinimumOrderController.text.trim().isNotEmpty &&
                    _parseOptionalQuantity(_rankingMinimumOrderController.text) == null))
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'بعض شروط الترتيب غير صالحة وتم تجاهلها؛ أدخل أرقاماً موجبة أو صفراً.',
                  style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                ),
              ),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(
                labelText: 'عملة المقارنة',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: currencies.map((code) => DropdownMenuItem(
                value: code,
                child: Text(code),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRankingCurrency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            if (_rankingBudgetController.text.trim().isNotEmpty && _budgetCurrency != currency)
              Text(
                'الميزانية أُدخلت بعملة ${_budgetCurrency ?? 'غير محددة'} ولا تُطبَّق على $currency.',
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            if (ranked.isEmpty)
              const Text('لا توجد عروض بهذه العملة.')
            else
              ...ranked.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                final details = <String>[
                  ...result.reasons.map(reasonLabel),
                  ...result.warnings.map(warningLabel),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.candidate.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('${result.score.toStringAsFixed(0)}/100'),
                        ],
                      ),
                      if (result.candidate.totalCost != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 38, top: 3),
                          child: Text(
                            'الإجمالي: ${result.candidate.totalCost!.toStringAsFixed(2)} $currency',
                          ),
                        ),
                      if (details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 38, top: 3),
                          child: Text(
                            details.join(' • '),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _card(_Offer offer, {required bool isLowest}) {
    final total = _total(offer);
    final duplicateName = SupplierOfferComparisonLogic.duplicateSupplierNames(
      _offers.map((item) => item.supplier),
    ).contains(SupplierOfferComparisonLogic.normalizeSupplierName(offer.supplier));
    final missingFields = SupplierOfferComparisonLogic.missingDecisionFields(
      moq: offer.moq,
      leadTime: offer.leadTime,
      payment: offer.payment,
      validity: offer.validity,
    );
    const fieldLabels = <String, String>{
      'minimum_order': 'الحد الأدنى للطلب',
      'lead_time': 'مدة التسليم',
      'payment_terms': 'شروط الدفع',
      'validity': 'صلاحية العرض',
    };
    Widget detail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 125, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.storefront_outlined)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(offer.supplier, style: Theme.of(context).textTheme.titleMedium),
              Text(total == null ? (offer.shipping.isEmpty ? 'الإجمالي غير مكتمل — أدخل الشحن والرسوم أولاً' : 'التكلفة غير مكتملة') : 'الإجمالي التقديري: ${total.toStringAsFixed(2)} ${offer.currency}'),
              if (isLowest)
                Text('الأقل تكلفة ضمن ${offer.currency}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ])),
            IconButton(tooltip: 'تعديل العرض', onPressed: () => _edit(offer), icon: const Icon(Icons.edit_outlined)),
            IconButton(tooltip: 'حذف العرض', onPressed: () => _delete(offer), icon: const Icon(Icons.delete_outline)),
          ]),
          const Divider(),
          if (duplicateName)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.content_copy_outlined, color: Colors.deepOrange, size: 18),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'اسم هذا المورد مكرر في المسودة. تأكد أن العرضين من نفس الجهة قبل حذف أي منهما.',
                  style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                )),
              ]),
            ),
          if (missingFields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.rule_outlined, color: Colors.deepOrange, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  'معلومات ناقصة لاتخاذ القرار: ${missingFields.map((field) => fieldLabels[field] ?? field).join('، ')}',
                  style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
                )),
              ]),
            ),
          detail('تاريخ التسجيل', offer.receivedAt.length >= 10 ? offer.receivedAt.substring(0, 10) : offer.receivedAt),
          detail('السعر المسجل', '${offer.price} ${offer.currency}'),
          detail('الشحن والرسوم', offer.shipping.isEmpty ? 'غير معروف — لم يُدخل' : '${offer.shipping} ${offer.currency}'),
          detail('الحد الأدنى', offer.moq.isEmpty ? 'غير محدد' : offer.moq),
          detail('مدة التسليم', offer.leadTime.isEmpty ? 'غير محددة' : offer.leadTime),
          detail('شروط الدفع', offer.payment.isEmpty ? 'غير محددة' : offer.payment),
          detail('صلاحية العرض', offer.validity.isEmpty ? 'غير محددة' : offer.validity),
          if (_validityNotice(offer.validity) != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                _validityNotice(offer.validity)!,
                style: TextStyle(color: _validityColor(offer.validity), fontWeight: FontWeight.w600),
              ),
            ),
          if (offer.notes.isNotEmpty) detail('ملاحظات', offer.notes),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _statuses.containsKey(offer.status) ? offer.status : 'received',
            decoration: const InputDecoration(labelText: 'حالة العرض', border: OutlineInputBorder(), isDense: true),
            items: _statuses.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (value) => _setStatus(offer, value),
          ),
          if (offer.status == 'accepted') ...[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'اختيار مبدئي فقط؛ لا يعني عقداً أو إرسال أمر شراء.',
                style: TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AurenSupplierRfqDraftScreen(
                      initialSupplier: offer.supplier,
                      auth: widget.auth,
                      firestore: widget.firestore,
                    ),
                  ),
                ),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('إنشاء مسودة طلب سعر لهذا المورد'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Offer {
  const _Offer({required this.id, required this.supplier, required this.price, required this.currency, required this.shipping, required this.moq, required this.leadTime, required this.payment, required this.validity, required this.notes, required this.status, required this.receivedAt});
  final String id, supplier, price, currency, shipping, moq, leadTime, payment, validity, notes, status, receivedAt;
  _Offer copyWith({String? status}) => _Offer(id: id, supplier: supplier, price: price, currency: currency, shipping: shipping, moq: moq, leadTime: leadTime, payment: payment, validity: validity, notes: notes, status: status ?? this.status, receivedAt: receivedAt);
  Map<String, dynamic> toJson() => {'id': id, 'supplier': supplier, 'price': price, 'currency': currency, 'shipping': shipping, 'moq': moq, 'leadTime': leadTime, 'payment': payment, 'validity': validity, 'notes': notes, 'status': status, 'receivedAt': receivedAt};
  factory _Offer.fromJson(Map<String, dynamic> j) => _Offer(
    id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    supplier: j['supplier'] as String? ?? '', price: j['price'] as String? ?? '',
    currency: _currencies.contains(j['currency']) ? j['currency'] as String : 'USD',
    shipping: j['shipping'] as String? ?? '0', moq: j['moq'] as String? ?? '',
    leadTime: j['leadTime'] as String? ?? '', payment: j['payment'] as String? ?? '',
    validity: j['validity'] as String? ?? '', notes: j['notes'] as String? ?? '',
    receivedAt: j['receivedAt'] as String? ?? DateTime.now().toIso8601String(),
    status: _statuses.containsKey(j['status']) ? j['status'] as String : 'received',
  );
  static const _currencies = ['USD', 'EUR', 'SDG', 'KES', 'AED', 'NGN'];
  static const _statuses = {'received': 'وصل العرض', 'verify': 'بحاجة للتحقق', 'shortlist': 'ضمن القائمة المختصرة', 'accepted': 'اختير مبدئياً', 'rejected': 'مرفوض'};
}

class _OfferDialog extends StatefulWidget {
  const _OfferDialog({this.initialOffer});
  final _Offer? initialOffer;
  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  final _form = GlobalKey<FormState>();
  final _supplier = TextEditingController(), _price = TextEditingController(), _shipping = TextEditingController();
  final _moq = TextEditingController(), _lead = TextEditingController(), _payment = TextEditingController(), _validity = TextEditingController(), _notes = TextEditingController();
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    final offer = widget.initialOffer;
    if (offer == null) return;
    _supplier.text = offer.supplier;
    _price.text = offer.price;
    _shipping.text = offer.shipping;
    _moq.text = offer.moq;
    _lead.text = offer.leadTime;
    _payment.text = offer.payment;
    _validity.text = offer.validity;
    _notes.text = offer.notes;
    _currency = offer.currency;
  }

  @override
  void dispose() {
    for (final c in [_supplier, _price, _shipping, _moq, _lead, _payment, _validity, _notes]) { c.dispose(); }
    super.dispose();
  }

  String? _amount(String? value, {bool optional = false}) {
    final raw = value?.trim() ?? '';
    if (optional && raw.isEmpty) return null;
    if (raw.length > 50) return 'الرقم أطول من الحد المسموح';
    final validNumber = RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$');
    if (!validNumber.hasMatch(raw)) {
      return 'أدخل رقماً صحيحاً مثل 1200 أو 1,200.50';
    }
    final number = double.tryParse(raw.replaceAll(',', ''));
    return number == null || !number.isFinite || number < 0
        ? 'أدخل رقماً صفرياً أو موجباً'
        : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initialOffer == null ? 'تسجيل عرض مورد' : 'تعديل عرض المورد'),
    content: SizedBox(width: 460, child: Form(
      key: _form,
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _supplier, maxLength: 200, decoration: const InputDecoration(labelText: 'اسم المورد *'), validator: (v) => v == null || v.trim().isEmpty ? 'اسم المورد مطلوب' : null),
        TextFormField(controller: _price, maxLength: 50, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'السعر *'), validator: _amount),
        DropdownButtonFormField<String>(value: _currency, decoration: const InputDecoration(labelText: 'العملة'), items: _Offer._currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setState(() => _currency = v); }),
        TextFormField(controller: _shipping, maxLength: 50, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الشحن والرسوم (اختياري؛ اتركه فارغاً إذا غير معروف)'), validator: (v) => _amount(v, optional: true)),
        TextFormField(controller: _moq, maxLength: 100, decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب')),
        TextFormField(controller: _lead, maxLength: 100, decoration: const InputDecoration(labelText: 'مدة التجهيز/التسليم')),
        TextFormField(controller: _payment, maxLength: 300, decoration: const InputDecoration(labelText: 'شروط الدفع')),
        TextFormField(controller: _validity, maxLength: 100, decoration: const InputDecoration(labelText: 'صلاحية العرض (YYYY-MM-DD للتنبيه)'),),
        TextFormField(controller: _notes, maxLength: 500, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات / تحقق')),
      ])),
    )),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () {
        if (!_form.currentState!.validate()) return;
        Navigator.pop(context, _Offer(
          id: widget.initialOffer?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), supplier: _supplier.text.trim(),
          price: _price.text.trim(), currency: _currency, shipping: _shipping.text.trim(),
          moq: _moq.text.trim(), leadTime: _lead.text.trim(), payment: _payment.text.trim(),
          validity: _validity.text.trim(), notes: _notes.text.trim(), status: widget.initialOffer?.status ?? 'received', receivedAt: widget.initialOffer?.receivedAt ?? DateTime.now().toIso8601String(),
        ));
      }, child: const Text('حفظ العرض')),
    ],
  );
}
