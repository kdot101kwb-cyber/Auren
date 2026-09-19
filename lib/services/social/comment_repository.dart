import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/comment.dart';
class CommentRepository{
 final FirebaseFirestore _db;
 CommentRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> _comments(String postId)=>_db.collection('posts').doc(postId).collection('comments');
 Stream<List<AurenComment>> watch(String postId)=>_comments(postId).orderBy('createdAt').snapshots().map((s)=>s.docs.map((d)=>AurenComment.fromMap(d.id,d.data())).toList());
 Future<void> create(AurenComment c)=>_comments(c.postId).doc(c.id).set(c.toMap());
}