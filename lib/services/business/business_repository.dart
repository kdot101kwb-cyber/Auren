import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/business.dart';
class BusinessRepository {
 final FirebaseFirestore _db;
 BusinessRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _c=>_db.collection('businesses');
 Stream<List<AurenBusiness>> watchPublic({String query='',String category='All'})=>_c.where('visibility',isEqualTo:'public').limit(100).snapshots().map((s){
   final q=query.trim().toLowerCase();
   final x=s.docs.map((d)=>AurenBusiness.fromMap(d.id,d.data())).where((b)=>category=='All'||b.category==category).where((b)=>q.isEmpty||[b.name,b.description,b.category,b.city,b.country].join(' ').toLowerCase().contains(q)).toList();
   x.sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase())); return x;
 });
 Future<String> create({required String ownerId,required String name,required String description,required String category,required String city,required String country,required String phone,required String website,required String imageUrl}) async {
   final r=_c.doc(); await r.set({'ownerId':ownerId,'name':name.trim(),'description':description.trim(),'category':category,'city':city.trim(),'country':country.trim(),'phone':phone.trim(),'website':website.trim(),'imageUrl':imageUrl.trim(),'visibility':'public','verified':false,'createdAt':FieldValue.serverTimestamp()}); return r.id;
 }
 Future<void> delete(String id)=>_c.doc(id).delete();
}
