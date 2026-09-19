import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_profile.dart';
class UserSearchRepository{
 final FirebaseFirestore _db;
 UserSearchRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 Future<List<AurenUserProfile>> search(String term)async{
  final q=term.trim().toLowerCase(); if(q.isEmpty)return const [];
  final s=await _db.collection('users').orderBy('displayNameLower').startAt([q]).endAt(['$q\uf8ff']).limit(20).get();
  return s.docs.map((d)=>AurenUserProfile.fromMap(d.id,d.data())).toList();
 }
}