import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/goals/goal_repository.dart';
import '../../../services/memory/memory_repository.dart';
class AurenContinuitySnapshot { final String status,summary; final int activeGoals,enabledMemories; final String? focus; final DateTime updatedAt; const AurenContinuitySnapshot({required this.status,required this.summary,required this.activeGoals,required this.enabledMemories,required this.focus,required this.updatedAt}); Map<String,dynamic> toMap()=>{'status':status,'summary':summary,'activeGoals':activeGoals,'enabledMemories':enabledMemories,'focus':focus,'updatedAt':Timestamp.fromDate(updatedAt.toUtc())}; }
class ContinuityService {
 final FirebaseFirestore _db; final GoalRepository _goals; final MemoryRepository _memory;
 ContinuityService({FirebaseFirestore? firestore,GoalRepository? goals,MemoryRepository? memory}):_db=firestore??FirebaseFirestore.instance,_goals=goals??GoalRepository(),_memory=memory??MemoryRepository();
 Future<AurenContinuitySnapshot> resume(String uid) async {
  if(uid.trim().isEmpty) throw ArgumentError('uid is required');
  final goals=await _goals.watch(uid).first; final memories=await _memory.watch(uid).first;
  final active=goals.where((g)=>g.status=='active').toList(); final enabled=memories.where((m)=>m.enabled).toList();
  final focus=active.isEmpty?null:'${active.first.title}';
  final summary=active.isEmpty?'لا يوجد هدف نشط. يمكنك استئناف العمل من خلال إنشاء هدف واضح.':'استئناف من الهدف: ${active.first.title} (${active.first.progress}%). السياق الشخصي متاح.';
  final snapshot=AurenContinuitySnapshot(status:'resumed',summary:summary,activeGoals:active.length,enabledMemories:enabled.length,focus:focus,updatedAt:DateTime.now());
  await _db.collection('users').doc(uid).collection('continuity').doc('current').set(snapshot.toMap()); return snapshot;
 }
}