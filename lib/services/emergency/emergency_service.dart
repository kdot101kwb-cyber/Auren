import 'package:cloud_firestore/cloud_firestore.dart';

class AurenEmergencyContact {
  final String id,name,type,phone,city,country;
  const AurenEmergencyContact({required this.id,required this.name,required this.type,required this.phone,required this.city,required this.country});
  factory AurenEmergencyContact.fromDoc(DocumentSnapshot<Map<String,dynamic>> d) { final x = d.data() ?? <String, dynamic>{}; return AurenEmergencyContact(id: d.id, name: x['name']?.toString() ?? '', type: x['type']?.toString() ?? 'emergency', phone: x['phone']?.toString() ?? '', city: x['city']?.toString() ?? '', country: x['country']?.toString() ?? ''); }
  bool get isDisplayable => id.trim().isNotEmpty && name.trim().isNotEmpty && phone.trim().isNotEmpty && city.trim().isNotEmpty && country.trim().isNotEmpty;
}
class AurenEmergencyService {
  AurenEmergencyService._(); static final instance=AurenEmergencyService._(); final _db=FirebaseFirestore.instance;
  Stream<List<AurenEmergencyContact>> watch({String city='',String country=''}) => _db.collection('emergency_contacts').where('active',isEqualTo:true).limit(100).snapshots().map((s){ final c=city.trim().toLowerCase(),co=country.trim().toLowerCase(); return s.docs.map(AurenEmergencyContact.fromDoc).where((x)=>x.isDisplayable&&(c.isEmpty||x.city.trim().toLowerCase()==c)&&(co.isEmpty||x.country.trim().toLowerCase()==co)).toList()..sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase())); });
}