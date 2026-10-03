import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/goals/goal_repository.dart';

class AurenDailyPlan {
  final String goalId, goalTitle, focus;
  final List<String> steps;
  final DateTime generatedAt;
  const AurenDailyPlan({required this.goalId, required this.goalTitle, required this.focus, required this.steps, required this.generatedAt});
  Map<String,dynamic> toMap()=>{
    'goalId':goalId,'goalTitle':goalTitle,'focus':focus,'steps':steps,
    'generatedAt':Timestamp.fromDate(generatedAt.toUtc()),
  };
}

class DailyPlanTask {
  final String id, title;
  final int order;
  final bool completed;
  final Timestamp? completedAt;
  const DailyPlanTask({required this.id,required this.title,required this.order,required this.completed,this.completedAt});
  factory DailyPlanTask.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final data=doc.data()??<String,dynamic>{};
    return DailyPlanTask(
      id:doc.id,
      title:data['title']?.toString()??'',
      order:(data['order'] as num?)?.toInt()??0,
      completed:data['completed']==true,
      completedAt:data['completedAt'] is Timestamp?data['completedAt'] as Timestamp:null,
    );
  }
}

class DailyPlanService {
  final FirebaseFirestore _db;
  final GoalRepository _goals;
  DailyPlanService({FirebaseFirestore? firestore,GoalRepository? goals}):_db=firestore??FirebaseFirestore.instance,_goals=goals??GoalRepository();

  CollectionReference<Map<String,dynamic>> _tasks(String uid)=>
      _db.collection('users').doc(uid).collection('daily_plans').doc('current').collection('tasks');

  Stream<List<DailyPlanTask>> watchTasks(String uid)=>_tasks(uid)
      .orderBy('order')
      .snapshots()
      .map((s)=>s.docs.map(DailyPlanTask.fromDoc).toList());

  Future<void> setTaskCompleted(String uid,String taskId,bool completed) async {
    final task=_tasks(uid).doc(taskId);
    final snap=await task.get();
    if(!snap.exists) return;
    await task.update({'completed':completed,'completedAt':completed?FieldValue.serverTimestamp():null});
    final all=await _tasks(uid).get();
    final done=all.docs.where((d)=>d.data()['completed']==true).length;
    await _db.collection('users').doc(uid).collection('daily_plans').doc('current').set({
      'status':all.docs.isEmpty?'empty':done==all.size?'completed':'active',
      'completedTasks':done,
      'taskCount':all.size,
      'updatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
  }

  Future<AurenDailyPlan> build(String uid)async{
    final goals=await _goals.watch(uid).first;
    final active=goals.where((g)=>g.status=='active').toList()..sort((a,b)=>a.progress.compareTo(b.progress));
    final g=active.isEmpty?null:active.first;
    final title=g?.title??'لا يوجد هدف نشط';
    final focus=g==null?'أنشئ هدفًا واحدًا واضحًا لليوم.':g.progress<30?'ابدأ بأصغر خطوة قابلة للتنفيذ.':g.progress<70?'ادفع الهدف خطوة عملية إلى الأمام.':'أكمل آخر جزء وحوّل التقدم إلى نتيجة.';
    final steps=g==null?['أنشئ هدفًا واحدًا','اكتب النتيجة المطلوبة','حدد أول خطوة لمدة 15 دقيقة']:['حدد نتيجة اليوم لهذا الهدف','نفّذ جلسة تركيز واحدة','سجّل ما أنجزته وحدّث التقدم'];
    final p=AurenDailyPlan(goalId:g?.id??'',goalTitle:title,focus:focus,steps:steps,generatedAt:DateTime.now());
    final planRef=_db.collection('users').doc(uid).collection('daily_plans').doc('current');
    await planRef.set({...p.toMap(),'planDate':DateTime.now().toIso8601String().substring(0,10),'status':'active','completedTasks':0,'taskCount':steps.length,'updatedAt':FieldValue.serverTimestamp()});
    final old=await _tasks(uid).get();
    final batch=_db.batch();
    for(final doc in old.docs){batch.delete(doc.reference);}
    for(var i=0;i<steps.length;i++){batch.set(_tasks(uid).doc(),{'title':steps[i],'order':i,'completed':false,'completedAt':null,'createdAt':FieldValue.serverTimestamp()});}
    await batch.commit();
    return p;
  }
}