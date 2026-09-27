import 'package:cloud_firestore/cloud_firestore.dart';

class AurenEmergencyContact {
  final String id,name,type,phone,city,country;
  const AurenEmergencyContact({required this.id,required this.name,required this.type,required this.phone,required this.city,required this.country});
  factory AurenEmergencyContact.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){ final x=d.data()??{}; return AurenEmergencyContact(id:d.id,name:x['name']??'',type:x['type']??'emergency',phone:x['phone']??'',city:x['city']??'',country:x['country']??''); }
}
class AurenEmergencyService {
  AurenEmergencyService._(); static final instance=AurenEmergencyService._(); final _db=FirebaseFirestore.instance;
  Stream<List<AurenEmergencyContact>> watch({String city='',String country=''}) => _db.collection('emergency_contacts').where('active',isEqualTo:true).limit(100).snapshots().map((s){ final c=city.trim().toLowerCase(),co=country.trim().toLowerCase(); return s.docs.map(AurenEmergencyContact.fromDoc).where((x)=>(c.isEmpty||x.city.toLowerCase()==c)&&(co.isEmpty||x.country.toLowerCase()==co)).toList(); });
}