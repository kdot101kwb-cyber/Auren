import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/business.dart';

class BusinessRepository {
  final FirebaseFirestore _db;
  BusinessRepository({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get _c=>_db.collection('businesses');

  Stream<List<AurenBusiness>> watchPublic({String query='',String category='All'})=>
    _c.where('visibility',isEqualTo:'public').limit(100).snapshots().map((s){
      final q=query.trim().toLowerCase();
      final items=s.docs.map((d)=>AurenBusiness.fromMap(d.id,d.data()))
        .where((b)=>category=='All'||b.category==category)
        .where((b)=>q.isEmpty||[b.name,b.description,b.category,b.city,b.country,b.businessType].join(' ').toLowerCase().contains(q)).toList();
      items.sort((a,b)=>a.name.toLowerCase().compareTo(b.name.toLowerCase())); return items;
    });

  Future<String> create({required String ownerId,required String name,required String description,required String category,required String city,required String country,required String phone,required String website,required String imageUrl,required String businessType})async{
    final r=_c.doc();
    await r.set({'ownerId':ownerId,'name':name.trim(),'description':description.trim(),'category':category,'city':city.trim(),'country':country.trim(),'phone':phone.trim(),'website':website.trim(),'imageUrl':imageUrl.trim(),'businessType':businessType,'status':'active','visibility':'public','verified':false,'createdAt':FieldValue.serverTimestamp()});
    return r.id;
  }
  Future<void> update({required String id,required String name,required String description,required String category,required String city,required String country,required String phone,required String website,required String imageUrl,required String businessType,required String status})=>
    _c.doc(id).update({'name':name.trim(),'description':description.trim(),'category':category,'city':city.trim(),'country':country.trim(),'phone':phone.trim(),'website':website.trim(),'imageUrl':imageUrl.trim(),'businessType':businessType,'status':status});
  Future<void> delete(String id)=>_c.doc(id).delete();

  DocumentReference<Map<String,dynamic>> _saved(String uid,String id)=>_db.collection('users').doc(uid).collection('savedBusinesses').doc(id);
  Stream<bool> watchSaved(String uid,String id)=>_saved(uid,id).snapshots().map((d)=>d.exists);
  Future<void> toggleSaved(String uid,String id)async{final r=_saved(uid,id);final s=await r.get();if(s.exists){await r.delete();}else{await r.set({'businessId':id,'createdAt':FieldValue.serverTimestamp()});final b=await getById(id);if(b.exists&&b.data()!=null){final business=AurenBusiness.fromMap(id,b.data()!);await recordEvent(business:business,viewerUid:uid,type:'save');}}}
  Stream<List<String>> watchSavedIds(String uid)=>_db.collection('users').doc(uid).collection('savedBusinesses').orderBy('createdAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>d.id).toList());
  Future<DocumentSnapshot<Map<String,dynamic>>> getById(String id)=>_c.doc(id).get();
  Stream<AurenBusiness?> watchById(String id)=>_c.doc(id).snapshots().map((d)=>d.exists&&d.data()!=null?AurenBusiness.fromMap(d.id,d.data()!):null);

  CollectionReference<Map<String,dynamic>> _reviews(String id)=>_c.doc(id).collection('reviews');
  Stream<List<AurenBusinessReview>> watchReviews(String id)=>_reviews(id).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>AurenBusinessReview.fromMap(d.id,d.data())).toList());
  Future<void> upsertReview({required String businessId,required String userId,required int rating,required String text})=>_reviews(businessId).doc(userId).set({'businessId':businessId,'userId':userId,'rating':rating,'text':text.trim(),'createdAt':FieldValue.serverTimestamp()});
  Future<void> report({required String businessId,required String reporterUid,required String reason})=>_db.collection('business_reports').add({'businessId':businessId,'reporterUid':reporterUid,'reason':reason.trim(),'createdAt':FieldValue.serverTimestamp()});

  CollectionReference<Map<String,dynamic>> _events(String id)=>_c.doc(id).collection('events');
  Future<void> recordEvent({required AurenBusiness business,required String viewerUid,required String type})=>_events(business.id).add({'businessId':business.id,'ownerId':business.ownerId,'viewerUid':viewerUid,'type':type,'createdAt':FieldValue.serverTimestamp()});
  Stream<List<AurenBusinessEvent>> watchEvents(String id)=>_events(id).orderBy('createdAt',descending:true).limit(500).snapshots().map((s)=>s.docs.map((d)=>AurenBusinessEvent.fromMap(d.id,d.data())).toList());
  Future<void> requestVerification({required String businessId,required String ownerId,required String note})=>_db.collection('business_verification_requests').doc(businessId).set({'businessId':businessId,'ownerId':ownerId,'note':note.trim(),'status':'pending','createdAt':FieldValue.serverTimestamp()});
}
