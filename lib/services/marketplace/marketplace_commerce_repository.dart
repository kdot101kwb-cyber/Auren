import 'package:cloud_firestore/cloud_firestore.dart';
class MarketplaceCommerceRepository {
  final FirebaseFirestore db;
  MarketplaceCommerceRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get products=>db.collection('products');
  CollectionReference<Map<String,dynamic>> get orders=>db.collection('marketplace_orders');
  Future<String> createOrder({required String buyerId,required String productId,required String sellerId,required int quantity,required int unitPriceMinor,required String currency,required String paymentMethod}) async {
    final ref=orders.doc();
    await ref.set({'buyerId':buyerId,'sellerId':sellerId,'productId':productId,'quantity':quantity,'unitPriceMinor':unitPriceMinor,'totalMinor':unitPriceMinor*quantity,'currency':currency,'paymentMethod':paymentMethod,'status':'pending','createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }
  Stream<List<Map<String,dynamic>>> watchBuyerOrders(String uid)=>orders.where('buyerId',isEqualTo:uid).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Stream<List<Map<String,dynamic>>> watchSellerOrders(String uid)=>orders.where('sellerId',isEqualTo:uid).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<void> updateOrderStatus(String id,String status)=>orders.doc(id).update({'status':status,'updatedAt':FieldValue.serverTimestamp()});
  Stream<List<Map<String,dynamic>>> watchCart(String uid)=>db.collection('users').doc(uid).collection('cart').orderBy('addedAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<void> addToCart({required String uid,required String productId,required int quantity})=>db.collection('users').doc(uid).collection('cart').doc(productId).set({'productId':productId,'quantity':quantity,'addedAt':FieldValue.serverTimestamp()});
  Future<void> removeFromCart(String uid,String productId)=>db.collection('users').doc(uid).collection('cart').doc(productId).delete();
  Future<void> saveOffer({required String productId,required String ownerId,required String title,required int percent})=>products.doc(productId).collection('offers').doc('active').set({'productId':productId,'ownerId':ownerId,'title':title,'percent':percent,'active':true,'createdAt':FieldValue.serverTimestamp()});
  Stream<Map<String,dynamic>?> watchOffer(String productId)=>products.doc(productId).collection('offers').doc('active').snapshots().map((d)=>d.exists?d.data():null);
  Future<void> review({required String productId,required String userId,required int rating,required String text})=>products.doc(productId).collection('reviews').doc(userId).set({'productId':productId,'userId':userId,'rating':rating,'text':text,'createdAt':FieldValue.serverTimestamp()});
  Stream<List<Map<String,dynamic>>> watchReviews(String productId)=>products.doc(productId).collection('reviews').orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>d.data()).toList());
  Stream<List<Map<String,dynamic>>> watchAnalytics(String productId)=>products.doc(productId).collection('events').orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>d.data()).toList());
}
