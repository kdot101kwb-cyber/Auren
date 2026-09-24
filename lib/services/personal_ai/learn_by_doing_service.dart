import 'package:cloud_firestore/cloud_firestore.dart';
import '../goals/goal_repository.dart';
import '../memory/memory_repository.dart';

class AurenLearnStep {
  final String id,title,description,action;
  final bool completed;
  const AurenLearnStep({required this.id,required this.title,required this.description,required this.action,required this.completed});
  Map<String,dynamic> toMap()=>{'id':id,'title':title,'description':description,'action':action,'completed':completed};
  factory AurenLearnStep.fromMap(Map<String,dynamic> m)=>AurenLearnStep(id:m['id']?.toString()??'',title:m['title']?.toString()??'',description:m['description']?.toString()??'',action:m['action']?.toString()??'',completed:m['completed']==true);
}

class AurenLearnByDoingPlan {
  final String goalTitle,skill; final List<AurenLearnStep> steps; final DateTime? updatedAt;
  const AurenLearnByDoingPlan({required this.goalTitle,required this.skill,required this.steps,this.updatedAt});
}

class AurenLearnByDoingService {
  final FirebaseFirestore _db;
  final GoalRepository _goals;
  final MemoryRepository _memory;
  AurenLearnByDoingService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance,_goals=GoalRepository(firestore:firestore),_memory=MemoryRepository(firestore:firestore);
  Future<AurenLearnByDoingPlan> build(String uid,{String? skill}) async {
    final goals=await _goals.watch(uid).first;
    final memories=await _memory.watch(uid).first;
    final active=goals.where((g)=>g.status=='active').toList()..sort((a,b)=>a.progress.compareTo(b.progress));
    final goal=active.isEmpty?null:active.first;
    final inferred=skill?.trim().isNotEmpty==true?skill!.trim():(memories.where((m)=>m.enabled).isNotEmpty?memories.first.key:(goal?.title??'مهارة جديدة'));
    final title=goal?.title??'تعلم عملي';
    final steps=[
      AurenLearnStep(id:'learn_1',title:'افهم الأساس',description:'حدد المفهوم أو المهارة المطلوبة في سياق هدفك.',action:'اكتب 3 نقاط تريد فهمها عن $inferred',completed:false),
      AurenLearnStep(id:'learn_2',title:'طبّق فورًا',description:'حوّل المعرفة إلى مهمة صغيرة قابلة للتنفيذ.',action:'نفّذ تطبيقًا صغيرًا مرتبطًا بـ$title',completed:false),
      AurenLearnStep(id:'learn_3',title:'اختبر النتيجة',description:'راجع ما نجح وما يحتاج تحسينًا.',action:'سجّل نتيجة التجربة وما ستغيره في المحاولة القادمة',completed:false),
      AurenLearnStep(id:'learn_4',title:'حوّلها إلى قدرة',description:'كرر التطبيق أو استخدمه في فرصة حقيقية.',action:'اختر استخدامًا عمليًا جديدًا لـ$inferred',completed:false),
    ];
    final ref=_db.collection('users').doc(uid).collection('learn_by_doing').doc('current');
    final old=await ref.get();
    final oldSteps=(old.data()?['steps'] as List?)?.map((x)=>AurenLearnStep.fromMap(Map<String,dynamic>.from(x as Map))).toList()??<AurenLearnStep>[];
    final merged=steps.map((s){final o=oldSteps.where((x)=>x.id==s.id);return o.isEmpty?s:AurenLearnStep(id:s.id,title:s.title,description:s.description,action:s.action,completed:o.first.completed);}).toList();
    await ref.set({'goalTitle':title,'skill':inferred,'steps':merged.map((s)=>s.toMap()).toList(),'updatedAt':FieldValue.serverTimestamp()});
    return AurenLearnByDoingPlan(goalTitle:title,skill:inferred,steps:merged,updatedAt:DateTime.now());
  }
  Future<void> toggle(String uid,String stepId,bool completed) async {
    final ref=_db.collection('users').doc(uid).collection('learn_by_doing').doc('current');
    final snap=await ref.get(); final data=snap.data(); if(data==null)return;
    final raw=(data['steps'] as List? )??[];
    final steps=raw.map((x)=>Map<String,dynamic>.from(x as Map)).toList();
    for(final s in steps){if(s['id']==stepId)s['completed']=completed;}
    await ref.update({'steps':steps,'updatedAt':FieldValue.serverTimestamp()});
  }
}