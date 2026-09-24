import 'package:cloud_firestore/cloud_firestore.dart';

class AurenAgentTask {
  final String id, ownerId, sourceAgent, targetAgent, taskType, title, status;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final bool requiresApproval;
  final DateTime? createdAt;
  const AurenAgentTask({required this.id,required this.ownerId,required this.sourceAgent,required this.targetAgent,required this.taskType,required this.title,required this.status,required this.input,required this.output,required this.requiresApproval,this.createdAt});
  factory AurenAgentTask.fromMap(String id, Map<String,dynamic> d) => AurenAgentTask(id:id,ownerId:d['ownerId']?.toString()??'',sourceAgent:d['sourceAgent']?.toString()??'',targetAgent:d['targetAgent']?.toString()??'',taskType:d['taskType']?.toString()??'handoff',title:d['title']?.toString()??'',status:d['status']?.toString()??'proposed',input:d['input'] is Map?Map<String,dynamic>.from(d['input'] as Map):const {},output:d['output'] is Map?Map<String,dynamic>.from(d['output'] as Map):const {},requiresApproval:d['requiresApproval']==true,createdAt:d['createdAt'] is Timestamp?(d['createdAt'] as Timestamp).toDate():null);
}