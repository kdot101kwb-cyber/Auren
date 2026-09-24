import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/models/agent_task.dart';

class AurenAgentCollaborationRepository {
  final FirebaseFirestore db; final FirebaseFunctions functions;
  AurenAgentCollaborationRepository({FirebaseFirestore? firestore,FirebaseFunctions? cloudFunctions}) : db=firestore??FirebaseFirestore.instance, functions=cloudFunctions??FirebaseFunctions.instanceFor(region:'us-central1');
  Stream<List<AurenAgentTask>> watch(String uid) => db.collection('users').doc(uid).collection('agent_collaboration').orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>AurenAgentTask.fromMap(d.id,d.data())).toList());
  Future<String> propose({required String sourceAgent,required String targetAgent,required String title,Map<String,dynamic> input=const {},String taskType='handoff',String? workflowId,int? step}) async {
    final r=await functions.httpsCallable('proposeAurenAgentTask').call({'sourceAgent':sourceAgent,'targetAgent':targetAgent,'taskType':taskType,'title':title,'input':input,'workflowId':workflowId,'step':step});
    return Map<String,dynamic>.from(r.data as Map)['taskId'].toString();
  }
  Future<void> decide(String taskId,String decision) async { await functions.httpsCallable('decideAurenAgentTask').call({'taskId':taskId,'decision':decision}); }
  Future<void> execute(String taskId,{Map<String,dynamic> output=const {}}) async { await functions.httpsCallable('executeAurenAgentTask').call({'taskId':taskId,'output':output}); }
  Future<Map<String,dynamic>> orchestrate(String workflowId,{String command='status'}) async { final r=await functions.httpsCallable('orchestrateAurenTalentWorkflow').call({'workflowId':workflowId,'command':command}); return Map<String,dynamic>.from(r.data as Map); }\n  Future<AurenAgentTask?> get(String uid,String taskId) async { final d=await db.collection('users').doc(uid).collection('agent_collaboration').doc(taskId).get(); return d.exists?AurenAgentTask.fromMap(d.id,d.data()??const {}):null; }
}