import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_profile.dart';
class UserSearchRepository{
 final FirebaseFirestore _db;
 UserSearchRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 Future<List<AurenUserProfile>> search(String text)async{
  final q=text.trim().toLowerCase(); if(q.isEmpty)return [];
  final snap=await _db.collection('users').orderBy('displayNameLower').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
  return snap.docs.map((d)=>AurenUserProfile.fromMap(d.id,d.data())).toList();
 }
}