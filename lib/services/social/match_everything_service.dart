import 'package:cloud_firestore/cloud_firestore.dart';

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

    final results = <AurenMatchItem>[];
    results.addAll(await _people(uid, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan));
    results.addAll(await _collectionMatches('opportunities', AurenMatchKind.opportunity, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan));
    results.addAll(await _collectionMatches('businesses', AurenMatchKind.business, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan));
    results.addAll(await _collectionMatches('products', AurenMatchKind.product, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan));
    results.addAll(await _collectionMatches('posts', AurenMatchKind.content, profile, resolved.mode, limit, intentTerms, normalizedIntent, actionPlan));

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
          score: _score(text, profile, candidateMode == mode, intentTerms, normalizedIntent),
          reasons: _reasons(text, profile, candidateMode == mode, intentTerms, normalizedIntent),
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
  ) async {
    try {
      final snapshot = await _db.collection(collection)
          .where('visibility', isEqualTo: 'public')
          .limit(_candidateLimit(limit))
          .get();
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
          score: _score(text, profile, modeMatch, intentTerms, normalizedIntent),
          reasons: _reasons(text, profile, modeMatch, intentTerms, normalizedIntent),
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
      ].whereType<String>().join(' ').toLowerCase();

  int _score(String text, AurenProfileModeData profile, bool modeMatch, Set<String> intentTerms, String normalizedIntent) {
    final profileText = [...profile.skills, ...profile.interests, ...profile.goals, ...profile.services].join(' ');
    var score = _overlapScore(text, profileText);
    if (modeMatch) score += 15;
    final normalizedText = _normalize(text);
    score += (intentTerms.intersection(_tokens(text)).length * 10).clamp(0, 25);
    if (normalizedIntent.length >= 6 && normalizedText.contains(normalizedIntent)) score += 15;
    return score.clamp(0, 100);
  }

  List<String> _reasons(String text, AurenProfileModeData profile, bool modeMatch, Set<String> intentTerms, String normalizedIntent) {
    final reasons = <String>[];
    final tokens = _tokens(text);
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
    if (modeMatch) reasons.add('متوافق مع نمط ملفك الحالي');
    if (reasons.isEmpty) reasons.add('مرتبط بسياقك الحالي');
    return reasons;
  }

  int _overlapScore(String a, String b) {
    final aa = _tokens(a), bb = _tokens(b);
    if (aa.isEmpty || bb.isEmpty) return 20;
    return (20 + aa.intersection(bb).length * 12).clamp(20, 80);
  }

  Set<String> _tokens(String value) => value.toLowerCase()
      .split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'))
      .where((v) => v.length >= 3).toSet();

  List<String> _list(dynamic value) =>
      value is List ? value.whereType<String>().map((v) => v.trim()).toList() : const [];

  String _string(dynamic value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  Set<String> _intentTerms(String? intent) => intent == null ? <String>{} : _tokens(intent);

  String _normalize(String? value) => (value ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  int _candidateLimit(int limit) => (limit * 5).clamp(10, 50);

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
    final n = (intent ?? '').toLowerCase().trim();
    bool has(List<String> words) => words.any(n.contains);
    return AurenIntentActionPlan(
      normalized: n,
      commercial: has(['مورد','توريد','supplier','شراء','اشتري','سعر','منتج','بضاعة','ملابس','خدمة','مطعم','store','business','quote','عرض سعر']),
      learning: has(['اتعلم','تعلم','كورس','دورة','flutter','learn','course','study']),
      work: has(['وظيفة','شغل','عمل','فرصة','تقديم','توظيف','job','work','career','apply']),
      social: has(['تابع','متابعة','صديق','تواصل','chat','follow','connect','creator','مؤثر']),
      media: has(['فيلم','مسلسل','فيديو','شورت','اغنية','موسيقى','محتوى','شاهد','watch','video','movie','series','music']),
      wantsAction: has(['عايز','اريد','أريد','ابحث','أبحث','جيب','find','need','want','buy','get','open','contact','apply','learn']),
    );
  }

  AurenMatchAction actionFor(AurenMatchKind kind) {
    if (commercial) {
      switch (kind) {
        case AurenMatchKind.business:
          return normalized.contains('مورد') || normalized.contains('supplier') || normalized.contains('توريد') || normalized.contains('quote') || normalized.contains('عرض سعر')
              ? AurenMatchAction.requestQuote : AurenMatchAction.contact;
        case AurenMatchKind.product:
          return normalized.contains('اشتري') || normalized.contains('شراء') || normalized.contains('buy')
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


extension AurenMatchActionExecution on AurenMatchEverythingService {
  Future<void> recordAction({required String uid, required AurenMatchItem item}) async {
    await FirebaseFirestore.instance.collection('auren_action_events').add({
      'uid': uid,
      'targetId': item.id,
      'targetKind': item.kind.name,
      'action': item.action.name,
      'intent': item.actionReason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
