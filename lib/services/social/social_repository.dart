import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/follow.dart';
import '../../core/models/profile.dart';
class SocialRepository {
 final FirebaseFirestore _db;
 SocialRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 Future<void> saveProfile(AurenProfile p)=>_db.collection('profiles').doc(p.uid).set(p.toMap(),SetOptions(merge:true));
 Stream<AurenProfile?> watchProfile(String uid)=>_db.collection('profiles').doc(uid).snapshots().map((d)=>d.exists?AurenProfile.fromMap(uid,d.data()!):null);
 Future<void> follow(String follower,String following){final f=AurenFollow(followerId:follower,followingId:following,createdAt:DateTime.now());return _db.collection('follows').doc(follower+'_'+following).set(f.toMap());}
 Future<void> unfollow(String follower,String following)=>_db.collection('follows').doc(follower+'_'+following).delete();
}