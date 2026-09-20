class AurenBusiness {
  final String id, ownerId, name, description, category, city, country, phone, website, imageUrl, visibility, businessType, status;
  final bool verified;
  final DateTime? createdAt;
  const AurenBusiness({required this.id,required this.ownerId,required this.name,required this.description,required this.category,required this.city,required this.country,required this.phone,required this.website,required this.imageUrl,required this.visibility,required this.businessType,required this.status,required this.verified,this.createdAt});
  factory AurenBusiness.fromMap(String id, Map<String,dynamic> d)=>AurenBusiness(id:id,ownerId:d['ownerId'] as String? ?? '',name:d['name'] as String? ?? '',description:d['description'] as String? ?? '',category:d['category'] as String? ?? 'Other',city:d['city'] as String? ?? '',country:d['country'] as String? ?? '',phone:d['phone'] as String? ?? '',website:d['website'] as String? ?? '',imageUrl:d['imageUrl'] as String? ?? '',visibility:d['visibility'] as String? ?? 'public',businessType:d['businessType'] as String? ?? 'Business',status:d['status'] as String? ?? 'active',verified:d['verified'] as bool? ?? false,createdAt:(d['createdAt'] as dynamic)?.toDate());
}
class AurenBusinessReview {
  final String id,businessId,userId,text; final int rating; final DateTime? createdAt;
  const AurenBusinessReview({required this.id,required this.businessId,required this.userId,required this.rating,required this.text,this.createdAt});
  factory AurenBusinessReview.fromMap(String id,Map<String,dynamic> d)=>AurenBusinessReview(id:id,businessId:d['businessId'] as String? ?? '',userId:d['userId'] as String? ?? '',rating:(d['rating'] as num?)?.toInt() ?? 0,text:d['text'] as String? ?? '',createdAt:(d['createdAt'] as dynamic)?.toDate());
}