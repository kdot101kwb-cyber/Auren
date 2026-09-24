import '../../../core/models/business.dart';
import '../business/business_repository.dart';

class AurenLocalSnapshot {
  final String city;
  final String country;
  final String category;
  final List<AurenBusiness> businesses;
  const AurenLocalSnapshot({required this.city,required this.country,required this.category,required this.businesses});
  String get summary {
    if (businesses.isEmpty) return 'لا توجد نتائج محلية كافية بعد.';
    final verified=businesses.where((b)=>b.verified).length;
    return '${businesses.length} نشاط محلي • $verified موثّق';
  }
}

class LocalIntelligenceService {
  final BusinessRepository _businesses;
  LocalIntelligenceService({BusinessRepository? businesses}):_businesses=businesses??BusinessRepository();

  Stream<AurenLocalSnapshot> watch({required String city,required String country,String category='All'}) =>
    _businesses.watchPublic(category: category).map((items){
      final c=city.trim().toLowerCase(), co=country.trim().toLowerCase();
      final filtered=items.where((b){
        final cityOk=c.isEmpty || b.city.toLowerCase().contains(c);
        final countryOk=co.isEmpty || b.country.toLowerCase().contains(co);
        return cityOk && countryOk;
      }).toList()
        ..sort((a,b){
          final av=a.verified?1:0, bv=b.verified?1:0;
          final byVerified=bv.compareTo(av);
          return byVerified!=0?byVerified:a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return AurenLocalSnapshot(city:city,country:country,category:category,businesses:filtered.take(50).toList());
    });
}
