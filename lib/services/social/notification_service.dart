import 'package:cloud_firestore/cloud_firestore.dart';

class AurenNotification {
  final String id, title, body, type;
  final String? actorUid, targetId, entityId, conversationId;
  final bool read;
  final DateTime? createdAt;

  const AurenNotification({
    required this.id, required this.title, required this.body, required this.type,
    required this.read, this.actorUid, this.targetId, this.entityId, this.conversationId, this.createdAt,
  });

  factory AurenNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final timestamp = d['createdAt'];
    return AurenNotification(
      id: doc.id,
      title: (d['title'] as String? ?? 'AUREN').trim(),
      body: (d['body'] as String? ?? '').trim(),
      type: (d['type'] as String? ?? 'system').trim(),
      actorUid: d['actorUid'] as String?,
      targetId: d['targetId'] as String?,
      entityId: d['entityId'] as String?,
      conversationId: d['conversationId'] as String?,
      read: d['read'] == true,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

class AurenNotificationService {
  final FirebaseFirestore _db;
  AurenNotificationService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<AurenNotification>> watch(String uid, {int limit = 100}) =>
      _collection(uid).orderBy('createdAt', descending: true).limit(limit.clamp(1, 100))
          .snapshots().map((s) => s.docs.map(AurenNotification.fromDoc).toList());

  Stream<int> watchUnreadCount(String uid) =>
      _collection(uid).where('read', isEqualTo: false).limit(100).snapshots().map((s) => s.size);

  Future<void> markRead(String uid, String id) => _collection(uid).doc(id).update({'read': true});
  Future<void> markUnread(String uid, String id) => _collection(uid).doc(id).update({'read': false});

  Future<void> markAllRead(String uid) async {
    final snapshot = await _collection(uid).where('read', isEqualTo: false).limit(100).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snapshot.docs) { batch.update(doc.reference, {'read': true}); }
    await batch.commit();
  }
}
