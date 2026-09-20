import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/post.dart';

class PostRepository {
  final FirebaseFirestore _db;
  PostRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  Stream<List<AurenPost>> watchFeed() => _posts
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => AurenPost.fromMap(d.id, d.data())).toList());

  Future<void> create(AurenPost post) => _posts.doc(post.id).set({
    ...post.toMap(),
    'searchText': post.text.trim().toLowerCase(),
  });

  Future<void> toggleLike(String postId, String uid, bool liked) async {
    final ref = _posts.doc(postId);
    final like = ref.collection('likes').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Post not found.');
      final likeSnap = await tx.get(like);
      final data = snap.data() ?? {};
      final count = (data['likes'] as num?)?.toInt() ?? 0;
      if (liked) {
        if (!likeSnap.exists) return;
        tx.delete(like);
        tx.update(ref, {'likes': count > 0 ? count - 1 : 0});
      } else {
        if (likeSnap.exists) return;
        tx.set(like, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(ref, {'likes': count + 1});
      }
    });
  }

  Stream<bool> watchLiked(String postId, String uid) =>
      _posts.doc(postId).collection('likes').doc(uid).snapshots().map((d) => d.exists);

  CollectionReference<Map<String, dynamic>> _saved(String uid) =>
      _db.collection('users').doc(uid).collection('savedPosts');

  Stream<bool> watchSaved(String postId, String uid) =>
      _saved(uid).doc(postId).snapshots().map((d) => d.exists);

  Future<void> toggleSaved(String postId, String uid, bool saved) async {
    final ref = _saved(uid).doc(postId);
    if (saved) {
      await ref.delete();
    } else {
      await ref.set({
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  CollectionReference<Map<String, dynamic>> _reactions(String postId) =>
      _posts.doc(postId).collection('reactions');

  Stream<String?> watchReaction(String postId, String uid) =>
      _reactions(postId).doc(uid).snapshots().map((d) => d.data()?['type'] as String?);

  Future<void> setReaction(String postId, String uid, String? type) async {
    final ref = _reactions(postId).doc(uid);
    if (type == null) {
      await ref.delete();
      return;
    }
    await ref.set({
      'type': type,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
