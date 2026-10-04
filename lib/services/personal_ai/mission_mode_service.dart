import 'package:cloud_firestore/cloud_firestore.dart';
import 'next_move_service.dart';
class AurenMission { final String goalTitle,mission,firstStep; final int progress; const AurenMission({required this.goalTitle,required this.mission,required this.firstStep,required this.progress}); }
class MissionModeService {
 final FirebaseFirestore db; MissionModeService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 Future<AurenMission> build(String uid) async {
  final s=await db.collection('users').doc(uid).collection('goals').limit(50).get(); final a=s.docs.where((d)=>(d.data()['status']?.toString()??'active')=='active').toList();
  if(a.isEmpty)return const AurenMission(goalTitle:'لا يوجد هدف',mission:'أنشئ هدفًا واضحًا لتبدأ Mission Mode.',firstStep:'افتح Goal → Reality وأنشئ أول هدف.',progress:0);
  a.sort((x,y)=>((x.data()['progress'] as num?)?.toInt()??0).compareTo((y.data()['progress'] as num?)?.toInt()??0)); final x=a.first.data(); final title=(x['title']??'هدفك').toString(); final p=(((x['progress'] as num?)?.toInt()??0).clamp(0,100)).toInt();
  final move=await NextMoveService(firestore:db).build(uid); return AurenMission(goalTitle:title,mission:'ركّز على '+title+' بدون تشتيت حتى تصل للنتيجة التالية.',firstStep:move.action,progress:p);
 }
}