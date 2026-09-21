import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_commerce_repository.dart';

class AurenMarketplaceCommerceScreen extends StatelessWidget {
  const AurenMarketplaceCommerceScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=MarketplaceCommerceRepository();
    return Scaffold(appBar:AppBar(title:const Text('Marketplace Center')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('التجارة والطلبات',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      _section(context,'🛒 السلة','المنتجات المحفوظة للشراء',()=>_cart(context,repo,uid)),
      _section(context,'📦 طلباتي','متابعة الطلبات وحالاتها',()=>_orders(context,repo.watchBuyerOrders(uid),'طلباتي')),
      _section(context,'🏪 طلبات البيع','طلبات العملاء لنشاطك',()=>_orders(context,repo.watchSellerOrders(uid),'طلبات البيع')),
      _section(context,'📊 تحليلات','المشاهدات والرسائل والحفظ لكل إعلان',()=>_analytics(context,repo)),
      _section(context,'⭐ التقييمات','تقييمات المنتجات والخدمات',()=>_reviews(context,repo)),
      _section(context,'🏷️ العروض','إدارة عروض المنتجات',()=>_offers(context,repo)),
      const Card(child:ListTile(leading:Icon(Icons.payments_outlined),title:Text('الدفع'),subtitle:Text('جاهز لربط بوابة الدفع المحلية/الدولية. الطلبات تحفظ طريقة الدفع ولا تنفذ خصماً مالياً تلقائياً.'))),
      const Card(child:ListTile(leading:Icon(Icons.local_shipping_outlined),title:Text('التوصيل والشحن'),subtitle:Text('حالة الطلب: pending → confirmed → processing → shipped → delivered → cancelled.'))),
    ]));
  }
  Widget _section(BuildContext c,String title,String sub,VoidCallback tap)=>Card(child:ListTile(title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:tap));
  void _cart(BuildContext c,MarketplaceCommerceRepository repo,String uid)=>showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>StreamBuilder<List<Map<String,dynamic>>>(stream:repo.watchCart(uid),builder:(c,s){final items=s.data??[];return SizedBox(height:MediaQuery.of(c).size.height*.7,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('السلة',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...items.map((x)=>ListTile(title:Text(x['productId']?.toString()??''),subtitle:Text('الكمية: ${x['quantity']??1}'),trailing:IconButton(onPressed:()=>repo.removeFromCart(uid,x['productId']),icon:const Icon(Icons.delete_outline))))]));}));
  void _orders(BuildContext c,Stream<List<Map<String,dynamic>>> stream,String title)=>showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>StreamBuilder<List<Map<String,dynamic>>>(stream:stream,builder:(c,s)=>SizedBox(height:MediaQuery.of(c).size.height*.75,child:ListView(padding:const EdgeInsets.all(20),children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...((s.data??[]).map((x)=>Card(child:ListTile(title:Text('طلب ${x['id']}'),subtitle:Text('${x['quantity']??1} × ${x['totalMinor']??0} ${x['currency']??''}'),trailing:Text(x['status']?.toString()??'pending')))))])));
  void _analytics(BuildContext c,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,builder:(_)=>const Padding(padding:EdgeInsets.all(24),child:Text('تحليلات الإعلانات أصبحت مدعومة في طبقة Marketplace.')));
  void _reviews(BuildContext c,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,builder:(_)=>const Padding(padding:EdgeInsets.all(24),child:Text('تقييمات المنتجات أصبحت مدعومة في طبقة Marketplace.')));
  void _offers(BuildContext c,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,builder:(_)=>const Padding(padding:EdgeInsets.all(24),child:Text('العروض أصبحت مدعومة في طبقة Marketplace.')));
}
