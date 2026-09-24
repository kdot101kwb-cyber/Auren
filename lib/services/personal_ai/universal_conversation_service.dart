import 'package:cloud_firestore/cloud_firestore.dart';
import '../goals/goal_repository.dart';
import '../memory/memory_repository.dart';
import '../business/business_repository.dart';

class AurenConversationContext {
  final String summary; final List<String> goals, memories, businesses;
  const AurenConversationContext({required this.summary,required this.goals,required this.memories,required this.businesses});
  String toPrompt()=> 'Universal AUREN context:\n'+summary+'\nGoals: '+goals.join(', ')+'\nMemory: '+memories.join(', ')+'\nBusiness: '+businesses.join(', ');
}
class AurenUniversalConversationService {
  final FirebaseFirestore _db; final GoalRepository _goals; final MemoryRepository _memory; final BusinessRepository _business;
  AurenUniversalConversationService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance,_goals=GoalRepository(firestore:firestore),_memory=MemoryRepository(firestore:firestore),_business=BusinessRepository(firestore:firestore);
  Future<AurenConversationContext> build(String uid) async {
    final goals=await _goals.watch(uid).first; final memories=await _memory.watch(uid).first; final businesses=(await _business.watchPublic().first).where((b)=>b.ownerId==uid).toList();
    final active=goals.where((g)=>g.status=='active').toList(); final enabled=memories.where((m)=>m.enabled).toList();
    final avg=active.isEmpty?0:active.fold<int>(0,(s,g)=>s+g.progress)~/active.length;
    final c=AurenConversationContext(summary:active.isEmpty?'لا يوجد هدف نشط حالياً.':'لديك '+active.length.toString()+' أهداف نشطة • متوسط التقدم '+avg.toString()+'%',goals:active.take(10).map((g)=>g.title+' ('+g.progress.toString()+'%)').toList(),memories:enabled.take(20).map((m)=>m.key+': '+m.value).toList(),businesses:businesses.take(10).map((b)=>b.name+' ('+b.category+')').toList());
    await _db.collection('users').doc(uid).collection('universal_conversation').doc('current').set({'summary':c.summary,'goals':c.goals,'memories':c.memories,'businesses':c.businesses,'updatedAt':FieldValue.serverTimestamp()}); return c;
  }
}
