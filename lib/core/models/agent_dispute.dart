import 'package:cloud_firestore/cloud_firestore.dart';
class AurenAgentDispute {
 final String id,agentId,actionId,reason,status; final DateTime createdAt;
 const AurenAgentDispute({required this.id,required this.agentId,required this.actionId,required this.reason,required this.status,required this.createdAt});
 factory AurenAgentDispute.fromMap(String id,Map<String,dynamic> m)=>AurenAgentDispute(id:id,agentId:m['agentId'] as String? ?? '',actionId:m['actionId'] as String? ?? '',reason:m['reason'] as String? ?? '',status:m['status'] as String? ?? 'open',createdAt:m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());
}
