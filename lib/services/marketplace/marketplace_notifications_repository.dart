import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceNotificationsRepository {
  final FirebaseFirestore db;
  MarketplaceNotificationsRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watch(String uid) {
    return db
        .collection('marketplace_notifications')
        .where('recipientUid', isEqualTo: uid)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> markRead(String id) {
    return db.collection('marketplace_notifications').doc(id).update({'read': true});
  }
}
