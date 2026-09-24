import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/talent_scout.dart';

class TalentScoutRepository {
  final FirebaseFirestore db;
  TalentScoutRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  Stream<List<AurenTalentScout>> watch(String uid)=>db.collection('users').doc(uid).collection('talent_scouts').orderBy('updatedAt',descending:true).limit(20).snapshots().map((s)=>s.docs.map((d)=>AurenTalentScout.fromMap(d.id,d.data())).toList());
  Future<void> upsert({required String uid,required String id,required String name,required String role,required String description,required bool enabled,List<String> interests=const [],List<String> skills=const []}) async {
    String clean(String v)=>v.trim();
    List<String> norm(Iterable<String> v,int max)=>v.map(clean).where((x)=>x.isNotEmpty).map((x)=>x.toLowerCase()).toSet().take(max).toList();
    await db.collection('users').doc(uid).collection('talent_scouts').doc(id).set({'ownerId':uid,'name':clean(name),'role':clean(role),'description':clean(description),'enabled':enabled,'interests':norm(interests,20),'skills':norm(skills,30),'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
  }
  Future<void> setEnabled(String uid,String id,bool enabled)=>db.collection('users').doc(uid).collection('talent_scouts').doc(id).update({'enabled':enabled,'updatedAt':FieldValue.serverTimestamp()});
}