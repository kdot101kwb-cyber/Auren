import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/comment.dart';

class CommentRepository {
  final FirebaseFirestore _db;
  CommentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _db.collection('posts').doc(postId).collection('comments');

  Stream<List<AurenComment>> watch(String postId) => _comments(postId)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map((d) => AurenComment.fromMap(d.id, d.data())).toList());

  Future<void> create(AurenComment comment) async {
    final postRef = _db.collection('posts').doc(comment.postId);
    final commentRef = _comments(comment.postId).doc(comment.id);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw StateError('Post not found.');

      final existing = await tx.get(commentRef);
      if (existing.exists) return;

      final data = postSnap.data() ?? {};
      final count = (data['comments'] as num?)?.toInt() ?? 0;
      tx.set(commentRef, comment.toMap());
      tx.update(postRef, {'comments': count + 1});
    });
  }
}