import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/models/auren_work_execution.dart';

class AurenWorkAgentRepository {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  AurenWorkAgentRepository({FirebaseFirestore? firestore,FirebaseFunctions? functions})
    : firestore=firestore??FirebaseFirestore.instance, functions=functions??FirebaseFunctions.instance;

  Stream<List<AurenWorkExecution>> watch(String uid) => firestore.collection('users').doc(uid)
    .collection('agent_work_executions').orderBy('createdAt',descending:true).limit(50).snapshots()
    .map((s)=>s.docs.map((d)=>AurenWorkExecution.fromDoc(d.id,d.data())).toList());

  Future<String> request(String agentId,String prompt) async {
    final r=await functions.httpsCallable('requestAurenWorkAgent').call({'agentId':agentId,'prompt':prompt});
    return (r.data['executionId']??'').toString();
  }
  Future<void> decide(String id,String decision) => functions.httpsCallable('decideAurenWorkAgent').call({'executionId':id,'decision':decision});
  Future<void> execute(String id) => functions.httpsCallable('executeAurenWorkAgent').call({'executionId':id});
}