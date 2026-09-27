import 'package:cloud_firestore/cloud_firestore.dart';

class AurenOrder {
  final String id,buyerId,sellerId,productId,title,currency,status,deliveryStatus;
  final int amountMinor;
  final DateTime? createdAt;
  const AurenOrder({required this.id,required this.buyerId,required this.sellerId,required this.productId,required this.title,required this.currency,required this.amountMinor,required this.status,required this.deliveryStatus,this.createdAt});
  factory AurenOrder.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){final x=d.data()!;return AurenOrder(id:d.id,buyerId:x['buyerId']??'',sellerId:x['sellerId']??'',productId:x['productId']??'',title:x['title']??'',currency:x['currency']??'USD',amountMinor:(x['amountMinor'] as num?)?.toInt()??0,status:x['status']??'pending',deliveryStatus:x['deliveryStatus']??'not_started',createdAt:x['createdAt'] is Timestamp?(x['createdAt'] as Timestamp).toDate():null);}
}
class AurenOrderService{
 final FirebaseFirestore db; AurenOrderService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
 CollectionReference<Map<String,dynamic>> get orders=>db.collection('orders');
 Stream<List<AurenOrder>> watchBuyer(String uid)=>orders.where('buyerId',isEqualTo:uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenOrder.fromDoc).toList());
 Stream<List<AurenOrder>> watchSeller(String uid)=>orders.where('sellerId',isEqualTo:uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map(AurenOrder.fromDoc).toList());
 Future<String> create({required String buyerId,required String sellerId,required String productId,required String title,required String currency,required int amountMinor})async{if(buyerId.isEmpty||sellerId.isEmpty||productId.isEmpty||title.trim().isEmpty)throw ArgumentError('بيانات الطلب ناقصة');if(buyerId==sellerId||amountMinor<=0)throw ArgumentError('بيانات الطلب غير صالحة');final r=orders.doc();await r.set({'buyerId':buyerId,'sellerId':sellerId,'productId':productId,'title':title.trim(),'currency':currency.toUpperCase(),'amountMinor':amountMinor,'status':'pending','deliveryStatus':'not_started','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});return r.id;}
 Future<void> updateDelivery(String sellerId,String orderId,String status)async{if(!['not_started','preparing','shipped','out_for_delivery','delivered','cancelled'].contains(status))throw ArgumentError('حالة التوصيل غير صالحة');await orders.doc(orderId).update({'deliveryStatus':status,'updatedAt':FieldValue.serverTimestamp()});}
}