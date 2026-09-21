import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/creator.dart';

class CreatorRepository {
  final FirebaseFirestore db;
  CreatorRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Stream<List<AurenCreatorDraft>> watchDrafts(String uid) => db.collection('creator_drafts').where('ownerId', isEqualTo: uid).snapshots().map((s) { final list = s.docs.map((d) => AurenCreatorDraft.fromMap(d.id, d.data())).toList(); list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))); return list; });
  Future<String> createDraft({required String uid, required String title, required String body}) async { final r = db.collection('creator_drafts').doc(); await r.set({'ownerId': uid, 'title': title.trim(), 'body': body.trim(), 'status': 'draft', 'createdAt': FieldValue.serverTimestamp()}); return r.id; }
  Future<void> updateDraft(String id, String title, String body) => db.collection('creator_drafts').doc(id).update({'title': title.trim(), 'body': body.trim(), 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> publish(String id) => db.collection('creator_drafts').doc(id).update({'status': 'published', 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> deleteDraft(String uid,String id) => db.collection('creator_drafts').doc(id).delete();
}
