class AurenSocialPost {
  final String id, authorId, text;
  final DateTime createdAt;
  final int likes, comments;
  const AurenSocialPost({required this.id,required this.authorId,required this.text,required this.createdAt,this.likes=0,this.comments=0});
}