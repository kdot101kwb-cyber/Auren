import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Stream<List<AurenEntertainmentItem>> watchItems({String? type}) { Query<Map<String, dynamic>> q = db.collection('entertainment_items').where('visibility', isEqualTo: 'public'); if (type != null) q = q.where('type', isEqualTo: type); return q.limit(100).snapshots().map((s) => s.docs.map((d) => AurenEntertainmentItem.fromMap(d.id, d.data())).toList()); }
  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedEntertainment').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> save(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).set({'itemId': itemId, 'createdAt': FieldValue.serverTimestamp()});
  Future<void> unsave(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).delete();
}