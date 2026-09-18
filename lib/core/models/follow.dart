class AurenFollow {
  final String followerId, followingId;
  final DateTime createdAt;
  const AurenFollow({required this.followerId,required this.followingId,required this.createdAt});
  Map<String,dynamic> toMap()=>{'followerId':followerId,'followingId':followingId,'createdAt':createdAt.toUtc().toIso8601String()};
}