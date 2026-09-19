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
      final data = snap.data() ?? {};
      final count = (data['likes'] as num?)?.toInt() ?? 0;
      if (liked) {
        tx.delete(like);
        tx.update(ref, {'likes': count > 0 ? count - 1 : 0});
      } else {
        tx.set(like, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(ref, {'likes': count + 1});
      }
    });
  }

  Stream<bool> watchLiked(String postId, String uid) =>
      _posts.doc(postId).collection('likes').doc(uid).snapshots().map((d) => d.exists);
}