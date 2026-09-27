import 'package:cloud_firestore/cloud_firestore.dart';

class AurenSupplyRequest {
  final String id, ownerId, title, description, category, city, country, status;
  final List<String> targetCountries, requestedSkills;
  final DateTime? createdAt;
  const AurenSupplyRequest({required this.id,required this.ownerId,required this.title,required this.description,required this.category,required this.city,required this.country,required this.status,required this.targetCountries,required this.requestedSkills,this.createdAt});
  factory AurenSupplyRequest.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){
    final x=d.data()!;
    return AurenSupplyRequest(id:d.id,ownerId:x['ownerId']?.toString()??'',title:x['title']?.toString()??'',description:x['description']?.toString()??'',category:x['category']?.toString()??'',city:x['city']?.toString()??'',country:x['country']?.toString()??'',status:x['status']?.toString()??'open',targetCountries:List<String>.from(x['targetCountries']??const []),requestedSkills:List<String>.from(x['requestedSkills']??const []),createdAt:x['createdAt'] is Timestamp?(x['createdAt'] as Timestamp).toDate():null);
  }
}

class AurenSupplierService {
  final FirebaseFirestore db;
  AurenSupplierService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get requests=>db.collection('supply_requests');
  Stream<List<AurenSupplyRequest>> watchOpen({String? category,String? country}){
    Query<Map<String,dynamic>> q=requests.where('status',isEqualTo:'open').limit(100);
    if(category!=null&&category.trim().isNotEmpty)q=q.where('category',isEqualTo:category.trim());
    if(country!=null&&country.trim().isNotEmpty)q=q.where('targetCountries',arrayContains:country.trim());
    return q.snapshots().map((s)=>s.docs.map(AurenSupplyRequest.fromDoc).toList());
  }
  Future<String> createRequest({required String ownerId,required String title,required String description,required String category,required String city,required String country,List<String> targetCountries=const [],List<String> requestedSkills=const []})async{
    if(ownerId.isEmpty||title.trim().isEmpty||description.trim().isEmpty)throw ArgumentError('بيانات الطلب ناقصة');
    if(title.length>160||description.length>3000)throw ArgumentError('الطلب طويل جداً');
    final ref=requests.doc();
    await ref.set({'ownerId':ownerId,'title':title.trim(),'description':description.trim(),'category':category.trim(),'city':city.trim(),'country':country.trim(),'targetCountries':targetCountries.map((e)=>e.trim()).where((e)=>e.isNotEmpty).take(20).toList(),'requestedSkills':requestedSkills.map((e)=>e.trim()).where((e)=>e.isNotEmpty).take(20).toList(),'status':'open','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
    return ref.id;
  }
  Future<void> close(String ownerId,String id)=>requests.doc(id).update({'status':'closed','updatedAt':FieldValue.serverTimestamp()});
}
