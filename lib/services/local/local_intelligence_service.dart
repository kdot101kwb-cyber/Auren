import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/business.dart';
import '../../../core/models/opportunity.dart';

class AurenLocalSnapshot {
  final String city,country;
  final List<AurenBusiness> businesses;
  final List<AurenOpportunity> opportunities;
  const AurenLocalSnapshot({required this.city,required this.country,required this.businesses,required this.opportunities});
}

class AurenLocalIntelligenceService {
  final FirebaseFirestore db;
  AurenLocalIntelligenceService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  Stream<AurenLocalSnapshot> watch({required String city,required String country}) {
    final c=city.trim(), co=country.trim();
    if(c.isEmpty&&co.isEmpty) return Stream.value(AurenLocalSnapshot(city:c,country:co,businesses:const [],opportunities:const []));
    final bq=db.collection('businesses').where('visibility',isEqualTo:'public').limit(100).snapshots();
    final oq=db.collection('opportunities').where('status',isEqualTo:'open').limit(100).snapshots();
    return bq.asyncMap((bs) async {
      final os=await oq.first;
      bool match(String a,String b)=>a.trim().toLowerCase()==b.trim().toLowerCase();
      final businesses=bs.docs.map((d)=>AurenBusiness.fromMap(d.id,d.data())).where((b)=>match(b.city,c)||match(b.country,co)).take(30).toList();
      final opportunities=os.docs.map((d)=>AurenOpportunity.fromMap(d.id,d.data())).where((o)=>match(o.city,c)||match(o.country,co)).take(30).toList();
      return AurenLocalSnapshot(city:c,country:co,businesses:businesses,opportunities:opportunities);
    });
  }
}
