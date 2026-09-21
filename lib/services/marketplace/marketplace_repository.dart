import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/product.dart';
class MarketplaceRepository{
 final FirebaseFirestore _db; MarketplaceRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _c=>_db.collection('products');
 Stream<List<AurenProduct>> watchPublic({String query='',String category='All'})=>_c.where('status',isEqualTo:'active').limit(100).snapshots().map((s){
  final q=query.trim().toLowerCase(); final items=s.docs.map((d)=>AurenProduct.fromMap(d.id,d.data())).where((p)=>category=='All'||p.category==category).where((p)=>q.isEmpty||[p.name,p.description,p.category].join(' ').toLowerCase().contains(q)).toList();
  items.sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase())); return items;
 });
 Future<String> create({required String ownerId,required String businessId,required String name,required String description,required String category,required String currency,required int priceMinor,required String imageUrl,required bool service})async{
  final r=_c.doc(); await r.set({'ownerId':ownerId,'businessId':businessId,'name':name.trim(),'description':description.trim(),'category':category,'currency':currency,'priceMinor':priceMinor,'imageUrl':imageUrl.trim(),'service':service,'status':'active','createdAt':FieldValue.serverTimestamp()}); return r.id;
 }
 Future<void> update(String id,Map<String,dynamic> data)=>_c.doc(id).update(data);
 Future<void> delete(String id)=>_c.doc(id).delete();
 Future<void> toggleSaved(String uid,String productId,bool saved)async{final ref=_db.collection('users').doc(uid).collection('savedProducts').doc(productId);if(saved){await ref.set({'productId':productId,'savedAt':FieldValue.serverTimestamp()});}else{await ref.delete();}}
 Stream<Set<String>> watchSavedIds(String uid)=>_db.collection('users').doc(uid).collection('savedProducts').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
  Stream<List<AurenProduct>> watchBusiness(String businessId)=>_c.where('businessId',isEqualTo:businessId).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenProduct.fromMap(d.id,d.data())).toList());
  Stream<List<AurenProduct>> watchOwner(String ownerId)=>_c.where('ownerId',isEqualTo:ownerId).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenProduct.fromMap(d.id,d.data())).toList());
}
