import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/property.dart';

class AurenRealEstateService {
  final FirebaseFirestore _db;
  AurenRealEstateService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get _c=>_db.collection('properties');
  Stream<List<AurenProperty>> watchPublic({String query='',String city='',String listingType='All',String type='All'})=>
    _c.where('visibility',isEqualTo:'public').where('status',isEqualTo:'active').limit(100).snapshots().map((s){
      final q=query.trim().toLowerCase(), c=city.trim().toLowerCase();
      final list=s.docs.map((d)=>AurenProperty.fromMap(d.id,d.data()))
        .where((p)=>listingType=='All'||p.listingType==listingType)
        .where((p)=>type=='All'||p.type==type)
        .where((p)=>c.isEmpty||p.city.toLowerCase().contains(c)||p.country.toLowerCase().contains(c))
        .where((p)=>q.isEmpty||[p.title,p.description,p.city,p.country,p.type].join(' ').toLowerCase().contains(q)).toList();
      list.sort((a,b)=>b.verified.toString().compareTo(a.verified.toString()));
      return list;
    });
  Future<String> publish({required String ownerId,required String title,required String description,required String city,required String country,required String type,required String listingType,required String currency,required int priceMinor,required int bedrooms,required int bathrooms,required int areaSqm,required String imageUrl})async{
    final r=_c.doc();
    await r.set({'ownerId':ownerId,'title':title.trim(),'description':description.trim(),'city':city.trim(),'country':country.trim(),'type':type,'listingType':listingType,'currency':currency,'priceMinor':priceMinor,'bedrooms':bedrooms,'bathrooms':bathrooms,'areaSqm':areaSqm,'imageUrl':imageUrl.trim(),'verified':false,'status':'active','visibility':'public','createdAt':FieldValue.serverTimestamp()});
    return r.id;
  }
  Future<void> update(String id,Map<String,dynamic> data)=>_c.doc(id).update(data);
  Future<void> delete(String id)=>_c.doc(id).delete();
  Future<void> toggleSaved(String uid,String propertyId)async{
    final r=_db.collection('users').doc(uid).collection('savedProperties').doc(propertyId);
    final s=await r.get(); if(s.exists){await r.delete();}else{await r.set({'propertyId':propertyId,'createdAt':FieldValue.serverTimestamp()});}
  }
  Stream<Set<String>> watchSavedIds(String uid)=>_db.collection('users').doc(uid).collection('savedProperties').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
}