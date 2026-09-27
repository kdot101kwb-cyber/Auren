import 'package:cloud_firestore/cloud_firestore.dart';

class AurenCommerceIntent {
  final String id, uid, action, status, currency;
  final int amountMinor;
  final String? merchantId, itemId;
  final DateTime? createdAt;
  const AurenCommerceIntent({required this.id,required this.uid,required this.action,required this.status,required this.currency,required this.amountMinor,this.merchantId,this.itemId,this.createdAt});
  factory AurenCommerceIntent.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){
    final x=d.data()!;
    return AurenCommerceIntent(id:d.id,uid:x['uid']?.toString()??'',action:x['action']?.toString()??'purchase',status:x['status']?.toString()??'draft',currency:x['currency']?.toString()??'USD',amountMinor:x['amountMinor'] is int?x['amountMinor'] as int:0,merchantId:x['merchantId']?.toString(),itemId:x['itemId']?.toString(),createdAt:x['createdAt'] is Timestamp?(x['createdAt'] as Timestamp).toDate():null);
  }
}

class AurenCommerceService {
  final FirebaseFirestore db;
  AurenCommerceService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> _c(String uid)=>db.collection('users').doc(uid).collection('commerce_intents');

  Stream<List<AurenCommerceIntent>> watch(String uid)=>_c(uid).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map(AurenCommerceIntent.fromDoc).toList());

  Future<String> createPurchaseIntent({required String uid,required String title,required String currency,required int amountMinor,String? merchantId,String? itemId})async{
    if(uid.trim().isEmpty||title.trim().isEmpty)throw ArgumentError('بيانات الشراء ناقصة');
    if(amountMinor<=0)throw ArgumentError('المبلغ يجب أن يكون أكبر من صفر');
    if(!RegExp(r'^[A-Z]{3}$').hasMatch(currency.toUpperCase()))throw ArgumentError('العملة غير صالحة');
    final ref=_c(uid).doc();
    await ref.set({'uid':uid,'action':'purchase','title':title.trim(),'currency':currency.toUpperCase(),'amountMinor':amountMinor,'merchantId':merchantId,'itemId':itemId,'status':'awaiting_approval','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> approve(String uid,String intentId)async{
    await _c(uid).doc(intentId).update({'status':'approved','approvedAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
  }

  Future<void> cancel(String uid,String intentId)async{
    await _c(uid).doc(intentId).update({'status':'cancelled','updatedAt':FieldValue.serverTimestamp()});
  }
}
