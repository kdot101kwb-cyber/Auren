class AurenWorkExecution {
  final String id;
  final String agentId;
  final String prompt;
  final String status;
  final bool requiresApproval;
  final Map<String, dynamic> result;
  final String? error;
  const AurenWorkExecution({required this.id,required this.agentId,required this.prompt,required this.status,required this.requiresApproval,this.result=const {},this.error});
  factory AurenWorkExecution.fromDoc(String id, Map<String,dynamic> data) => AurenWorkExecution(
    id:id, agentId:(data['agentId']??'').toString(), prompt:(data['prompt']??'').toString(),
    status:(data['status']??'proposed').toString(), requiresApproval:data['requiresApproval']==true,
    result:data['result'] is Map ? Map<String,dynamic>.from(data['result'] as Map) : const {}, error:data['error']?.toString());
}