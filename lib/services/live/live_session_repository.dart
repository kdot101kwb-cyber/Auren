import 'package:cloud_firestore/cloud_firestore.dart';

import 'live_session.dart';

class LiveSessionRepository {
  final FirebaseFirestore db;

  LiveSessionRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      db.collection('live_sessions');

  Future<String> createSession({
    required String ownerId,
    String title = '',
    LiveSessionType type = LiveSessionType.normal,
  }) async {
    final cleanOwnerId = ownerId.trim();
    final cleanTitle = title.trim();
    if (cleanOwnerId.isEmpty || cleanOwnerId.length > 128) {
      throw ArgumentError('معرّف صاحب اللايف غير صالح.');
    }
    if (cleanTitle.length > 160) {
      throw ArgumentError('عنوان اللايف طويل جدًا.');
    }

    final ref = _sessions.doc();
    final now = Timestamp.now();
    await ref.set({
      'ownerId': cleanOwnerId,
      'title': cleanTitle,
      'type': type.name,
      'currentMode': LiveMode.normal.name,
      'status': LiveSessionStatus.live.name,
      'currentSkillId': '',
      'visibility': 'public',
      'createdAt': now,
      'updatedAt': now,
      'segments': <Map<String, dynamic>>[],
    });
    return ref.id;
  }

  Stream<LiveSession?> watchSession(String sessionId) {
    final id = sessionId.trim();
    if (id.isEmpty) return const Stream<LiveSession?>.empty();
    return _sessions.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return LiveSession.fromMap(snapshot.id, _normalizeFirestoreData(data));
    });
  }

  Future<void> addSkillSegment({
    required String sessionId,
    required String ownerId,
    required String skillId,
  }) async {
    await _switchMode(
      sessionId: sessionId,
      ownerId: ownerId,
      mode: LiveMode.skill,
      skillId: skillId,
    );
  }

  Future<void> returnToNormal({
    required String sessionId,
    required String ownerId,
  }) async {
    await _switchMode(
      sessionId: sessionId,
      ownerId: ownerId,
      mode: LiveMode.normal,
    );
  }

  Future<void> endSession({
    required String sessionId,
    required String ownerId,
  }) async {
    final id = sessionId.trim();
    final uid = ownerId.trim();
    if (id.isEmpty || uid.isEmpty) throw ArgumentError('بيانات اللايف غير مكتملة.');

    await db.runTransaction((transaction) async {
      final ref = _sessions.doc(id);
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) throw StateError('اللايف غير موجود.');
      if (data['ownerId']?.toString() != uid) throw StateError('ليس لديك صلاحية تعديل هذا اللايف.');
      if (data['status']?.toString() != LiveSessionStatus.live.name) return;

      final now = Timestamp.now();
      final segments = _closeOpenSegment(data['segments'], now);
      transaction.update(ref, {
        'currentMode': LiveMode.normal.name,
        'currentSkillId': '',
        'status': LiveSessionStatus.ended.name,
        'endedAt': now,
        'updatedAt': now,
        'segments': segments,
      });
    });
  }

  Future<void> _switchMode({
    required String sessionId,
    required String ownerId,
    required LiveMode mode,
    String skillId = '',
  }) async {
    final id = sessionId.trim();
    final uid = ownerId.trim();
    final cleanSkillId = skillId.trim();
    if (id.isEmpty || uid.isEmpty) throw ArgumentError('بيانات اللايف غير مكتملة.');
    if (mode == LiveMode.skill && (cleanSkillId.isEmpty || cleanSkillId.length > 200)) {
      throw ArgumentError('المهارة المحددة غير صالحة.');
    }

    await db.runTransaction((transaction) async {
      final ref = _sessions.doc(id);
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) throw StateError('اللايف غير موجود.');
      if (data['ownerId']?.toString() != uid) throw StateError('ليس لديك صلاحية تعديل هذا اللايف.');
      if (data['status']?.toString() != LiveSessionStatus.live.name) {
        throw StateError('اللايف انتهى بالفعل.');
      }

      final currentMode = data['currentMode']?.toString() == LiveMode.skill.name
          ? LiveMode.skill
          : LiveMode.normal;
      final currentSkill = data['currentSkillId']?.toString() ?? '';
      if (currentMode == mode && (mode != LiveMode.skill || currentSkill == cleanSkillId)) return;

      final now = Timestamp.now();
      final segments = _closeOpenSegment(data['segments'], now);
      final newSegments = List<Map<String, dynamic>>.from(segments);
      newSegments.add({
        'id': ref.id + '_' + now.millisecondsSinceEpoch.toString(),
        'mode': mode.name,
        'skillId': mode == LiveMode.skill ? cleanSkillId : '',
        'startedAt': now,
      });

      transaction.update(ref, {
        'currentMode': mode.name,
        'currentSkillId': mode == LiveMode.skill ? cleanSkillId : '',
        'updatedAt': now,
        'segments': newSegments,
      });
    });
  }

  List<Map<String, dynamic>> _closeOpenSegment(dynamic rawSegments, Timestamp endedAt) {
    if (rawSegments is! List) return <Map<String, dynamic>>[];
    return rawSegments.whereType<Map>().map((raw) {
      final segment = Map<String, dynamic>.from(raw);
      if (!segment.containsKey('endedAt')) segment['endedAt'] = endedAt;
      return segment;
    }).toList();
  }

  Map<String, dynamic> _normalizeFirestoreData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    for (final key in const ['createdAt', 'endedAt']) {
      final value = normalized[key];
      if (value is Timestamp) normalized[key] = value.toDate().toUtc().toIso8601String();
    }
    final rawSegments = normalized['segments'];
    if (rawSegments is List) {
      normalized['segments'] = rawSegments.whereType<Map>().map((raw) {
        final segment = Map<String, dynamic>.from(raw);
        for (final key in const ['startedAt', 'endedAt']) {
          final value = segment[key];
          if (value is Timestamp) segment[key] = value.toDate().toUtc().toIso8601String();
        }
        return segment;
      }).toList();
    }
    return normalized;
  }
}
