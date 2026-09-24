import 'package:cloud_firestore/cloud_firestore.dart';
import '../goals/goal_repository.dart';
import '../memory/memory_repository.dart';

class AurenSkillCoachPlan {
  final String skill, goalTitle, level;
  final List<String> strengths, gaps, actions;
  const AurenSkillCoachPlan({required this.skill,required this.goalTitle,required this.level,required this.strengths,required this.gaps,required this.actions});
}
class AurenSkillCoachService {
  final FirebaseFirestore _db; final GoalRepository _goals; final MemoryRepository _memory;
  AurenSkillCoachService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance,_goals=GoalRepository(firestore:firestore),_memory=MemoryRepository(firestore:firestore);
  Future<AurenSkillCoachPlan> build(String uid,{String? skill}) async {
    final goals=await _goals.watch(uid).first; final memories=await _memory.watch(uid).first;
    final active=goals.where((g)=>g.status=='active').toList()..sort((a,b)=>a.progress.compareTo(b.progress));
    final goal=active.isEmpty?null:active.first; final enabled=memories.where((m)=>m.enabled).toList();
    final chosen=skill?.trim().isNotEmpty==true?skill!.trim():(enabled.isNotEmpty?enabled.first.key:(goal?.title??'مهارة جديدة'));
    final progress=goal?.progress??0; final level=progress>=75?'متقدم':progress>=40?'متوسط':'مبتدئ';
    final strengths=<String>['لديك سياق مرتبط بـ'+chosen]; if(goal!=null) strengths.add('هدف نشط بتقدم '+goal.progress.toString()+'%');
    final gaps=<String>['زيادة التطبيق العملي','اختبار المهارة في موقف حقيقي','تحويل التعلم إلى نتيجة قابلة للقياس'];
    final actions=<String>['اختر مهمة صغيرة مرتبطة بـ'+chosen+' ونفذها اليوم','راجع النتيجة وسجل ما يحتاج تحسينًا','طبّق المهارة في هدفك: '+(goal?.title??'هدف جديد'),'حوّل أفضل نتيجة إلى مثال أو عمل قابل للعرض'];
    await _db.collection('users').doc(uid).collection('skill_coach').doc('current').set({'skill':chosen,'goalTitle':goal?.title??'لا يوجد هدف نشط','level':level,'strengths':strengths,'gaps':gaps,'actions':actions,'updatedAt':FieldValue.serverTimestamp()});
    return AurenSkillCoachPlan(skill:chosen,goalTitle:goal?.title??'لا يوجد هدف نشط',level:level,strengths:strengths,gaps:gaps,actions:actions);
  }
}