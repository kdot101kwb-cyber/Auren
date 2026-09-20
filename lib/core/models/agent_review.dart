class AurenAgentReview {
  final String reviewId, agentId, reviewerUid, text; final int rating; final DateTime createdAt;
  const AurenAgentReview({required this.reviewId,required this.agentId,required this.reviewerUid,required this.rating,required this.text,required this.createdAt});
  factory AurenAgentReview.fromMap(String id, Map<String,dynamic> m)=>AurenAgentReview(
    reviewId:id,agentId:m['agentId'] as String? ?? '',reviewerUid:m['reviewerUid'] as String? ?? '',
    rating:(m['rating'] as num?)?.toInt() ?? 0,text:m['text'] as String? ?? '',
    createdAt:(m['createdAt'] is String ? DateTime.tryParse(m['createdAt']) : null) ?? DateTime.fromMillisecondsSinceEpoch(0));
}
