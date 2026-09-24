import 'package:cloud_firestore/cloud_firestore.dart';
class ReverseMarketplaceRequest {
 final String id,ownerId,title,description,category,currency,status; final int? maxPriceMinor; final DateTime? createdAt;
 const ReverseMarketplaceRequest({required this.id,required this.ownerId,required this.title,required this.description,required this.category,required this.currency,required this.status,this.maxPriceMinor,this.createdAt});
 factory ReverseMarketplaceRequest.fromMap(String id,Map<String,dynamic> d)=>ReverseMarketplaceRequest(id:id,ownerId:d['ownerId'] as String? ?? '',title:d['title'] as String? ?? '',description:d['description'] as String? ?? '',category:d['category'] as String? ?? 'General',currency:d['currency'] as String? ?? 'USD',status:d['status'] as String? ?? 'open',maxPriceMinor:(d['maxPriceMinor'] as num?)?.toInt(),createdAt:(d['createdAt'] as dynamic)?.toDate());
}
class ReverseMarketplaceService {
 final FirebaseFirestore _db; ReverseMarketplaceService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get _c=>_db.collection('reverse_marketplace_requests');
 Future<String> create({required String ownerId,required String title,required String description,required String category,required String currency,int? maxPriceMinor})async{final r=_c.doc();await r.set({'ownerId':ownerId,'title':title.trim(),'description':description.trim(),'category':category,'currency':currency,'maxPriceMinor':maxPriceMinor,'status':'open','createdAt':FieldValue.serverTimestamp()});return r.id;}
 Stream<List<ReverseMarketplaceRequest>> watchOpen({String query='',String category='All',String currency=''})=>_c.where('status',isEqualTo:'open').limit(100).snapshots().map((s){final q=query.trim().toLowerCase();final cur=currency.trim().toUpperCase();return s.docs.map((d)=>ReverseMarketplaceRequest.fromMap(d.id,d.data())).where((r)=>category=='All'||r.category==category).where((r)=>cur.isEmpty||r.currency==cur).where((r)=>q.isEmpty||('${r.title} ${r.description} ${r.category}').toLowerCase().contains(q)).toList();});
 Future<void> close(String uid,String id)=>_c.doc(id).update({'status':'closed'});
 Future<String> offer({required String supplierUid,required String requestId,required int priceMinor,required String message})async{final r=_c.doc(requestId).collection('offers').doc();await r.set({'supplierUid':supplierUid,'requestId':requestId,'priceMinor':priceMinor,'message':message.trim(),'status':'pending','createdAt':FieldValue.serverTimestamp()});return r.id;}
 Stream<QuerySnapshot<Map<String,dynamic>>> watchOffers(String requestId)=>_c.doc(requestId).collection('offers').orderBy('createdAt',descending:true).snapshots();
}