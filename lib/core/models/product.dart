class AurenProduct {
  final String id,businessId,ownerId,name,description,category,currency,imageUrl,status;
  final int priceMinor;
  final bool service;
  final DateTime? createdAt;
  const AurenProduct({required this.id,required this.businessId,required this.ownerId,required this.name,required this.description,required this.category,required this.currency,required this.priceMinor,required this.imageUrl,required this.status,required this.service,this.createdAt});
  factory AurenProduct.fromMap(String id,Map<String,dynamic> d)=>AurenProduct(id:id,businessId:d['businessId'] as String? ?? '',ownerId:d['ownerId'] as String? ?? '',name:d['name'] as String? ?? '',description:d['description'] as String? ?? '',category:d['category'] as String? ?? 'Other',currency:d['currency'] as String? ?? 'USD',priceMinor:(d['priceMinor'] as num?)?.toInt() ?? 0,imageUrl:d['imageUrl'] as String? ?? '',status:d['status'] as String? ?? 'active',service:d['service'] as bool? ?? false,createdAt:(d['createdAt'] as dynamic)?.toDate());
}
