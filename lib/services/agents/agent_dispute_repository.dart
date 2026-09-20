import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/models/agent_dispute.dart';
class AurenAgentDisputeRepository {
 final FirebaseFirestore _db; AurenAgentDisputeRepository({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;
 Stream<List<AurenAgentDispute>> watch(String uid)=>_db.collection('users').doc(uid).collection('disputes').orderBy('createdAt',descending:true).limit(30).snapshots().map((s)=>s.docs.map((d)=>AurenAgentDispute.fromMap(d.id,d.data())).toList());
 Future<void> open({required String agentId,required String actionId,required String reason}) async {
  await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('openAurenAgentDispute').call({'agentId':agentId,'actionId':actionId,'reason':reason});
 }
}
