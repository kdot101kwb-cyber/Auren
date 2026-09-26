import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/entertainment.dart';

class EntertainmentRepository {
  final FirebaseFirestore db;
  EntertainmentRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenEntertainmentItem>> watchItems({String? type}) {
    Query<Map<String, dynamic>> q = db.collection('entertainment_items').where('visibility', isEqualTo: 'public');
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.limit(100).snapshots().map((s) => s.docs.map((d) => AurenEntertainmentItem.fromMap(d.id, d.data())).toList());
  }

  Stream<List<AurenEntertainmentItem>> watchShorts({String? mood}) {
    Query<Map<String, dynamic>> q = db.collection('entertainment_items')
      .where('visibility', isEqualTo: 'public')
      .where('type', isEqualTo: 'Short');
    if (mood != null && mood.isNotEmpty && mood != 'تسلية') {
      q = q.where('moods', arrayContains: mood);
    }
    return q.limit(50).snapshots().map((s) => s.docs
      .map((d) => AurenEntertainmentItem.fromMap(d.id, d.data()))
      .where((i) => i.isVideo && i.mediaUrl.isNotEmpty)
      .toList());
  }

  Stream<AurenEntertainmentItem?> watchItem(String itemId) => db.collection('entertainment_items').doc(itemId).snapshots().map((d) {
    final data = d.data();
    if (!d.exists || data == null || data['visibility'] != 'public') return null;
    return AurenEntertainmentItem.fromMap(d.id, data);
  });

  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedEntertainment').snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> save(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).set({'itemId': itemId, 'createdAt': FieldValue.serverTimestamp()});
  Future<void> unsave(String uid, String itemId) => db.collection('users').doc(uid).collection('savedEntertainment').doc(itemId).delete();

  Future<void> toggleLike(String uid, String itemId, bool liked) => db.collection('entertainment_items').doc(itemId).collection('likes').doc(uid).set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> toggleShortLike(String uid, String itemId, bool liked) async {
    final ref = db.collection('entertainment_items').doc(itemId).collection('likes').doc(uid);
    if (liked) {
      await ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }


  Future<void> trackShortView(String uid, String itemId, {required int seconds, required bool completed, required String mood}) =>
      db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId).set({
        'itemId': itemId,
        'lastViewedAt': FieldValue.serverTimestamp(),
        'watchSeconds': FieldValue.increment(seconds),
        'views': FieldValue.increment(1),
        'completed': completed,
        'mood': mood,
      }, SetOptions(merge: true));

  Future<void> trackShortAction(String uid, String itemId, {required String action, required String mood}) =>
      db.collection('users').doc(uid).collection('entertainmentSignals').doc(itemId).collection('actions').add({
        'action': action,
        'mood': mood,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<bool> watchLiked(String uid, String itemId) => db.collection('entertainment_items').doc(itemId).collection('likes').doc(uid).snapshots().map((d) => d.exists);

  Stream<List<AurenEntertainmentItem>> watchSavedItems(String uid) => db.collection('users').doc(uid).collection('savedEntertainment').snapshots().asyncMap((s) async {
    final out=<AurenEntertainmentItem>[];
    for(final d in s.docs) {
      final item=await db.collection('entertainment_items').doc(d.id).get();
      if(item.exists && (item.data()?['visibility']=='public')) out.add(AurenEntertainmentItem.fromMap(item.id,item.data()!));
    }
    return out;
  });
}