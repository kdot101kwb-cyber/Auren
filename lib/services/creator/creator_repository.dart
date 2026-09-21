import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/creator.dart';

class CreatorRepository {
  final FirebaseFirestore db;
  CreatorRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;
  Stream<List<AurenCreatorDraft>> watchDrafts(String uid) => db.collection('creator_drafts').where('ownerId', isEqualTo: uid).snapshots().map((s) { final list = s.docs.map((d) => AurenCreatorDraft.fromMap(d.id, d.data())).toList(); list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))); return list; });
  Future<String> createDraft({required String uid, required String title, required String body}) async { final r = db.collection('creator_drafts').doc(); await r.set({'ownerId': uid, 'title': title.trim(), 'body': body.trim(), 'status': 'draft', 'createdAt': FieldValue.serverTimestamp()}); return r.id; }
  Future<void> updateDraft(String id, String title, String body) => db.collection('creator_drafts').doc(id).update({'title': title.trim(), 'body': body.trim(), 'updatedAt': FieldValue.serverTimestamp()});
  Future<void> publish(String id, {String contentType = 'moment'}) async {
    const allowed = {'moment', 'idea', 'question', 'project', 'opportunity'};
    if (!allowed.contains(contentType)) throw ArgumentError('نوع النشر غير مدعوم.');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('يجب تسجيل الدخول للنشر.');
    final draftRef = db.collection('creator_drafts').doc(id);
    final snap = await draftRef.get();
    if (!snap.exists) throw StateError('المسودة غير موجودة.');
    final data = snap.data() ?? <String, dynamic>{};
    if (data['ownerId'] != uid) throw StateError('لا تملك هذه المسودة.');
    if (data['status'] == 'published') return;
    final title = data['title']?.toString().trim() ?? '';
    final body = data['body']?.toString().trim() ?? '';
    if (title.isEmpty || body.isEmpty) throw StateError('العنوان والمحتوى مطلوبان.');
    final postRef = db.collection('posts').doc();
    final text = '$title\n\n$body';
    final batch = db.batch();
    batch.set(postRef, {
      'authorId': uid,
      'text': text,
      'mediaUrl': '',
      'mediaType': 'none',
      'contentType': contentType,
      'contextLabel': 'Creator Studio',
      'actionLabel': 'تواصل',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'likes': 0,
      'comments': 0,
      'searchText': text.toLowerCase(),
    });
    batch.update(draftRef, {
      'status': 'published',
      'publishedPostId': postRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
  Future<void> deleteDraft(String uid,String id) => db.collection('creator_drafts').doc(id).delete();
}
