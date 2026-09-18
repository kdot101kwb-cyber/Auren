class AurenPost {
  final String id, authorId, text;
  final DateTime createdAt;
  final int likes, comments;
  const AurenPost({required this.id,required this.authorId,required this.text,required this.createdAt,this.likes=0,this.comments=0});
  Map<String,dynamic> toMap()=>{'authorId':authorId,'text':text,'createdAt':createdAt.toUtc().toIso8601String(),'likes':likes,'comments':comments};
  factory AurenPost.fromMap(String id,Map<String,dynamic> m)=>AurenPost(id:id,authorId:m['authorId']??'',text:m['text']??'',createdAt:DateTime.tryParse(m['createdAt']??'')??DateTime.now(),likes:m['likes']??0,comments:m['comments']??0);
}