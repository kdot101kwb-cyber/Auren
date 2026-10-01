import 'package:cloud_firestore/cloud_firestore.dart';

import 'adaptive_profile_service.dart';
import 'profile_mode_service.dart';

enum AurenDiscoveryKind { people, opportunities }

class AurenDiscoveryItem {
  final String id;
  final String title;
  final String subtitle;
  final AurenDiscoveryKind kind;
  final AurenProfileMode? mode;
  final int score;
  final Map<String, dynamic> data;

  const AurenDiscoveryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.score,
    this.mode,
    this.data = const {},
  });
}

/// Shared ranking layer for Social Discovery and Opportunity Radar.
///
/// The ranking is deterministic and local to the client. It uses only the
/// profile context the user has already provided and public/discoverable data.
/// It does not expose private profile fields.
class AurenAdaptiveDiscoveryService {
  final FirebaseFirestore _db;
  final AurenAdaptiveProfileService _adaptive;

  AurenAdaptiveDiscoveryService({
    FirebaseFirestore? db,
    AurenAdaptiveProfileService adaptive = const AurenAdaptiveProfileService(),
  })  : _db = db ?? FirebaseFirestore.instance,
        _adaptive = adaptive;

  Future<AurenAdaptiveProfileResult> resolveContext({
    required String uid,
    AurenProfileContext context = AurenProfileContext.unknown,
    String? intent,
  }) async {
    final modeService = AurenProfileModeService(db: _db);
    final current = await modeService.getActiveMode(uid);
    final profile = await modeService.get(uid, current);
    return _adaptive.suggest(
      currentMode: current,
      context: context,
      profile: profile,
      intent: intent,
    );
  }

  Future<List<AurenDiscoveryItem>> findOpportunities({
    required String uid,
    AurenProfileContext context = AurenProfileContext.work,
    String? intent,
    int limit = 20,
  }) async {
    final modeService = AurenProfileModeService(db: _db);
    final current = await modeService.getActiveMode(uid);
    final profile = await modeService.get(uid, current);
    final result = _adaptive.suggest(
      currentMode: current,
      context: context,
      profile: profile,
      intent: intent,
    );

    final snapshot = await _db
        .collection('opportunities')
        .where('visibility', isEqualTo: 'public')
        .limit(_safeLimit(limit))
        .get();

    return snapshot.docs
        .map((doc) => _rankOpportunity(doc, profile, result.mode))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  Future<List<AurenDiscoveryItem>> findPeople({
    required String uid,
    AurenProfileContext context = AurenProfileContext.social,
    String? intent,
    int limit = 20,
  }) async {
    final modeService = AurenProfileModeService(db: _db);
    final current = await modeService.getActiveMode(uid);
    final profile = await modeService.get(uid, current);
    final result = _adaptive.suggest(
      currentMode: current,
      context: context,
      profile: profile,
      intent: intent,
    );

    final snapshot = await _db
        .collectionGroup('profile_modes')
        .where('discoverable', isEqualTo: true)
        .limit(limit.clamp(1, 50))
        .get();

    return snapshot.docs
        .where((doc) => doc.reference.parent.parent?.id != uid)
        .map((doc) => _rankPerson(doc, profile, result.mode))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  AurenDiscoveryItem _rankOpportunity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    AurenProfileModeData profile,
    AurenProfileMode mode,
  ) {
    final d = doc.data();
    final title = _string(d['title'], 'Opportunity');
    final text = [
      title,
      _string(d['description'], ''),
      _string(d['category'], ''),
      _string(d['type'], ''),
      _list(d['skills']).join(' '),
      _list(d['tags']).join(' '),
    ].join(' ').toLowerCase();

    final profileText = [
      ...profile.skills,
      ...profile.interests,
      ...profile.goals,
      ...profile.services,
    ].join(' ').toLowerCase();

    final score = _score(text, profileText, mode, d);
    return AurenDiscoveryItem(
      id: doc.id,
      title: title,
      subtitle: _string(d['description'], 'فرصة قد تناسب سياقك الحالي.'),
      kind: AurenDiscoveryKind.opportunities,
      score: score,
      mode: mode,
      data: d,
    );
  }

  AurenDiscoveryItem _rankPerson(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    AurenProfileModeData profile,
    AurenProfileMode mode,
  ) {
    final d = doc.data();
    final candidateMode = AurenProfileModeX.fromId(d['mode'] as String?) ?? AurenProfileMode.personal;
    final text = [
      _string(d['headline'], ''),
      _string(d['bio'], ''),
      _list(d['skills']).join(' '),
      _list(d['interests']).join(' '),
      _list(d['goals']).join(' '),
      _list(d['services']).join(' '),
    ].join(' ').toLowerCase();

    final profileText = [
      ...profile.skills,
      ...profile.interests,
      ...profile.goals,
      ...profile.services,
    ].join(' ').toLowerCase();

    var score = _overlapScore(text, profileText);
    if (candidateMode == mode) score += 15;

    final parentUid = doc.reference.parent.parent?.id ?? '';
    final name = _string(d['headline'], 'AUREN member');
    return AurenDiscoveryItem(
      id: parentUid.isEmpty ? doc.id : parentUid,
      title: name,
      subtitle: _string(d['bio'], candidateMode.label),
      kind: AurenDiscoveryKind.people,
      score: score.clamp(0, 100),
      mode: candidateMode,
      data: d,
    );
  }

  int _score(
    String text,
    String profileText,
    AurenProfileMode mode,
    Map<String, dynamic> data,
  ) {
    var score = _overlapScore(text, profileText);
    final declaredMode = AurenProfileModeX.fromId(data['mode'] as String?);
    if (declaredMode == mode) score += 10;
    if (mode == AurenProfileMode.business &&
        (text.contains('business') || text.contains('company') || text.contains('شركة'))) {
      score += 10;
    }
    if (mode == AurenProfileMode.professional &&
        (text.contains('job') || text.contains('career') || text.contains('وظيفة'))) {
      score += 10;
    }
    return score.clamp(0, 100);
  }

  int _overlapScore(String a, String b) {
    final tokensA = _tokens(a);
    final tokensB = _tokens(b);
    if (tokensA.isEmpty || tokensB.isEmpty) return 20;
    final common = tokensA.intersection(tokensB).length;
    return (20 + common * 12).clamp(20, 80);
  }

  int _safeLimit(int value) => value < 1 ? 1 : (value > 50 ? 50 : value);

  Set<String> _tokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'))
      .where((v) => v.length >= 3)
      .toSet();

  List<String> _list(dynamic value) =>
      value is List ? value.whereType<String>().map((v) => v.trim()).toList() : const [];

  String _string(dynamic value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}
