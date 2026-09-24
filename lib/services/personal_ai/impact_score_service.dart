import 'package:cloud_firestore/cloud_firestore.dart';
import '../goals/goal_repository.dart';
import '../memory/memory_repository.dart';

class AurenImpactScore {
 final int score; final List<String> strengths, actions; final String headline;
 const AurenImpactScore({required this.score,required this.strengths,required this.actions,required this.headline});
 Map<String,dynamic> toMap()=>{'score':score,'headline':headline,'strengths':strengths,'actions':actions,'updatedAt':FieldValue.serverTimestamp()};
}
class ImpactScoreService {
 final GoalRepository goals; final MemoryRepository memory; final FirebaseFirestore db;
 ImpactScoreService({GoalRepository? goals,MemoryRepository? memory,FirebaseFirestore? firestore}):goals=goals??GoalRepository(),memory=memory??MemoryRepository(),db=firestore??FirebaseFirestore.instance;
 Future<AurenImpactScore> calculate(String uid) async {
  final gs=await goals.watch(uid).first; final ms=await memory.watch(uid).first;
  final active=gs.where((g)=>g.status=='active').toList(); final completed=gs.where((g)=>g.status=='completed').length;
  final avg=active.isEmpty?0:active.map((g)=>g.progress).fold<double>(0,(a,b)=>a+b)/active.length;
  final enabled=ms.where((m)=>m.enabled).length;
  var score=(avg*0.55+completed*8+enabled*3).round(); if(score>100)score=100;
  final strengths=<String>[]; final actions=<String>[];
  if(completed>0)strengths.add('لديك أهداف مكتملة'); else actions.add('أكمل أول هدف قابل للتنفيذ');
  if(avg>=70)strengths.add('تقدم قوي في الأهداف النشطة'); else actions.add('ارفع تقدم الهدف النشط بخطوة صغيرة');
  if(enabled>0)strengths.add('لديك ذاكرة شخصية مفعلة'); else actions.add('فعّل ما تحتاجه من الذاكرة الشخصية');
  final headline=score>=70?'تقدمك الحالي يعطيك أساساً جيداً للبناء':score>=40?'لديك تقدم يمكن تحويله إلى نتائج':'ابدأ بخطوة صغيرة قابلة للقياس';
  final result=AurenImpactScore(score:score,headline:headline,strengths:strengths,actions:actions);
  await db.collection('users').doc(uid).collection('impact_scores').doc('current').set(result.toMap()); return result;
 }
}