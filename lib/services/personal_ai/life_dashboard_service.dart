import 'package:cloud_firestore/cloud_firestore.dart';
class AurenLifeDashboard { final int activeGoals,memories,businesses,products,posts,opportunities,averageProgress; const AurenLifeDashboard({required this.activeGoals,required this.memories,required this.businesses,required this.products,required this.posts,required this.opportunities,required this.averageProgress}); }
class LifeDashboardService {
 final FirebaseFirestore db; LifeDashboardService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 Future<AurenLifeDashboard> load(String uid) async {
  final r=await Future.wait([db.collection('users').doc(uid).collection('goals').limit(100).get(),db.collection('users').doc(uid).collection('memory').where('enabled',isEqualTo:true).limit(100).get(),db.collection('businesses').where('ownerId',isEqualTo:uid).limit(100).get(),db.collection('products').where('ownerId',isEqualTo:uid).limit(100).get(),db.collection('posts').where('authorId',isEqualTo:uid).limit(100).get()]);
  final g=r[0] as QuerySnapshot<Map<String,dynamic>>; final a=g.docs.where((d)=>(d.data()['status']?.toString()??'active')=='active').toList();
  final avg=a.isEmpty?0:a.fold<int>(0,(s,d)=>s+((d.data()['progress'] as num?)?.toInt()??0))~/a.length;
  QuerySnapshot<Map<String,dynamic>>? o; try{o=await db.collection('opportunities').where('visibility',isEqualTo:'public').limit(100).get();}catch(_){}
  return AurenLifeDashboard(activeGoals:a.length,memories:(r[1] as QuerySnapshot).size,businesses:(r[2] as QuerySnapshot).size,products:(r[3] as QuerySnapshot).size,posts:(r[4] as QuerySnapshot).size,opportunities:o?.size??0,averageProgress:avg);
 }
}