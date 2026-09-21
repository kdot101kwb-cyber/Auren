import 'package:cloud_firestore/cloud_firestore.dart';
class MarketplaceCommerceRepository {
  final FirebaseFirestore db;
  MarketplaceCommerceRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get products=>db.collection('products');
  CollectionReference<Map<String,dynamic>> get orders=>db.collection('marketplace_orders');
  Future<String> createOrder({required String buyerId,required String productId,required String sellerId,required int quantity,required int unitPriceMinor,required String currency,required String paymentMethod,required String deliveryAddress,required String deliveryPhone,String? productName,String? productImageUrl}) async {
    if(!{'cash_on_delivery','pending_gateway'}.contains(paymentMethod)) throw ArgumentError('طريقة دفع غير صالحة');
    if(quantity<1||quantity>1000) throw ArgumentError('كمية غير صالحة');
    if(deliveryAddress.trim().isEmpty||deliveryAddress.trim().length>500) throw ArgumentError('عنوان توصيل غير صالح');
    if(deliveryPhone.trim().isEmpty||deliveryPhone.trim().length>40) throw ArgumentError('رقم هاتف غير صالح');
    final ref=orders.doc();
    await ref.set({'buyerId':buyerId,'sellerId':sellerId,'productId':productId,'quantity':quantity,'unitPriceMinor':unitPriceMinor,'totalMinor':unitPriceMinor*quantity,'currency':currency,'paymentMethod':paymentMethod,'productName':productName ?? '','productImageUrl':productImageUrl ?? '','deliveryAddress':deliveryAddress.trim(),'deliveryPhone':deliveryPhone.trim(),'status':'pending','estimatedDeliveryAt':Timestamp.fromDate(DateTime.now().add(const Duration(days:3))),'createdAt':FieldValue.serverTimestamp()});
    return ref.id;
  }
  Stream<List<Map<String,dynamic>>> watchBuyerOrders(String uid)=>orders.where('buyerId',isEqualTo:uid).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Stream<List<Map<String,dynamic>>> watchSellerOrders(String uid)=>orders.where('sellerId',isEqualTo:uid).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<Map<String,int>> sellerFinancialSummary(String uid) async {
    final snap=await orders.where('sellerId',isEqualTo:uid).limit(500).get();
    var gross=0; var commission=0; var count=0;
    for(final d in snap.docs){final x=d.data();if(x['status']=='cancelled') continue; final total=(x['totalMinor'] as num?)?.toInt()??0; gross+=total; commission+=(total*5/100).round(); count++;}
    return {'orders':count,'grossMinor':gross,'commissionMinor':commission,'netMinor':gross-commission};
  }
  Future<void> updateOrderStatus(String id,String status) async {
    const allowed={'pending','confirmed','processing','shipped','delivered','cancelled'};
    if(!allowed.contains(status)) throw ArgumentError('حالة طلب غير صالحة');
    await orders.doc(id).update({'status':status,'updatedAt':FieldValue.serverTimestamp(),'statusUpdatedAt':FieldValue.serverTimestamp()});
  }
  Future<void> updateCartQuantity({required String uid,required String productId,required int quantity}) async {
    if(quantity<1){await removeFromCart(uid,productId);return;}
    if(quantity>100) throw ArgumentError('الكمية القصوى 100');
    await db.collection('users').doc(uid).collection('cart').doc(productId).update({'quantity':quantity});
  }
  Future<void> addToCartWithSnapshot({required String uid,required String productId,required int quantity}) async { final p=await products.doc(productId).get(); if(!p.exists||p.data()==null) throw StateError('المنتج غير موجود'); final d=p.data()!; await db.collection('users').doc(uid).collection('cart').doc(productId).set({'productId':productId,'name':d['name'],'sellerId':d['ownerId'],'unitPriceMinor':d['priceMinor'],'currency':d['currency'],'quantity':quantity.clamp(1,100),'addedAt':FieldValue.serverTimestamp()}); }
  Future<String> checkoutCart({required String uid,required String paymentMethod,required String deliveryAddress,required String deliveryPhone}) async {
    final snap=await db.collection('users').doc(uid).collection('cart').get();
    if(snap.docs.isEmpty) throw StateError('السلة فارغة');
    String firstOrder='';
    final validated=<Map<String,dynamic>>[];
    for(final cart in snap.docs){
        final x=cart.data();
        final productId=x['productId']?.toString() ?? cart.id;
        final quantity=(x['quantity'] as num?)?.toInt() ?? 1;
        final product=await products.doc(productId).get();
        if(!product.exists||product.data()==null) throw StateError('المنتج لم يعد متاحاً: $productId');
        final d=product.data()!;
        if((d['status']?.toString() ?? 'active')!='active') throw StateError('المنتج غير متاح حالياً: ${d['name'] ?? productId}');
        final sellerId=d['ownerId']?.toString() ?? '';
        final price=(d['priceMinor'] as num?)?.toInt() ?? 0;
        final currency=d['currency']?.toString() ?? 'USD';
        if(sellerId.isEmpty) throw StateError('المنتج لا يملك بائعاً صالحاً: $productId');
        if(quantity<1||quantity>1000) throw StateError('كمية غير صالحة: $productId');
        validated.add({'cart':cart,'productId':productId,'sellerId':sellerId,'quantity':quantity,'price':price,'currency':currency,'name':d['name']?.toString() ?? '','imageUrl':d['imageUrl']?.toString() ?? ''});
    }
    for(final v in validated){
      final id=await createOrder(buyerId:uid,productId:v['productId'],sellerId:v['sellerId'],quantity:v['quantity'],unitPriceMinor:v['price'],currency:v['currency'],paymentMethod:paymentMethod,deliveryAddress:deliveryAddress,deliveryPhone:deliveryPhone,productName:v['name'],productImageUrl:v['imageUrl']);
      firstOrder=firstOrder.isEmpty?id:firstOrder;
    }
    for(final cart in snap.docs) await cart.reference.delete();
    return firstOrder;
  }
  Stream<List<Map<String,dynamic>>> watchCart(String uid)=>db.collection('users').doc(uid).collection('cart').orderBy('addedAt',descending:true).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<void> addToCart({required String uid,required String productId,required int quantity})=>addToCartWithSnapshot(uid:uid,productId:productId,quantity:quantity);
  Future<void> removeFromCart(String uid,String productId)=>db.collection('users').doc(uid).collection('cart').doc(productId).delete();
  Future<void> saveOffer({required String productId,required String ownerId,required String title,required int percent})=>products.doc(productId).collection('offers').doc('active').set({'productId':productId,'ownerId':ownerId,'title':title,'percent':percent,'active':true,'createdAt':FieldValue.serverTimestamp()});
  Stream<Map<String,dynamic>?> watchOffer(String productId)=>products.doc(productId).collection('offers').doc('active').snapshots().map((d)=>d.exists?d.data():null);
  Future<void> review({required String productId,required String userId,required int rating,required String text})=>products.doc(productId).collection('reviews').doc(userId).set({'productId':productId,'userId':userId,'rating':rating,'text':text,'createdAt':FieldValue.serverTimestamp()});
  Stream<List<Map<String,dynamic>>> watchReviews(String productId)=>products.doc(productId).collection('reviews').orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>d.data()).toList());
  Stream<List<Map<String,dynamic>>> watchAnalytics(String productId)=>products.doc(productId).collection('events').orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>d.data()).toList());
}
