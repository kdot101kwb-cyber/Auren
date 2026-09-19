import 'package:cloud_firestore/cloud_firestore.dart';
class FollowRepository {
 final FirebaseFirestore _db;
 FollowRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _follows=>_db.collection('follows');
 Stream<bool> watchFollowing(String follower,String following)=>_follows.doc('${follower}_${following}').snapshots().map((d)=>d.exists);
 Future<void> toggle(String follower,String following,bool isFollowing) async {
  final ref=_follows.doc('${follower}_${following}');
  if(isFollowing){await ref.delete();}else{await ref.set({'followerId':follower,'followingId':following,'createdAt':FieldValue.serverTimestamp()});}
 }
 Stream<int> followersCount(String uid)=>_follows.where('followingId',isEqualTo:uid).snapshots().map((s)=>s.size);
 Stream<int> followingCount(String uid)=>_follows.where('followerId',isEqualTo:uid).snapshots().map((s)=>s.size);
}