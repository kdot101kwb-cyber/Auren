import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
class AurenRescueStep { final int order; final String title, action, reason; const AurenRescueStep({required this.order,required this.title,required this.action,required this.reason}); }
class AurenRescuePlan { final String status,summary; final List<AurenRescueStep> steps; final DateTime updatedAt; const AurenRescuePlan({required this.status,required this.summary,required this.steps,required this.updatedAt}); Map<String,dynamic> toMap()=>{'status':status,'summary':summary,'steps':steps.map((s)=>{'order':s.order,'title':s.title,'action':s.action,'reason':s.reason}).toList(),'updatedAt':Timestamp.fromDate(updatedAt.toUtc())}; }
class RescueModeService {
 final FirebaseFirestore _db; final GoalRepository _goals; final MemoryRepository _memory;
 RescueModeService({FirebaseFirestore? firestore,GoalRepository? goals,MemoryRepository? memory}):_db=firestore??FirebaseFirestore.instance,_goals=goals??GoalRepository(),_memory=memory??MemoryRepository();
 Future<AurenRescuePlan> build(String uid) async {
  if(uid.trim().isEmpty) throw ArgumentError('uid is required');
  final goals=await _goals.watch(uid).first; final memories=await _memory.watch(uid).first;
  final active=goals.where((g)=>g.status=='active').toList(); final enabled=memories.where((m)=>m.enabled).toList();
  final steps=<AurenRescueStep>[
   const AurenRescueStep(order:1,title:'ثبّت الوضع',action:'أوقف القرارات الكبيرة مؤقتًا وحدد أهم شيء واحد الآن.',reason:'تقليل التشتيت قبل أي خطوة جديدة.'),
   AurenRescueStep(order:2,title:'اختر الأولوية',action:active.isEmpty?'أنشئ هدفًا واحدًا واضحًا.':'ركّز على: ${active.first.title}',reason:active.isEmpty?'لا يوجد هدف نشط يقود الخطوات.':'استخدام الهدف النشط كنقطة ارتكاز.'),
   AurenRescueStep(order:3,title:'استرجع السياق',action:enabled.isEmpty?'راجع معلوماتك الأساسية وأضف ما تريد أن يتذكره AUREN.':'راجع آخر ${enabled.length>5?5:enabled.length} ذكريات مفعّلة قبل المتابعة.',reason:'استعادة المعلومات المهمة بدون حذف أو تغيير تلقائي.')
  ];
  final plan=AurenRescuePlan(status:'ready',summary:active.isEmpty?'وضع إنقاذ هادئ: ثبّت الأولوية ثم ابدأ بهدف واحد.':'وضع إنقاذ هادئ: هدف واحد، سياق واضح، وخطوة واحدة في كل مرة.',steps:steps,updatedAt:DateTime.now());
  await _db.collection('users').doc(uid).collection('rescue_mode').doc('current').set(plan.toMap()); return plan;
 }
}