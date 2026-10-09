import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'adaptive_profile_service.dart';
import 'profile_mode_service.dart';

enum AurenMatchKind { person, opportunity, business, product, content }

enum AurenMatchAction {
  open,
  contact,
  requestQuote,
  apply,
  addToCart,
  follow,
  save,
  watch,
}

class AurenMatchItem {
  final String id;
  final String title;
  final String subtitle;
  final AurenMatchKind kind;
  final int score;
  final List<String> reasons;
  final Map<String, dynamic> data;
  final AurenMatchAction action;
  final String actionLabel;
  final String actionReason;

  const AurenMatchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.score,
    required this.reasons,
    this.data = const {},
    this.action = AurenMatchAction.open,
    this.actionLabel = 'فتح',
    this.actionReason = 'افتح النتيجة لمتابعة الخطوة المناسبة.',
  });
}

/// Unified matching across people, opportunities, businesses, products and
/// public Pulse content. It converts natural-language intent into a
/// recommended next action instead of returning a passive search result.
class AurenMatchEverythingService {
  final FirebaseFirestore _db;
  final AurenAdaptiveProfileService _adaptive;

  AurenMatchEverythingService({
    FirebaseFirestore? db,
    AurenAdaptiveProfileService adaptive = const AurenAdaptiveProfileService(),
  })  : _db = db ?? FirebaseFirestore.instance,
        _adaptive = adaptive;

  Future<List<AurenMatchItem>> findMatches({
    required String uid,
    AurenProfileContext context = AurenProfileContext.unknown,
    String? intent,
    int limitPerKind = 8,
  }) async {
    final modeService = AurenProfileModeService(db: _db);
    final currentMode = await modeService.getActiveMode(uid);
    final profile = await modeService.get(uid, currentMode);
    final resolved = _adaptive.suggest(
      currentMode: currentMode,
      context: context,
      profile: profile,
      intent: intent,
    );
    final intentTerms = _intentTerms(intent);
    final normalizedIntent = _normalize(intent);
    final limit = _safeLimit(limitPerKind);
    final actionPlan = AurenIntentActionPlan.fromIntent(intent);
    final signals = AurenIntentSignals.fromIntent(intent);

    // These five reads are independent after the profile/mode context is resolved.
    // Run them concurrently to keep Match Everything latency bounded.
    final groups = await Future.wait<List<AurenMatchItem>>([
      _people(uid, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan, signals),
      _collectionMatches('opportunities', AurenMatchKind.opportunity, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan, signals),
      _collectionMatches('businesses', AurenMatchKind.business, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan, signals),
      _collectionMatches('products', AurenMatchKind.product, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan, signals),
      _collectionMatches('posts', AurenMatchKind.content, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan, signals),
      _supplierMatches(profile, limit, intentTerms, normalizedIntent, actionPlan, signals),
    ]);
    final results = <AurenMatchItem>[
      for (final group in groups) ...group,
    ];
    results.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return _actionPriority(b.action).compareTo(_actionPriority(a.action));
    });
    return results.take(limit * 5).toList();
  }

  Future<List<AurenMatchItem>> _people(
    String uid,
    AurenProfileModeData profile,
    AurenProfileMode mode,
    int limit,
    Set<String> intentTerms,
    String normalizedIntent,
    AurenIntentActionPlan plan,
    AurenIntentSignals signals,
  ) async {
    try {
      final snapshot = await _db.collectionGroup('profile_modes')
          .where('discoverable', isEqualTo: true)
          .limit(_candidateLimit(limit))
          .get();
      return snapshot.docs.where((doc) => doc.reference.parent.parent?.id != uid).map((doc) {
        final d = doc.data();
        final candidateMode = AurenProfileModeX.fromId(d['mode'] as String?);
        final text = _documentText(d);
        final action = plan.actionFor(AurenMatchKind.person);
        return AurenMatchItem(
          id: doc.reference.parent.parent?.id ?? doc.id,
          title: _string(d['headline'], 'AUREN member'),
          subtitle: _string(d['bio'], candidateMode?.label ?? 'Person'),
          kind: AurenMatchKind.person,
          score: _score(text, profile, candidateMode == mode, intentTerms, normalizedIntent, signals),
          reasons: _reasons(text, profile, candidateMode == mode, intentTerms, normalizedIntent, signals),
          data: d,
          action: action,
          actionLabel: plan.labelFor(action),
          actionReason: plan.reasonFor(action),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AurenMatchItem>> _collectionMatches(
    String collection,
    AurenMatchKind kind,
    AurenProfileModeData profile,
    AurenProfileMode mode,
    int limit,
    Set<String> intentTerms,
    String normalizedIntent,
    AurenIntentActionPlan plan,
    AurenIntentSignals signals,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collection);
      if (collection == 'businesses') {
        query = query.where('visibility', isEqualTo: 'public');
      } else if (collection == 'products') {
        query = query.where('status', isEqualTo: 'active');
      } else if (collection == 'opportunities') {
        query = query.where('status', isEqualTo: 'open');
      } else if (collection == 'posts') {
        query = query.where('visibility', isEqualTo: 'public');
      }
      final snapshot = await query.limit(_candidateLimit(limit)).get();
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final text = _documentText(d);
        final declaredMode = AurenProfileModeX.fromId(d['mode'] as String?);
        final modeMatch = declaredMode == mode;
        final action = plan.actionFor(kind);
        return AurenMatchItem(
          id: doc.id,
          title: _titleFor(kind, d),
          subtitle: _subtitleFor(kind, d),
          kind: kind,
          score: _score(text, profile, modeMatch, intentTerms, normalizedIntent, signals),
          reasons: _reasons(text, profile, modeMatch, intentTerms, normalizedIntent, signals),
          data: d,
          action: action,
          actionLabel: plan.labelFor(action),
          actionReason: plan.reasonFor(action),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Supplier records live in `auren_suppliers`, while the general business
  /// directory lives in `businesses`. Include real supplier records for explicit
  /// sourcing requests and attach the canonical supplier ID so the result opens
  /// the approval-gated contact/RFQ draft flow.
  Future<List<AurenMatchItem>> _supplierMatches(
    AurenProfileModeData profile,
    int limit,
    Set<String> intentTerms,
    String normalizedIntent,
    AurenIntentActionPlan plan,
    AurenIntentSignals signals,
  ) async {
    if (!signals.wantsSupplier &&
        !signals.wantsManufacturer &&
        !signals.wantsWholesale &&
        !signals.wantsExporter &&
        !signals.wantsImporter &&
        !signals.wantsInternationalTrade) {
      return const [];
    }

    try {
      final sourceCollections = <String>['auren_suppliers'];
      if (signals.wantsExporter || signals.wantsInternationalTrade) {
        sourceCollections.add('auren_exporters');
      }
      if (signals.wantsImporter || signals.wantsInternationalTrade) {
        sourceCollections.add('auren_importers');
      }
      if (signals.wantsManufacturer) sourceCollections.add('auren_manufacturers');
      final snapshots = await Future.wait(sourceCollections.map(
        (collection) => _db.collection(collection).limit(_candidateLimit(limit)).get(),
      ));
      final results = <AurenMatchItem>[];
      for (final doc in snapshots.expand((snapshot) => snapshot.docs)) {
        final raw = doc.data();
        final status = _string(raw['status'], 'active').toLowerCase();
        final visibility = _string(raw['visibility'], 'public').toLowerCase();
        if (!const {'active', 'open', 'verified'}.contains(status) ||
            !const {'public', 'listed'}.contains(visibility)) {
          continue;
        }

        final name = _string(
          raw['name'],
          _string(raw['companyName'], _string(raw['businessName'], 'Supplier')),
        );
        final normalizedData = <String, dynamic>{
          ...raw,
          'name': name,
          'businessType': _string(raw['businessType'],
              doc.reference.parent.id == 'auren_exporters' ? 'exporter' :
              doc.reference.parent.id == 'auren_importers' ? 'importer' :
              doc.reference.parent.id == 'auren_manufacturers' ? 'manufacturer' : 'supplier'),
          'tradeRole': doc.reference.parent.id == 'auren_exporters' ? 'exporter' :
              doc.reference.parent.id == 'auren_importers' ? 'importer' :
              doc.reference.parent.id == 'auren_manufacturers' ? 'manufacturer' :
              _string(raw['tradeRole'], 'supplier'),
          'searchText': [
            raw['searchText'],
            raw['category'],
            raw['type'],
            raw['products'],
            raw['productCategories'],
            raw['services'],
            raw['tags'],
            raw['city'],
            raw['country'],
            raw['countryCode'],
            raw['exportMarkets'],
            raw['marketsServed'],
            raw['importCountries'],
            raw['exportProducts'],
            raw['certifications'],
            doc.reference.parent.id == 'auren_exporters' ? 'exporter export' : '',
            doc.reference.parent.id == 'auren_importers' ? 'importer import' : '',
            doc.reference.parent.id == 'auren_manufacturers' ? 'manufacturer factory' : '',
          ].where((value) => value != null).join(' '),
          'supplierId': doc.id,
          'aurenSupplierId': doc.id,
          'status': status,
          'visibility': visibility,
        };
        final text = _documentText(normalizedData);
        final action = plan.actionFor(AurenMatchKind.business);
        results.add(AurenMatchItem(
          id: doc.id,
          title: name,
          subtitle: _string(
            raw['description'],
            _string(raw['category'], 'مورد متاح للتواصل عبر AUREN'),
          ),
          kind: AurenMatchKind.business,
          score: _score(
            text, profile, false, intentTerms, normalizedIntent, signals,
          ),
          reasons: [
            ..._reasons(text, profile, false, intentTerms, normalizedIntent, signals),
            if (_string(raw['source'], '').isNotEmpty)
              'المصدر: ${_string(raw['source'], '')}',
            if (_string(raw['verificationStatus'], 'unverified').toLowerCase() == 'verified')
              'حالة التحقق: موثّق'
            else
              'حالة التحقق: غير متحقق',
            if (_string(raw['provenanceStatus'], '').toLowerCase() == 'provided')
              'بيانات مصدر السجل متاحة',
          ],
          data: normalizedData,
          action: action,
          actionLabel: plan.labelFor(action),
          actionReason: plan.reasonFor(action),
        ));
      }
      // The same licensed company may be present in more than one trade-role
      // collection. Keep the highest-scoring copy so users do not see duplicates.
      final unique = <String, AurenMatchItem>{};
      for (final item in results) {
        final country = _normalize(_string(
          item.data['countryCode'],
          _string(item.data['country'], ''),
        ));
        final key = '${_normalize(item.title)}|$country';
        final existing = unique[key];
        if (existing == null || item.score > existing.score) {
          unique[key] = item;
        }
      }
      final deduplicated = unique.values.toList();
      deduplicated.sort((a, b) => b.score.compareTo(a.score));
      return deduplicated.take(limit).toList(growable: false);
    } catch (_) {
      // Supplier records are an optional source; other Match Everything
      // categories remain available if this collection cannot be queried.
      return const [];
    }
  }

  String _titleFor(AurenMatchKind kind, Map<String, dynamic> d) {
    final fallback = switch (kind) {
      AurenMatchKind.opportunity => 'Opportunity',
      AurenMatchKind.business => 'Business',
      AurenMatchKind.product => 'Product',
      AurenMatchKind.content => 'Pulse',
      AurenMatchKind.person => 'AUREN member',
    };
    return _string(d['title'], _string(d['name'], _string(d['displayName'], fallback)));
  }

  String _subtitleFor(AurenMatchKind kind, Map<String, dynamic> d) {
    final fallback = switch (kind) {
      AurenMatchKind.opportunity => 'فرصة قد تناسب سياقك.',
      AurenMatchKind.business => 'نشاط قد يناسب احتياجك.',
      AurenMatchKind.product => 'منتج أو خدمة قد تناسب احتياجك.',
      AurenMatchKind.content => 'محتوى قد يهمك.',
      AurenMatchKind.person => 'شخص قد يناسب سياقك.',
    };
    return _string(d['description'], _string(d['text'], fallback));
  }

  String _documentText(Map<String, dynamic> d) => [
        d['title'], d['name'], d['displayName'], d['headline'],
        d['description'], d['text'], d['category'], d['type'],
        d['mode'], d['searchText'], _list(d['tags']).join(' '),
        _list(d['skills']).join(' '), _list(d['interests']).join(' '),
        _list(d['goals']).join(' '), _list(d['services']).join(' '),
        d['businessType'], d['tradeRole'], d['country'], d['countryCode'],
        d['city'], d['source'], d['sourceHost'],
        _list(d['products']).join(' '), _list(d['productCategories']).join(' '),
        _list(d['exportMarkets']).join(' '), _list(d['marketsServed']).join(' '),
        _list(d['importCountries']).join(' '), _list(d['exportProducts']).join(' '),
        _list(d['certifications']).join(' '), _list(d['searchKeywords']).join(' '),
        _valueText(d['price']), d['priceRange'], d['currency'],
        _valueText(d['minimumOrderQuantity']), _valueText(d['moq']),
        d['shippingTerms'], d['incoterms'], d['industry'],
        _list(d['industries']).join(' '), _list(d['languages']).join(' '),
        _list(d['paymentTerms']).join(' '), _list(d['certificationNames']).join(' '),
      ].whereType<String>().join(' ').toLowerCase();

  int _score(String text, AurenProfileModeData profile, bool modeMatch, Set<String> intentTerms, String normalizedIntent, AurenIntentSignals signals) {
    final profileText = [...profile.skills, ...profile.interests, ...profile.goals, ...profile.services].join(' ');
    var score = _overlapScore(text, profileText);
    if (modeMatch) score += 15;
    final normalizedText = _normalize(text);
    score += (intentTerms.intersection(_tokens(text)).length * 10).clamp(0, 25).toInt();
    if (normalizedIntent.length >= 6 && normalizedText.contains(normalizedIntent)) score += 15;
    score += _intentSemanticBoost(normalizedText, normalizedIntent);
    score += signals.matchScore(normalizedText);

    // Penalize explicit location mismatches instead of ranking an unrelated
    // country/city as highly as a result that satisfies the user's constraint.
    if (signals.countries.isNotEmpty &&
        signals.matchingCountries(normalizedText).isEmpty) {
      score -= 18;
    }
    if (signals.cities.isNotEmpty &&
        signals.matchingCities(normalizedText).isEmpty) {
      score -= 12;
    }
    if (signals.wantsCertified &&
        !['certified', 'certification', 'iso', 'haccp', 'شهادة', 'معتمد']
            .any(normalizedText.contains)) {
      score -= 5;
    }
    if (signals.wantsOrganic &&
        !['organic', 'bio', 'عضوي'].any(normalizedText.contains)) {
      score -= 5;
    }
    if (signals.wantsShipping &&
        !['شحن', 'shipping', 'delivery', 'incoterms']
            .any(normalizedText.contains)) {
      score -= 3;
    }
    return score.clamp(0, 100).toInt();
  }

  List<String> _reasons(
    String text,
    AurenProfileModeData profile,
    bool modeMatch,
    Set<String> intentTerms,
    String normalizedIntent,
    AurenIntentSignals signals,
  ) {
    final reasons = <String>[];
    final tokens = _tokens(text);
    final normalizedText = _normalize(text);
    final common = <String>[];
    for (final value in [...profile.skills, ...profile.interests, ...profile.goals, ...profile.services]) {
      final normalized = value.trim().toLowerCase();
      if (normalized.length >= 3 && tokens.contains(normalized)) common.add(value.trim());
      if (common.length == 2) break;
    }
    if (common.isNotEmpty) reasons.add('تطابق: ' + common.join('، '));
    final intentCommon = intentTerms.intersection(tokens).take(3).toList();
    if (normalizedIntent.length >= 6 && _normalize(text).contains(normalizedIntent)) reasons.add('تطابق مباشر مع طلبك');
    if (intentCommon.isNotEmpty) reasons.add('مرتبط بطلبك: ' + intentCommon.join('، '));
    final matchedCountries = signals.matchingCountries(normalizedText)
        .take(2)
        .toList();
    if (matchedCountries.isNotEmpty) {
      reasons.add('الدولة المطابقة: ${matchedCountries.join('، ')}');
    }
    final matchedCities = signals.matchingCities(normalizedText)
        .take(2)
        .toList();
    if (matchedCities.isNotEmpty) {
      reasons.add('المدينة المطابقة: ${matchedCities.join('، ')}');
    }
    if (signals.countries.isNotEmpty && matchedCountries.isEmpty) {
      reasons.add('الدولة المطلوبة غير مؤكدة في بيانات هذه النتيجة');
    }
    if (signals.cities.isNotEmpty && matchedCities.isEmpty) {
      reasons.add('المدينة المطلوبة غير مؤكدة في بيانات هذه النتيجة');
    }
    if (signals.wantsCheap &&
        ['رخيص', 'cheap', 'affordable', 'low price', 'price'].any(normalizedText.contains)) {
      reasons.add('يتضمن مؤشرات سعر أو تكلفة');
    }
    if (signals.wantsShipping &&
        ['شحن', 'shipping', 'delivery', 'incoterms'].any(normalizedText.contains)) {
      reasons.add('توجد معلومات مرتبطة بالشحن');
    }
    if (signals.wantsCertified &&
        ['certified', 'certification', 'iso', 'haccp', 'شهادة', 'معتمد'].any(normalizedText.contains)) {
      reasons.add('توجد إشارة إلى الشهادات المطلوبة');
    }
    if (signals.wantsOrganic &&
        ['organic', 'bio', 'عضوي'].any(normalizedText.contains)) {
      reasons.add('توجد إشارة إلى المنتجات العضوية');
    }
    if (signals.wantsSamples &&
        ['sample', 'samples', 'عينة', 'عينات'].any(normalizedText.contains)) {
      reasons.add('توجد إشارة إلى إمكانية توفير عينات');
    }
    if (modeMatch) reasons.add('متوافق مع نمط ملفك الحالي');
    if (reasons.isEmpty) reasons.add('ارتباط محدود؛ راجع تفاصيل النتيجة قبل اتخاذ إجراء');
    return reasons;
  }

  int _intentSemanticBoost(String text, String intent) {
    if (intent.isEmpty) return 0;
    var boost = 0;
    bool pair(List<String> words) => words.any(intent.contains) && words.any(text.contains);
    if (pair(['السودان', 'sudan'])) boost += 12;
    if (pair(['مصر', 'egypt'])) boost += 8;
    if (pair(['أفريقيا', 'افريقيا', 'africa'])) boost += 8;
    if (pair(['الصين', 'china'])) boost += 8;
    if (pair(['رخيص', 'ارخص', 'cheap', 'cheapest'])) boost += 6;
    if (pair(['مصنع', 'مصانع', 'manufacturer', 'factory'])) boost += 10;
    if (pair(['مورد', 'توريد', 'supplier', 'wholesale'])) boost += 10;
    if (pair(['مصدر', 'تصدير', 'exporter', 'export'])) boost += 12;
    if (pair(['مستورد', 'استيراد', 'importer', 'import'])) boost += 12;
    if (pair(['تجارة دولية', 'international trade', 'global trade'])) boost += 8;
    if (pair(['ملابس', 'clothing', 'fashion'])) boost += 6;
    if (pair(['سمسم', 'sesame'])) boost += 8;
    if (pair(['صمغ عربي', 'gum arabic'])) boost += 8;
    if (pair(['قطن', 'cotton'])) boost += 7;
    if (pair(['حبوب', 'grain', 'cereals'])) boost += 6;
    if (pair(['اغذية', 'food', 'foodstuff'])) boost += 5;
    if (pair(['مواد بناء', 'construction materials'])) boost += 5;
    if (pair(['الكترونيات', 'electronics'])) boost += 5;
    if (pair(['زراعي', 'agriculture', 'agricultural'])) boost += 5;
    return boost.clamp(0, 30).toInt();
  }

  int _overlapScore(String a, String b) {
    final aa = _tokens(a), bb = _tokens(b);
    if (aa.isEmpty || bb.isEmpty) return 0;
    final overlap = aa.intersection(bb).length;
    if (overlap == 0) return 0;
    return (10 + overlap * 12).clamp(10, 80).toInt();
  }

  Set<String> _tokens(String value) => _normalize(value)
      .split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'))
      .where((v) => v.length >= 3).toSet();

  List<String> _list(dynamic value) => value is List
      ? value.map(_valueText).where((v) => v.isNotEmpty).toList()
      : const [];

  /// Convert common Firestore scalar/list/map values into searchable text.
  /// Numeric price and MOQ fields were previously discarded by whereType<String>().
  String _valueText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value.map(_valueText).where((v) => v.isNotEmpty).join(' ');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key} ${_valueText(entry.value)}')
          .where((v) => v.trim().isNotEmpty)
          .join(' ');
    }
    return '';
  }

  String _string(dynamic value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  Set<String> _intentTerms(String? intent) => intent == null ? <String>{} : _tokens(intent);

  String _normalize(String? value) {
    var valueText = (value ?? '').toLowerCase();
    valueText = valueText
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '');
    return valueText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _candidateLimit(int limit) => (limit * 5).clamp(10, 50).toInt();

  int _safeLimit(int value) => value < 1 ? 1 : (value > 20 ? 20 : value);

  int _actionPriority(AurenMatchAction action) => switch (action) {
    AurenMatchAction.requestQuote => 6,
    AurenMatchAction.contact => 5,
    AurenMatchAction.apply => 5,
    AurenMatchAction.addToCart => 4,
    AurenMatchAction.follow => 3,
    AurenMatchAction.save => 2,
    AurenMatchAction.watch => 2,
    AurenMatchAction.open => 1,
  };
}

class AurenIntentSignals {
  final Set<String> countries;
  final Set<String> cities;
  final bool wantsCheap;
  final bool wantsShipping;
  final bool wantsSupplier;
  final bool wantsManufacturer;
  final bool wantsWholesale;
  final bool wantsExporter;
  final bool wantsImporter;
  final bool wantsInternationalTrade;
  final bool wantsBulk;
  final bool wantsCertified;
  final bool wantsOrganic;
  final bool wantsSamples;
  const AurenIntentSignals({
    this.countries = const {},
    this.cities = const {},
    this.wantsCheap = false,
    this.wantsShipping = false,
    this.wantsSupplier = false,
    this.wantsManufacturer = false,
    this.wantsWholesale = false,
    this.wantsExporter = false,
    this.wantsImporter = false,
    this.wantsInternationalTrade = false,
    this.wantsBulk = false,
    this.wantsCertified = false,
    this.wantsOrganic = false,
    this.wantsSamples = false,
  });

  factory AurenIntentSignals.fromIntent(String? intent) {
    final n = AurenIntentSignals._normalizeIntent(intent);
    Set<String> found(List<String> words) => words
        .map(_normalizeIntent)
        .where(n.contains)
        .toSet();
    return AurenIntentSignals(
      countries: found(['السودان','sudan','مصر','egypt','الصين','china','الإمارات','الامارات','uae','united arab emirates','kenya','كينيا','نيجيريا','nigeria','السعودية','saudi arabia','saudi','تركيا','turkey','türkiye','الهند','india','باكستان','pakistan','بنغلاديش','bangladesh','اثيوبيا','ethiopia','اوغندا','uganda','تنزانيا','tanzania','رواندا','rwanda','غانا','ghana','جنوب افريقيا','south africa','امريكا','usa','united states','بريطانيا','uk','united kingdom','المانيا','germany','فيتنام','vietnam']),
      cities: found(['الخرطوم','khartoum','ام درمان','omdurman','ام درمان','القاهرة','cairo','دبي','dubai','ابوظبي','abu dhabi','الرياض','riyadh','جدة','jeddah','اسطنبول','istanbul','شنغهاي','shanghai','شنتشن','shenzhen','غوانزو','guangzhou','مومباي','mumbai','دلهي','delhi','نيروبي','nairobi','لاغوس','lagos','أديس أبابا','addis ababa','كمبالا','kampala','دار السلام','dar es salaam','جوهانسبرغ','johannesburg','لندن','london','نيويورك','new york']),
      wantsCheap: ['رخيص','ارخص','cheap','cheapest','low price','barato','barata','bon marché','pas cher','barato','barata','ucuz','nafuu','便宜','सस्ता'].any((w) => n.contains(_normalizeIntent(w))),
      wantsShipping: ['شحن','shipping','delivery','توصل','التوصيل','envío','envio','livraison','entrega','kargo','usafirishaji','运输','運輸','शिपिंग'].any((w) => n.contains(_normalizeIntent(w))),
      wantsSupplier: ['مورد','موردين','توريد','توريدات','supplier','suppliers','vendor','vendors','wholesale','تاجر جملة','proveedor','proveedora','fournisseur','fournisseurs','fornecedor','fornecedora','tedarikçi','tedarikci','msambazaji','供应商','供應商','आपूर्तिकर्ता'].any((w) => n.contains(_normalizeIntent(w))),
      wantsManufacturer: ['مصنع','مصانع','manufacturer','factory','fabricante','fabricant','fabricantes','üretici','uretici','mtengenezaji','制造商','製造商','निर्माता'].any((w) => n.contains(_normalizeIntent(w))),
      wantsExporter: ['مصدر','مصدرين','مصدّر','مصدّرين','تصدير','exporter','exporters','export','exportador','exportadora','exportateur','ihracatçı','ihracatci','msafirishaji','出口商','निर्यातक'].any((w) => n.contains(_normalizeIntent(w))),
      wantsImporter: ['مستورد','مستوردين','استيراد','importer','importers','import','importador','importadora','importateur','ithalatçı','ithalatci','muingizaji','进口商','進口商','आयातक'].any((w) => n.contains(_normalizeIntent(w))),
      wantsInternationalTrade: ['تجارة دولية','تجارة خارجية','international trade','global trade','import export','comercio internacional','commerce international','comércio internacional','uluslararası ticaret','biashara ya kimataifa','国际贸易','國際貿易','अंतरराष्ट्रीय व्यापार'].any((w) => n.contains(_normalizeIntent(w))),
      wantsWholesale: ['جملة','wholesale','bulk','mayorista','grossiste','atacado','toptan','jumla','批发','批發','थोक'].any((w) => n.contains(_normalizeIntent(w))),
      wantsBulk: ['كميات','كمية كبيرة','bulk','minimum order','moq','por mayor','en gros','a granel','toptan','kwa wingi','批量','थोक मात्रा'].any((w) => n.contains(_normalizeIntent(w))),
      wantsCertified: ['شهادة','شهادات','معتمد','معتمدة','certified','certification','iso','haccp','certificado','certificada','certifié','certifiée','sertifikalı','sertifikali','cheti','认证','認證','प्रमाणित'].any((w) => n.contains(_normalizeIntent(w))),
      wantsOrganic: ['عضوي','عضوية','organic','bio','orgánico','organico','biologique','orgânica','organica','organik','kikaboni','有机','有機','जैविक'].any((w) => n.contains(_normalizeIntent(w))),
      wantsSamples: ['عينة','عينات','sample','samples','muestra','muestras','échantillon','échantillons','amostra','amostras','numune','sampuli','样品','नमूने'].any((w) => n.contains(_normalizeIntent(w))),
    );
  }

  /// Match country aliases so "Türkiye" can match a record stored as
  /// "Turkey", and "UAE" can match "United Arab Emirates".
  List<String> matchingCountries(String text) {
    final n = _normalizeIntent(text);
    return countries.where((requested) {
      final group = _countryAliasGroup(requested);
      return group.any((alias) => n.contains(_normalizeIntent(alias)));
    }).toList(growable: false);
  }

  /// Match common city spellings and transliterations across English/Arabic.
  List<String> matchingCities(String text) {
    final n = _normalizeIntent(text);
    return cities.where((requested) {
      final group = _cityAliasGroup(requested);
      return group.any((alias) => n.contains(_normalizeIntent(alias)));
    }).toList(growable: false);
  }

  static List<String> _countryAliasGroup(String value) {
    const groups = <List<String>>[
      ['turkey', 'türkiye', 'تركيا'],
      ['uae', 'united arab emirates', 'الإمارات', 'الامارات'],
      ['usa', 'united states', 'america', 'امريكا', 'الولايات المتحدة'],
      ['uk', 'united kingdom', 'britain', 'بريطانيا', 'المملكة المتحدة'],
      ['saudi arabia', 'saudi', 'السعودية', 'المملكة العربية السعودية'],
      ['south africa', 'جنوب افريقيا', 'جنوب أفريقيا'],
      ['sudan', 'السودان'],
      ['egypt', 'مصر'],
      ['china', 'الصين'],
      ['kenya', 'كينيا'],
      ['nigeria', 'نيجيريا'],
      ['india', 'الهند'],
      ['pakistan', 'باكستان'],
      ['bangladesh', 'بنغلاديش', 'بنجلاديش'],
      ['ethiopia', 'اثيوبيا', 'إثيوبيا'],
      ['uganda', 'اوغندا', 'أوغندا'],
      ['tanzania', 'تنزانيا'],
      ['rwanda', 'رواندا'],
      ['ghana', 'غانا'],
      ['germany', 'المانيا', 'ألمانيا'],
      ['vietnam', 'فيتنام'],
    ];
    for (final group in groups) {
      if (group.any((alias) => _normalizeIntent(alias) == _normalizeIntent(value))) {
        return group;
      }
    }
    return [value];
  }

  static List<String> _cityAliasGroup(String value) {
    const groups = <List<String>>[
      ['khartoum', 'الخرطوم'],
      ['omdurman', 'om durman', 'umm durman', 'ام درمان', 'أم درمان'],
      ['cairo', 'القاهرة'],
      ['dubai', 'دبي'],
      ['abu dhabi', 'ابوظبي', 'أبوظبي'],
      ['riyadh', 'الرياض'],
      ['jeddah', 'جدة'],
      ['istanbul', 'اسطنبول', 'إسطنبول'],
      ['shanghai', 'شنغهاي'],
      ['shenzhen', 'شنتشن'],
      ['guangzhou', 'غوانزو'],
      ['mumbai', 'مومباي'],
      ['delhi', 'دلهي'],
      ['nairobi', 'نيروبي'],
      ['lagos', 'لاغوس'],
      ['addis ababa', 'أديس أبابا', 'اديس ابابا'],
      ['kampala', 'كمبالا'],
      ['dar es salaam', 'دار السلام'],
      ['johannesburg', 'جوهانسبرغ'],
      ['london', 'لندن'],
      ['new york', 'نيويورك'],
    ];
    for (final group in groups) {
      if (group.any((alias) => _normalizeIntent(alias) == _normalizeIntent(value))) {
        return group;
      }
    }
    return [value];
  }

  int matchScore(String text) {
    final n = _normalizeIntent(text);
    var score = 0;
    if (countries.any(n.contains)) score += 10;
    if (cities.any(n.contains)) score += 8;
    if (wantsCheap && ['رخيص','cheap','low price','affordable','سعر'].any((w) => n.contains(_normalizeIntent(w)))) score += 6;
    if (wantsShipping && ['شحن','shipping','delivery','التوصيل'].any((w) => n.contains(_normalizeIntent(w)))) score += 6;
    if (wantsSupplier && ['مورد','supplier','توريد','wholesale'].any((w) => n.contains(_normalizeIntent(w)))) score += 8;
    if (wantsManufacturer && ['مصنع','manufacturer','factory'].any((w) => n.contains(_normalizeIntent(w)))) score += 8;
    if (wantsWholesale && ['جملة','wholesale','bulk'].any((w) => n.contains(_normalizeIntent(w)))) score += 6;
    if (wantsBulk && ['كميات','bulk','moq','minimum order'].any((w) => n.contains(_normalizeIntent(w)))) score += 6;
    if (wantsCertified && ['شهادة','certified','certification','iso','haccp'].any((w) => n.contains(_normalizeIntent(w)))) score += 5;
    if (wantsOrganic && ['عضوي','organic','bio'].any((w) => n.contains(_normalizeIntent(w)))) score += 5;
    if (wantsSamples && ['عينة','عينات','sample','samples'].any((w) => n.contains(_normalizeIntent(w)))) score += 4;
    return score.clamp(0, 35).toInt();
  }

  static String _normalizeIntent(String? value) {
    var text = (value ?? '').toLowerCase();
    text = text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class AurenIntentActionPlan {
  final String normalized;
  final bool commercial;
  final bool learning;
  final bool work;
  final bool social;
  final bool media;
  final bool wantsAction;

  const AurenIntentActionPlan({
    required this.normalized,
    this.commercial = false,
    this.learning = false,
    this.work = false,
    this.social = false,
    this.media = false,
    this.wantsAction = false,
  });

  factory AurenIntentActionPlan.fromIntent(String? intent) {
    final n = AurenIntentActionPlan._normalizeIntent(intent);
    bool has(List<String> words) => words.any((word) => n.contains(AurenIntentSignals._normalizeIntent(word)));
    return AurenIntentActionPlan(
      normalized: n,
      commercial: has(['مورد','توريد','supplier','wholesale','مصنع','manufacturer','factory','شراء','اشتري','سعر','منتج','بضاعة','ملابس','خدمة','مطعم','store','business','quote','عرض سعر','مصدر','تصدير','exporter','export','مستورد','استيراد','importer','import','تجارة دولية','international trade','proveedor','fournisseur','fornecedor','tedarikçi','tedarikci','msambazaji','供应商','供應商','fabricante','fabricant','üretici','uretici','manufacturer','exportador','exportateur','ihracatçı','ihracatci','importador','importateur','ithalatçı','ithalatci','comercio internacional','commerce international','comércio internacional','uluslararası ticaret','biashara ya kimataifa','国际贸易','國際貿易']),
      learning: has(['اتعلم','تعلم','كورس','دورة','flutter','learn','course','study','aprender','curso','apprendre','cours','apprendre','aprender','öğren','ogren','kujifunza','学习','課程','课程','सीखें','पढ़ाई']),
      work: has(['وظيفة','شغل','عمل','فرصة','تقديم','توظيف','job','work','career','apply','empleo','trabajo','trabajar','emploi','travail','emprego','trabalho','iş','is ilanı','kariyer','kazi','ajira','工作','职位','職位','नौकरी','काम']),
      social: has(['تابع','متابعة','صديق','تواصل','chat','follow','connect','creator','مؤثر','seguir','conectar','suivre','contacter','seguir','conectar','takip','bağlan','baglan','fuata','unganisha','关注','联系','关注','जुड़ें','अनुसरण']),
      media: has(['فيلم','مسلسل','فيديو','شورت','اغنية','موسيقى','محتوى','شاهد','watch','video','movie','series','music','película','pelicula','serie','vídeo','video','música','musica','film','vidéo','video','musique','film','dizi','izle','filamu','muziki','视频','电影','电视剧','音乐','वीडियो','फ़िल्म','फिल्म','संगीत']),
      wantsAction: has(['عايز','اريد','أريد','ابحث','أبحث','جيب','find','need','want','buy','get','open','contact','apply','learn','buscar','necesito','quiero','trouver','cherche','besoin','je veux','procurar','preciso','quero','bul','ihtiyacım','nahitaji','tafuta','查找','需要','寻找','खोजें','चाहिए']),
    );
  }

  static String _normalizeIntent(String? value) {
    var text = (value ?? '').toLowerCase();
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه').replaceAll('ـ', '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  AurenMatchAction actionFor(AurenMatchKind kind) {
    if (commercial) {
      switch (kind) {
        case AurenMatchKind.business:
          final supplierIntent = [
            'مورد', 'supplier', 'proveedor', 'fournisseur', 'fornecedor',
            'tedarikçi', 'tedarikci', 'msambazaji', '供应商', '供應商',
            'توريد', 'wholesale', 'mayoreo', 'gros', 'atacado', 'toptan',
            'مصنع', 'manufacturer', 'fabricante', 'fabricant', 'üretici',
            'uretici', '厂商', '工厂', 'مصدر', 'تصدير', 'export', 'exporter',
            'exportador', 'exportateur', 'ihracatçı', 'ihracatci',
            'مستورد', 'استيراد', 'import', 'importer', 'importador',
            'importateur', 'ithalatçı', 'ithalatci', 'تجارة دولية',
            'international trade', 'comercio internacional',
            'commerce international', 'comércio internacional',
            'uluslararası ticaret', 'biashara ya kimataifa', '国际贸易',
            '國際貿易', 'quote', 'عرض سعر',
          ].any((term) => normalized.contains(_normalizeIntent(term)));
          return supplierIntent
              ? AurenMatchAction.requestQuote : AurenMatchAction.contact;
        case AurenMatchKind.product:
          return ['اشتري', 'شراء', 'buy', 'comprar', 'compra', 'acheter', 'achète', 'comprar', 'quero comprar', 'satın al', 'satin al', 'nunua', '购买', '买', 'खरीदें']
                  .any((term) => normalized.contains(_normalizeIntent(term)))
              ? AurenMatchAction.addToCart : AurenMatchAction.contact;
        default:
          break;
      }
    }
    if (work && kind == AurenMatchKind.opportunity) return AurenMatchAction.apply;
    if (learning && kind == AurenMatchKind.content) return AurenMatchAction.watch;
    if (media && kind == AurenMatchKind.content) return AurenMatchAction.watch;
    if (social && kind == AurenMatchKind.person) return AurenMatchAction.contact;
    return switch (kind) {
      AurenMatchKind.person => AurenMatchAction.open,
      AurenMatchKind.opportunity => AurenMatchAction.follow,
      AurenMatchKind.business => AurenMatchAction.contact,
      AurenMatchKind.product => AurenMatchAction.contact,
      AurenMatchKind.content => AurenMatchAction.watch,
    };
  }

  String labelFor(AurenMatchAction action) => switch (action) {
    AurenMatchAction.open => 'فتح',
    AurenMatchAction.contact => 'تواصل',
    AurenMatchAction.requestQuote => 'طلب عرض سعر',
    AurenMatchAction.apply => 'التقديم على الفرصة',
    AurenMatchAction.addToCart => 'إضافة للسلة',
    AurenMatchAction.follow => 'متابعة الفرصة',
    AurenMatchAction.save => 'حفظ',
    AurenMatchAction.watch => 'مشاهدة',
  };

  String reasonFor(AurenMatchAction action) => switch (action) {
    AurenMatchAction.requestQuote => 'فهمت أنك تبحث عن مورد؛ الخطوة التالية هي التواصل وطلب عرض سعر.',
    AurenMatchAction.contact => 'فهمت أنك تريد الوصول للجهة المناسبة؛ الخطوة التالية هي التواصل معها.',
    AurenMatchAction.apply => 'فهمت أنك تبحث عن فرصة عمل؛ الخطوة التالية هي فتح الفرصة ثم التقديم عندما يكون نموذج التقديم متاحاً.',
    AurenMatchAction.addToCart => 'فهمت أنك تريد الشراء؛ الخطوة التالية هي فتح المنتج ثم إضافته للسلة.',
    AurenMatchAction.follow => 'يمكنك فتح الفرصة وحفظ اهتمامك بها ومتابعتها.',
    AurenMatchAction.watch => 'فهمت أنك تبحث عن محتوى؛ الخطوة التالية هي فتحه ومشاهدته.',
    AurenMatchAction.save => 'يمكنك حفظ هذه النتيجة للرجوع إليها لاحقاً.',
    AurenMatchAction.open => 'افتح النتيجة لمتابعة الخطوة المناسبة.',
  };
}


extension AurenMatchIntelligence on AurenMatchEverythingService {
  Future<List<AurenMatchItem>> findSupplierIntelligence({
    required String query,
    String? country,
    int limit = 10,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('aurenMatchEverythingIntelligence');
    final result = await callable.call({
      'query': clean,
      if (country != null && country.trim().isNotEmpty) 'country': country.trim(),
      'limit': limit.clamp(1, 25).toInt(),
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final raw = data['results'];
    if (raw is! List) return const [];

    return raw.whereType<Map>().map((entry) {
      final item = Map<String, dynamic>.from(entry);
      final type = '${item['resultType'] ?? item['kind'] ?? ''}'.toLowerCase();
      final isSupplier = type == 'supplier';
      final id = '${item['id'] ?? ''}'.trim();
      if (id.isEmpty) return null;

      final score = (item['matchScore'] as num?)?.toInt() ?? 0;
      final name = '${item['name'] ?? item['companyName'] ?? item['title'] ?? id}'.trim();
      final description = '${item['description'] ?? item['category'] ?? 'مورد متاح عبر AUREN.'}'.trim();

      return AurenMatchItem(
        id: id,
        title: name,
        subtitle: description,
        kind: isSupplier ? AurenMatchKind.business : AurenMatchKind.opportunity,
        score: score.clamp(0, 100).toInt(),
        reasons: isSupplier
            ? const ['مورد مطابق لطلبك عبر Match Everything']
            : const ['نتيجة من ذكاء الفرص العالمي'],
        data: {
          ...item,
          if (isSupplier) 'supplierId': id,
        },
        action: isSupplier ? AurenMatchAction.requestQuote : AurenMatchAction.open,
        actionLabel: isSupplier ? 'طلب عرض سعر' : 'فتح',
        actionReason: isSupplier
            ? 'AUREN وجد مورداً مناسباً لطلبك؛ راجع RFQ وعدّل البيانات قبل الموافقة.'
            : 'افتح النتيجة لمتابعة التفاصيل.',
      );
    }).whereType<AurenMatchItem>().toList();
  }
}

extension AurenMatchActionExecution on AurenMatchEverythingService {
  Future<void> recordAction({
    required String uid,
    required AurenMatchItem item,
    String? sourceIntent,
  }) async {
    await _db.collection('auren_action_events').add({
      'uid': uid,
      'targetId': item.id,
      'targetKind': item.kind.name,
      'action': item.action.name,
      'intent': item.actionReason,
      'sourceIntent': (sourceIntent ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
