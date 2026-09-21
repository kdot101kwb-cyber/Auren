import 'package:cloud_firestore/cloud_firestore.dart';
class MarketplaceCommerceRepository {
  final FirebaseFirestore db;
  MarketplaceCommerceRepository({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> get products=>db.collection('products');
  CollectionReference<Map<String,dynamic>> get orders=>db.collection('marketplace_orders');
  Future<String> createOrder({required String buyerId,required String productId,required String sellerId,required int quantity,required int unitPriceMinor,required String currency,required String paymentMethod,required String deliveryAddress,required String deliveryPhone,String? productName,String? productImageUrl,String deliveryProviderId='manual',int deliveryFeeMinor=0}) async {
    if(!{'cash_on_delivery','pending_gateway'}.contains(paymentMethod)) throw ArgumentError('طريقة دفع غير صالحة');
    if(quantity<1||quantity>1000) throw ArgumentError('كمية غير صالحة');
    if(deliveryAddress.trim().isEmpty||deliveryAddress.trim().length>500) throw ArgumentError('عنوان توصيل غير صالح');
    if(deliveryPhone.trim().isEmpty||deliveryPhone.trim().length>40) throw ArgumentError('رقم هاتف غير صالح');
    if(deliveryProviderId.trim().isEmpty||deliveryProviderId.trim().length>60) throw ArgumentError('شركة توصيل غير صالحة');
    const providers={'manual','sa3i','link_express','afrimex','twseel','wdee'};
    if(!providers.contains(deliveryProviderId.trim())) throw ArgumentError('شركة توصيل غير صالحة');
    if(deliveryFeeMinor<0||deliveryFeeMinor>1000000000) throw ArgumentError('رسوم توصيل غير صالحة');
    if(unitPriceMinor<0||unitPriceMinor>1000000000) throw ArgumentError('سعر غير صالح');
    if(currency.trim().length!=3||currency.trim()!=currency.trim().toUpperCase()) throw ArgumentError('عملة غير صالحة');
    final ref=orders.doc();
    final notificationRef=db.collection('marketplace_notifications').doc();
    final batch=db.batch();
    batch.set(ref,{'buyerId':buyerId,'sellerId':sellerId,'productId':productId,'quantity':quantity,'unitPriceMinor':unitPriceMinor,'deliveryFeeMinor':deliveryFeeMinor,'totalMinor':unitPriceMinor*quantity+deliveryFeeMinor,'currency':currency,'paymentMethod':paymentMethod,'paymentStatus':paymentMethod=='cash_on_delivery'?'unpaid':'pending','deliveryProviderId':deliveryProviderId,'shipmentId':null,'trackingNumber':null,'trackingUrl':null,'deliveryStatus':'pending','productName':productName ?? '','productImageUrl':productImageUrl ?? '','deliveryAddress':deliveryAddress.trim(),'deliveryPhone':deliveryPhone.trim(),'status':'pending','estimatedDeliveryAt':Timestamp.fromDate(DateTime.now().add(const Duration(days:3))),'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'statusUpdatedAt':FieldValue.serverTimestamp()});
    batch.set(notificationRef,{'recipientUid':sellerId,'actorUid':buyerId,'orderId':ref.id,'type':'order_created','title':'طلب جديد','body':'لديك طلب جديد في Marketplace','createdAt':FieldValue.serverTimestamp(),'read':false});
    await batch.commit();
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
    final ref=orders.doc(id);
    final snap=await ref.get();
    if(!snap.exists||snap.data()==null) throw StateError('الطلب غير موجود');
    final order=snap.data()!;
    final currentStatus=order['status']?.toString() ?? 'pending';
    const transitions={
      'pending': {'confirmed','cancelled'},
      'confirmed': {'processing','cancelled'},
      'processing': {'shipped','cancelled'},
      'shipped': {'delivered'},
      'delivered': <String>{},
      'cancelled': <String>{},
    };
    if(status!=currentStatus && !(transitions[currentStatus] ?? const <String>{}).contains(status)) throw StateError('انتقال حالة الطلب غير مسموح');
    final notificationRef=db.collection('marketplace_notifications').doc();
    final batch=db.batch();
    batch.update(ref,{'status':status,'deliveryStatus':status,'updatedAt':FieldValue.serverTimestamp(),'statusUpdatedAt':FieldValue.serverTimestamp()});
    batch.set(notificationRef,{
      'recipientUid':order['buyerId'],
      'actorUid':order['sellerId'],
      'orderId':id,
      'type':'order_status',
      'title':'تحديث الطلب',
      'body':'تم تحديث حالة الطلب إلى $status',
      'createdAt':FieldValue.serverTimestamp(),
      'read':false,
    });
    await batch.commit();
  }
  Future<void> attachShipment({required String orderId,required String providerId,String? shipmentId,String? trackingNumber,String? trackingUrl,DateTime? estimatedDeliveryAt}) async {
    final ref=orders.doc(orderId);
    final snap=await ref.get();
    if(!snap.exists||snap.data()==null) throw StateError('الطلب غير موجود');
    final order=snap.data()!;
    const providers={'manual','sa3i','link_express','afrimex','twseel','wdee'};
    if(!providers.contains(providerId)) throw ArgumentError('شركة توصيل غير صالحة');
    if(shipmentId!=null && shipmentId.length>120) throw ArgumentError('معرّف شحنة غير صالح');
    if(trackingNumber!=null && trackingNumber.length>120) throw ArgumentError('رقم تتبع غير صالح');
    if(trackingUrl!=null && trackingUrl.length>1000) throw ArgumentError('رابط تتبع غير صالح');
    final currentStatus=order['status']?.toString() ?? 'pending';
    if(!{'pending','confirmed','processing'}.contains(currentStatus)) throw StateError('لا يمكن شحن الطلب من حالته الحالية');
    final data=<String,dynamic>{
      'deliveryProviderId':providerId,
      'shipmentId':shipmentId,
      'trackingNumber':trackingNumber,
      'trackingUrl':trackingUrl,
      'deliveryStatus':'shipped',
      if(estimatedDeliveryAt!=null) 'estimatedDeliveryAt':Timestamp.fromDate(estimatedDeliveryAt),
      'status':'shipped',
      'updatedAt':FieldValue.serverTimestamp(),
      'statusUpdatedAt':FieldValue.serverTimestamp(),
    };
    final notificationRef=db.collection('marketplace_notifications').doc();
    final batch=db.batch();
    batch.update(ref,data);
    batch.set(notificationRef,{
      'recipientUid':order['buyerId'],
      'actorUid':order['sellerId'],
      'orderId':orderId,
      'type':'shipment_created',
      'title':'تم شحن الطلب',
      'body':trackingNumber==null?'تم إنشاء الشحنة':'رقم التتبع: $trackingNumber',
      'createdAt':FieldValue.serverTimestamp(),
      'read':false,
    });
    await batch.commit();
  }
  Future<void> updateDeliveryStatus(String id,String status) async {
    const allowed={'pending','assigned','picked_up','shipped','delivered','failed','returned'};
    if(!allowed.contains(status)) throw ArgumentError('حالة توصيل غير صالحة');
    final ref=orders.doc(id);
    final snap=await ref.get();
    if(!snap.exists||snap.data()==null) throw StateError('الطلب غير موجود');
    final order=snap.data()!;
    final current=order['deliveryStatus']?.toString() ?? 'pending';
    const transitions={
      'pending': {'assigned','failed'},
      'assigned': {'picked_up','failed'},
      'picked_up': {'shipped','failed'},
      'shipped': {'delivered','failed','returned'},
      'delivered': <String>{},
      'failed': {'assigned','returned'},
      'returned': <String>{},
    };
    if(status!=current && !(transitions[current] ?? const <String>{}).contains(status)) throw StateError('انتقال حالة التوصيل غير مسموح');
    final batch=db.batch();
    final notificationRef=db.collection('marketplace_notifications').doc();
    batch.update(ref,{'deliveryStatus':status,'updatedAt':FieldValue.serverTimestamp()});
    batch.set(notificationRef,{
      'recipientUid':order['buyerId'],'actorUid':order['sellerId'],'orderId':id,
      'type':'order_status','title':'تحديث التوصيل','body':'تم تحديث حالة التوصيل إلى $status',
      'createdAt':FieldValue.serverTimestamp(),'read':false,
    });
    await batch.commit();
  }
  Future<void> updateCartQuantity({required String uid,required String productId,required int quantity}) async {
    if(quantity<1){await removeFromCart(uid,productId);return;}
    if(quantity>100) throw ArgumentError('الكمية القصوى 100');
    await db.collection('users').doc(uid).collection('cart').doc(productId).update({'quantity':quantity});
  }
  Future<void> addToCartWithSnapshot({required String uid,required String productId,required int quantity}) async { final p=await products.doc(productId).get(); if(!p.exists||p.data()==null) throw StateError('المنتج غير موجود'); final d=p.data()!; await db.collection('users').doc(uid).collection('cart').doc(productId).set({'productId':productId,'name':d['name'],'sellerId':d['ownerId'],'unitPriceMinor':d['priceMinor'],'currency':d['currency'],'quantity':quantity.clamp(1,100),'addedAt':FieldValue.serverTimestamp()}); }
  Future<String> checkoutCart({required String uid,required String paymentMethod,required String deliveryAddress,required String deliveryPhone,String deliveryProviderId='manual',int deliveryFeeMinor=0}) async {
    if(!{'cash_on_delivery','pending_gateway'}.contains(paymentMethod)) throw ArgumentError('طريقة دفع غير صالحة');
    if(deliveryAddress.trim().isEmpty||deliveryAddress.trim().length>500) throw ArgumentError('عنوان توصيل غير صالح');
    if(deliveryPhone.trim().isEmpty||deliveryPhone.trim().length>40) throw ArgumentError('رقم هاتف غير صالح');
    if(deliveryFeeMinor<0||deliveryFeeMinor>1000000000) throw ArgumentError('رسوم توصيل غير صالحة');
    if(deliveryProviderId.trim().isEmpty||deliveryProviderId.trim().length>60) throw ArgumentError('شركة توصيل غير صالحة');
    const providers={'manual','sa3i','link_express','afrimex','twseel','wdee'};
    if(!providers.contains(deliveryProviderId.trim())) throw ArgumentError('شركة توصيل غير صالحة');
    final snap=await db.collection('users').doc(uid).collection('cart').get();
    if(snap.docs.isEmpty) throw StateError('السلة فارغة');
    String? checkoutCurrency;
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
        if((d['currency']?.toString() ?? '').length!=3||d['currency'].toString()!=d['currency'].toString().toUpperCase()) throw StateError('عملة المنتج غير صالحة: $productId');
        final sellerId=d['ownerId']?.toString() ?? '';
        final price=(d['priceMinor'] as num?)?.toInt() ?? 0;
        final currency=d['currency']?.toString() ?? 'USD';
        if(sellerId.isEmpty) throw StateError('المنتج لا يملك بائعاً صالحاً: $productId');
        if(quantity<1||quantity>100) throw StateError('كمية غير صالحة: $productId');
        if(checkoutCurrency == null) {
          checkoutCurrency = currency;
        } else if(checkoutCurrency != currency) {
          throw StateError('السلة تحتوي على عملات مختلفة؛ افصل الطلبات حسب العملة.');
        }
        if(price<0||price>1000000000) throw StateError('سعر المنتج غير صالح: $productId');
        validated.add({'cart':cart,'productId':productId,'sellerId':sellerId,'quantity':quantity,'price':price,'currency':currency,'name':d['name']?.toString() ?? '','imageUrl':d['imageUrl']?.toString() ?? ''});
    }
    if(validated.length>450) throw StateError('السلة تحتوي على عناصر كثيرة جداً للمعاملة الواحدة');
    final batch=db.batch();
    final createdOrders=<Map<String,dynamic>>[];
    for(final v in validated){
      final ref=orders.doc();
      final orderData=<String,dynamic>{
        'buyerId':uid,'sellerId':v['sellerId'],'productId':v['productId'],'quantity':v['quantity'],
        'unitPriceMinor':v['price'],'deliveryFeeMinor':deliveryFeeMinor,
        'totalMinor':v['price']*v['quantity']+deliveryFeeMinor,'currency':v['currency'],
        'paymentMethod':paymentMethod,'paymentStatus':paymentMethod=='cash_on_delivery'?'unpaid':'pending',
        'deliveryProviderId':deliveryProviderId,'shipmentId':null,'trackingNumber':null,'trackingUrl':null,
        'deliveryStatus':'pending','productName':v['name'],'productImageUrl':v['imageUrl'],
        'deliveryAddress':deliveryAddress.trim(),'deliveryPhone':deliveryPhone.trim(),'status':'pending',
        'estimatedDeliveryAt':Timestamp.fromDate(DateTime.now().add(const Duration(days:3))),
        'createdAt':FieldValue.serverTimestamp(),
        'updatedAt':FieldValue.serverTimestamp(),
        'statusUpdatedAt':FieldValue.serverTimestamp(),
      };
      batch.set(ref,orderData);
      createdOrders.add({'id':ref.id,'sellerId':v['sellerId']});
      if(firstOrder.isEmpty) firstOrder=ref.id;
    }
    for(final cart in snap.docs) batch.delete(cart.reference);
    await batch.commit();
    final notificationBatch=db.batch();
    for(final order in createdOrders){
      final notificationRef=db.collection('marketplace_notifications').doc();
      notificationBatch.set(notificationRef,{
        'recipientUid':order['sellerId'],'actorUid':uid,'orderId':order['id'],
        'type':'order_created','title':'طلب جديد','body':'لديك طلب جديد في Marketplace',
        'createdAt':FieldValue.serverTimestamp(),'read':false,
      });
    }
    await notificationBatch.commit();
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
