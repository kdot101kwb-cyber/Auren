class AurenBusiness {
  final String id, ownerId, name, description, category, city, country, phone, website, imageUrl, visibility;
  final bool verified;
  final DateTime? createdAt;
  const AurenBusiness({required this.id,required this.ownerId,required this.name,required this.description,required this.category,required this.city,required this.country,required this.phone,required this.website,required this.imageUrl,required this.visibility,required this.verified,this.createdAt});
  factory AurenBusiness.fromMap(String id, Map<String,dynamic> d)=>AurenBusiness(id:id,ownerId:d['ownerId'] as String? ?? '',name:d['name'] as String? ?? '',description:d['description'] as String? ?? '',category:d['category'] as String? ?? 'Other',city:d['city'] as String? ?? '',country:d['country'] as String? ?? '',phone:d['phone'] as String? ?? '',website:d['website'] as String? ?? '',imageUrl:d['imageUrl'] as String? ?? '',visibility:d['visibility'] as String? ?? 'public',verified:d['verified'] as bool? ?? false,createdAt:(d['createdAt'] as dynamic)?.toDate());
}
