import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/post.dart';
class PostRepository {
 final FirebaseFirestore _db;
 PostRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _posts=>_db.collection('posts');
 Stream<List<AurenPost>> watchFeed()=>_posts.orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>AurenPost.fromMap(d.id,d.data())).toList());
 Future<void> create(AurenPost p)=>_posts.doc(p.id).set(p.toMap());
 Future<void> like(String postId,String uid)=>_posts.doc(postId).collection('likes').doc(uid).set({'createdAt':DateTime.now().toUtc().toIso8601String()});
 Future<void> unlike(String postId,String uid)=>_posts.doc(postId).collection('likes').doc(uid).delete();
}