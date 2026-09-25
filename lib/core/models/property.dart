class AurenProperty {
  final String id, ownerId, title, description, city, country, type, listingType, currency;
  final int priceMinor, bedrooms, bathrooms, areaSqm;
  final String imageUrl;
  final bool verified;
  const AurenProperty({
    required this.id, required this.ownerId, required this.title, required this.description,
    required this.city, required this.country, required this.type, required this.listingType,
    required this.currency, required this.priceMinor, required this.bedrooms, required this.bathrooms,
    required this.areaSqm, required this.imageUrl, required this.verified,
  });
  factory AurenProperty.fromMap(String id, Map<String,dynamic> m)=>AurenProperty(
    id:id, ownerId:m['ownerId']??'', title:m['title']??'', description:m['description']??'',
    city:m['city']??'', country:m['country']??'', type:m['type']??'Apartment',
    listingType:m['listingType']??'sale', currency:m['currency']??'USD',
    priceMinor:(m['priceMinor'] as num?)?.toInt()??0, bedrooms:(m['bedrooms'] as num?)?.toInt()??0,
    bathrooms:(m['bathrooms'] as num?)?.toInt()??0, areaSqm:(m['areaSqm'] as num?)?.toInt()??0,
    imageUrl:m['imageUrl']??'', verified:m['verified']==true,
  );
}