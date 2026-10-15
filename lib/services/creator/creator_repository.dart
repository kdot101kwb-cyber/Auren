import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/creator.dart';

class CreatorRepository {
  final FirebaseFirestore db;
  CreatorRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenCreatorDraft>> watchDrafts(String uid) => db
      .collection('creator_drafts')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => AurenCreatorDraft.fromMap(d.id, d.data()))
            .toList();
        list.sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
        return list;
      });

  Future<String> createDraft({
    required String uid,
    required String title,
    required String body,
  }) async {
    final ref = db.collection('creator_drafts').doc();
    await ref.set({
      'ownerId': uid,
      'title': title.trim(),
      'body': body.trim(),
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateDraft(String id, String title, String body) =>
      db.collection('creator_drafts').doc(id).update({
        'title': title.trim(),
        'body': body.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Publishes a draft and records its post ID in one Firestore transaction.
  ///
  /// The transaction makes the status check and post creation atomic, so two
  /// concurrent publish requests cannot create duplicate posts for one draft.
  Future<void> publish(String id, {String contentType = 'moment'}) async {
    const allowed = {'moment', 'idea', 'question', 'project', 'opportunity'};
    if (!allowed.contains(contentType)) {
      throw ArgumentError('نوع النشر غير مدعوم.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('يجب تسجيل الدخول للنشر.');

    final draftRef = db.collection('creator_drafts').doc(id);
    final postRef = db.collection('posts').doc();

    await db.runTransaction((transaction) async {
      final snap = await transaction.get(draftRef);
      if (!snap.exists) throw StateError('المسودة غير موجودة.');

      final data = snap.data() ?? <String, dynamic>{};
      if (data['ownerId'] != uid) throw StateError('لا تملك هذه المسودة.');
      // Idempotent: if a previous request already published the draft, do not
      // create a second post. This check is inside the transaction to avoid a
      // race between simultaneous publish requests.
      if (data['status'] == 'published') return;
      if (data['status'] != 'draft') {
        throw StateError('لا يمكن نشر مسودة في هذه الحالة.');
      }

      final title = data['title']?.toString().trim() ?? '';
      final body = data['body']?.toString().trim() ?? '';
      if (title.isEmpty || body.isEmpty) {
        throw StateError('العنوان والمحتوى مطلوبان.');
      }

      final text = '$title\n\n$body';
      transaction.set(postRef, {
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
      transaction.update(draftRef, {
        'status': 'published',
        'publishedPostId': postRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteDraft(String uid, String id) async {
    final ref = db.collection('creator_drafts').doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()?['ownerId'] != uid) {
      throw StateError('لا تملك هذه المسودة.');
    }
    if (snap.data()?['status'] == 'published') {
      throw StateError('لا يمكن حذف مسودة تم نشرها.');
    }
    await ref.delete();
  }
}
