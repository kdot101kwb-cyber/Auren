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
    final uid=ownerId.trim(), cleanTitle=title.trim(), cleanDescription=description.trim(), cleanCity=city.trim(), cleanCountry=country.trim(), cleanCurrency=currency.trim().toUpperCase();
    if(uid.isEmpty||uid.length>128) throw ArgumentError('معرّف صاحب العقار غير صالح.');
    if(cleanTitle.isEmpty||cleanTitle.length>160) throw ArgumentError('عنوان العقار مطلوب (حتى 160 حرفاً).');
    if(cleanDescription.length>3000) throw ArgumentError('وصف العقار طويل جداً.');
    if(cleanCity.isEmpty||cleanCity.length>100||cleanCountry.isEmpty||cleanCountry.length>100) throw ArgumentError('المدينة والدولة مطلوبتان.');
    if(!{'Apartment','House','Villa','Office','Shop','Land','Warehouse'}.contains(type)) throw ArgumentError('نوع العقار غير صالح.');
    if(!{'sale','rent'}.contains(listingType)) throw ArgumentError('نوع العرض يجب أن يكون بيعاً أو إيجاراً.');
    if(!RegExp(r'^[A-Z]{3}
  Future<void> update(String id,Map<String,dynamic> data)=>_c.doc(id).update(data);
  Future<void> delete(String id)=>_c.doc(id).delete();
  Future<void> toggleSaved(String uid,String propertyId)async{
    if(uid.trim().isEmpty||uid.length>128) throw ArgumentError('معرّف المستخدم غير صالح.');
    if(propertyId.trim().isEmpty||propertyId.length>128) throw ArgumentError('معرّف العقار غير صالح.');
    final r=_db.collection('users').doc(uid).collection('savedProperties').doc(propertyId);
    final s=await r.get(); if(s.exists){await r.delete();}else{await r.set({'propertyId':propertyId,'createdAt':FieldValue.serverTimestamp()});}
  }
  Stream<Set<String>> watchSavedIds(String uid)=>_db.collection('users').doc(uid).collection('savedProperties').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
}).hasMatch(cleanCurrency)) throw ArgumentError('رمز العملة يجب أن يتكون من 3 أحرف.');
    if(priceMinor<0||bedrooms<0||bathrooms<0||areaSqm<0) throw ArgumentError('السعر والمساحات والغرف لا يمكن أن تكون سالبة.');
    if(bedrooms>100||bathrooms>100||areaSqm>1000000) throw ArgumentError('بيانات العقار خارج النطاق المسموح.');
    final r=_c.doc();
    await r.set({'ownerId':uid,'title':cleanTitle,'description':cleanDescription,'city':cleanCity,'country':cleanCountry,'type':type,'listingType':listingType,'currency':cleanCurrency,'priceMinor':priceMinor,'bedrooms':bedrooms,'bathrooms':bathrooms,'areaSqm':areaSqm,'imageUrl':imageUrl.trim(),'verified':false,'status':'active','visibility':'public','createdAt':FieldValue.serverTimestamp()});
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