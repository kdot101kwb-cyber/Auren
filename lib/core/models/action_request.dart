class AurenActionRequest {
  final String id;
  final String conversationId;
  final String title;
  final String description;
  final bool requiresApproval;
  final String status;
  final DateTime createdAt;
  const AurenActionRequest({required this.id,required this.conversationId,required this.title,required this.description,required this.requiresApproval,required this.status,required this.createdAt});
  Map<String,dynamic> toMap()=>{'conversationId':conversationId,'title':title,'description':description,'requiresApproval':requiresApproval,'status':status,'createdAt':createdAt.toUtc().toIso8601String()};
  factory AurenActionRequest.fromMap(String id,Map<String,dynamic> m)=>AurenActionRequest(id:id,conversationId:m['conversationId']??'',title:m['title']??'',description:m['description']??'',requiresApproval:m['requiresApproval']??true,status:m['status']??'pending',createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now());
}