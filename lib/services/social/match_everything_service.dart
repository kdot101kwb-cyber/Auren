import 'package:cloud_firestore/cloud_firestore.dart';

import 'adaptive_profile_service.dart';
import 'profile_mode_service.dart';

enum AurenMatchKind { person, opportunity, business, product, content }

class AurenMatchItem {
  final String id;
  final String title;
  final String subtitle;
  final AurenMatchKind kind;
  final int score;
  final List<String> reasons;
  final Map<String, dynamic> data;

  const AurenMatchItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.score,
    required this.reasons,
    this.data = const {},
  });
}

/// Unified matching across people, opportunities, businesses, products and
/// public Pulse content.
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

    final results = <AurenMatchItem>[];
    results.addAll(await _people(uid, profile, resolved.mode, limit, intentTerms, normalizedIntent));
    results.addAll(await _collectionMatches('opportunities', AurenMatchKind.opportunity, profile, resolved.mode, limit, intentTerms, normalizedIntent));
    results.addAll(await _collectionMatches('businesses', AurenMatchKind.business, profile, resolved.mode, limit, intentTerms, normalizedIntent));
    results.addAll(await _collectionMatches('products', AurenMatchKind.product, profile, resolved.mode, limit, intentTerms, normalizedIntent));
    results.addAll(await _collectionMatches('posts', AurenMatchKind.content, profile, resolved.mode, limit, intentTerms, normalizedIntent));

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit * 5).toList();
  }

  Future<List<AurenMatchItem>> _people(
    String uid, AurenProfileModeData profile, AurenProfileMode mode, int limit, Set<String> intentTerms, String normalizedIntent) async {
    try {
      final snapshot = await _db.collectionGroup('profile_modes')
          .where('discoverable', isEqualTo: true).limit(_candidateLimit(limit)).get();
      return snapshot.docs.where((doc) => doc.reference.parent.parent?.id != uid).map((doc) {
        final d = doc.data();
        final candidateMode = AurenProfileModeX.fromId(d['mode'] as String?);
        final text = _documentText(d);
        return AurenMatchItem(
          id: doc.reference.parent.parent?.id ?? doc.id,
          title: _string(d['headline'], 'AUREN member'),
          subtitle: _string(d['bio'], candidateMode?.label ?? 'Person'),
          kind: AurenMatchKind.person,
          score: _score(text, profile, candidateMode == mode, intentTerms, normalizedIntent),
          reasons: _reasons(text, profile, candidateMode == mode, intentTerms, normalizedIntent),
          data: d,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<AurenMatchItem>> _collectionMatches(
    String collection, AurenMatchKind kind, AurenProfileModeData profile,
    AurenProfileMode mode, int limit, Set<String> intentTerms, String normalizedIntent) async {
    try {
      final snapshot = await _db.collection(collection)
          .where('visibility', isEqualTo: 'public').limit(_candidateLimit(limit)).get();
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final text = _documentText(d);
        final declaredMode = AurenProfileModeX.fromId(d['mode'] as String?);
        final modeMatch = declaredMode == mode;
        return AurenMatchItem(
          id: doc.id,
          title: _titleFor(kind, d),
          subtitle: _subtitleFor(kind, d),
          kind: kind,
          score: _score(text, profile, modeMatch, intentTerms, normalizedIntent),
          reasons: _reasons(text, profile, modeMatch, intentTerms, normalizedIntent),
          data: d,
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
      AurenMatchKind.business => 'نشاط قد يناسب اهتماماتك.',
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
    if (common.isNotEmpty) reasons.add('تطابق: '+common.join('، '));
    final intentCommon = intentTerms.intersection(tokens).take(3).toList();
    if (normalizedIntent.length >= 6 && _normalize(text).contains(normalizedIntent)) reasons.add('تطابق مباشر مع طلبك');
    if (intentCommon.isNotEmpty) reasons.add('مرتبط بطلبك: '+intentCommon.join('، '));
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

  String _normalize(String? value) => (value ?? '').toLowerCase().replaceAll(RegExp(r'\\s+'), ' ').trim();

  int _candidateLimit(int limit) => (limit * 5).clamp(10, 50);

  int _safeLimit(int value) => value < 1 ? 1 : (value > 20 ? 20 : value);
}
