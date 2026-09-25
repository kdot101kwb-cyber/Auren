import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Stream<List<AurenEntertainmentItem>> watchItems({String? type}) { Query<Map<String, dynamic>> q = db.collection('entertainment_items').where('visibility', isEqualTo: 'public'); if (type != null) q = q.where('type', isEqualTo: type); return q.limit(100).snapshots().map((s) => s.docs.map((d) => AurenEntertainmentItem.fromMap(d.id, d.data())).toList()); }
  Stream<AurenEntertainmentItem?> watchItem(String itemId) => db.collection('entertainment_items').doc(itemId).snapshots().map((d) { final data=d.data(); if (!d.exists || data == null || data['visibility'] != 'public') return null; return AurenEntertainmentItem.fromMap(d.id, data); });
  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedEntertainment').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> save(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).set({'itemId': itemId, 'createdAt': FieldValue.serverTimestamp()});
  Future<void> unsave(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).delete();
  Stream<List<AurenEntertainmentItem>> watchSavedItems(String uid) => db.collection('users').doc(uid).collection('savedEntertainment').snapshots().asyncMap((s) async { final out=<AurenEntertainmentItem>[]; for(final d in s.docs){ final item=await db.collection('entertainment_items').doc(d.id).get(); if(item.exists && (item.data()?['visibility']=='public')) out.add(AurenEntertainmentItem.fromMap(item.id,item.data()!)); } return out; });
}
