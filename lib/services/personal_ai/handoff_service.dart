import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
class AurenHandoff { final String title,summary,destination; final List<String> context; final DateTime createdAt; const AurenHandoff({required this.title,required this.summary,required this.destination,required this.context,required this.createdAt}); Map<String,dynamic> toMap()=>{'title':title,'summary':summary,'destination':destination,'context':context,'createdAt':Timestamp.fromDate(createdAt.toUtc())}; }
class HandoffService {
 final FirebaseFirestore _db; final GoalRepository _goals; final MemoryRepository _memory;
 HandoffService({FirebaseFirestore? firestore,GoalRepository? goals,MemoryRepository? memory}):_db=firestore??FirebaseFirestore.instance,_goals=goals??GoalRepository(),_memory=memory??MemoryRepository();
 Future<AurenHandoff> build(String uid,{required String destination}) async {
  if(uid.trim().isEmpty) throw ArgumentError('uid is required');
  final goals=await _goals.watch(uid).first; final memories=await _memory.watch(uid).first;
  final active=goals.where((g)=>g.status=='active').toList(); final enabled=memories.where((m)=>m.enabled).toList();
  final context=<String>[if(active.isNotEmpty)'الهدف النشط: ${active.first.title} (${active.first.progress}%)',if(active.length>1)'أهداف نشطة إضافية: ${active.length-1}',if(enabled.isNotEmpty)'الذاكرة المفعّلة: ${enabled.length}',if(enabled.isNotEmpty)'آخر ذاكرة: ${enabled.first.key}'];
  final h=AurenHandoff(title:'AUREN Handoff',summary:active.isEmpty?'لا يوجد هدف نشط؛ ابدأ من السياق الحالي.':'استلم المهمة من النقطة الحالية بدون إعادة بناء السياق.',destination:destination.trim().isEmpty?'AUREN':destination.trim(),context:context,createdAt:DateTime.now());
  await _db.collection('users').doc(uid).collection('handoffs').add(h.toMap()); return h;
 }
}