import 'package:cloud_firestore/cloud_firestore.dart';

class AurenNotification {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const AurenNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AurenNotification.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['createdAt'];
    return AurenNotification(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}

class NotificationRepository {
  final FirebaseFirestore _db;
  NotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<AurenNotification>> watch(String uid) => _items(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => AurenNotification.fromMap(d.id, d.data())).toList());

  Stream<int> watchUnreadCount(String uid) => _items(uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);

  Future<void> markRead(String uid, String id) =>
      _items(uid).doc(id).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final snap = await _items(uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
