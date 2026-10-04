import 'package:cloud_firestore/cloud_firestore.dart';

class AurenMemoryTimelineEvent {
  final String id, memoryId, key, value, action;
  final DateTime createdAt;
  const AurenMemoryTimelineEvent({required this.id, required this.memoryId, required this.key, required this.value, required this.action, required this.createdAt});

  factory AurenMemoryTimelineEvent.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['createdAt'];
    final createdAt = raw is Timestamp ? raw.toDate() : DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return AurenMemoryTimelineEvent(
      id: id, memoryId: data['memoryId']?.toString() ?? '', key: data['key']?.toString() ?? '',
      value: data['value']?.toString() ?? '', action: data['action']?.toString() ?? 'updated', createdAt: createdAt);
  }
}

class MemoryTimelineRepository {
  final FirebaseFirestore _db;
  MemoryTimelineRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _events(String uid) => _db.collection('users').doc(uid).collection('memory_timeline');

  Stream<List<AurenMemoryTimelineEvent>> watch(String uid, {int limit = 100}) => _events(uid)
      .orderBy('createdAt', descending: true).limit(limit.clamp(1, 200).toInt())
      .snapshots().map((s) => s.docs.map((d) => AurenMemoryTimelineEvent.fromMap(d.id, d.data())).toList());

  Future<void> record({required String uid, required String memoryId, required String key, required String value, required String action}) async {
    final cleanUid = uid.trim(), cleanId = memoryId.trim(), cleanKey = key.trim(), cleanValue = value.trim();
    if (cleanUid.isEmpty || cleanId.isEmpty || cleanKey.isEmpty) return;
    await _events(cleanUid).add({
      'memoryId': cleanId,
      'key': cleanKey.length > 120 ? cleanKey.substring(0, 120) : cleanKey,
      'value': cleanValue.length > 2000 ? cleanValue.substring(0, 2000) : cleanValue,
      'action': action,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}