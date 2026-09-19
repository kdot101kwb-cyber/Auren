class AurenComment {
  final String id, postId, authorId, text;
  final DateTime createdAt;
  const AurenComment({required this.id,required this.postId,required this.authorId,required this.text,required this.createdAt});
  Map<String,dynamic> toMap()=>{'postId':postId,'authorId':authorId,'text':text,'createdAt':createdAt.toUtc().toIso8601String()};
  factory AurenComment.fromMap(String id,Map<String,dynamic> m)=>AurenComment(id:id,postId:m['postId']??'',authorId:m['authorId']??'',text:m['text']??'',createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now());
}