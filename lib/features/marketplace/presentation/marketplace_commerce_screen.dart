import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/marketplace/marketplace_commerce_repository.dart';
import '../../../services/marketplace/marketplace_repository.dart';

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
      _section(context,'📦 طلباتي','متابعة الطلبات وحالاتها',()=>_orders(context,repo.watchBuyerOrders(uid),'طلباتي',false,repo)),
      _section(context,'🏪 طلبات البيع','قبول وتجهيز وشحن طلبات العملاء',()=>_orders(context,repo.watchSellerOrders(uid),'طلبات البيع',true,repo)),
      _section(context,'📊 تحليلات البائع','المشاهدات والرسائل والحفظ الفعلية',()=>_analytics(context)),
      _section(context,'⭐ التقييمات','تقييمات المنتجات والخدمات',()=>_reviews(context,repo)),
      _section(context,'🏷️ العروض','إدارة عروض المنتجات',()=>_offers(context,repo)),
      const Card(child:ListTile(leading:Icon(Icons.payments_outlined),title:Text('الدفع'),subtitle:Text('جاهز لربط بوابة الدفع المحلية/الدولية. الطلبات تحفظ طريقة الدفع ولا تنفذ خصماً مالياً تلقائياً.'))),
      const Card(child:ListTile(leading:Icon(Icons.local_shipping_outlined),title:Text('التوصيل والشحن'),subtitle:Text('حالة الطلب: pending → confirmed → processing → shipped → delivered → cancelled.'))),
    ]));
  }
  Widget _section(BuildContext c,String title,String sub,VoidCallback tap)=>Card(child:ListTile(title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:tap));
  void _cart(BuildContext c,MarketplaceCommerceRepository repo,String uid)=>showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>StreamBuilder<List<Map<String,dynamic>>>(stream:repo.watchCart(uid),builder:(c,s){final items=s.data??[];return SizedBox(height:MediaQuery.of(c).size.height*.7,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('السلة',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...items.map((x)=>ListTile(title:Text(x['name']?.toString()??x['productId']?.toString()??''),subtitle:Text('${x['quantity']??1} × ${x['unitPriceMinor']??0} ${x['currency']??''}'),trailing:IconButton(onPressed:()=>repo.removeFromCart(uid,x['productId']),icon:const Icon(Icons.delete_outline)))),const SizedBox(height:16),FilledButton.icon(onPressed:items.isEmpty?null:()async{String method='cash_on_delivery';final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('إتمام الطلب'),content:DropdownButtonFormField<String>(value:method,items:const [DropdownMenuItem(value:'cash_on_delivery',child:Text('الدفع عند الاستلام')),DropdownMenuItem(value:'pending_gateway',child:Text('دفع إلكتروني لاحقاً'))],onChanged:(v)=>method=v??method),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('تأكيد'))]));if(ok==true){try{await repo.checkoutCart(uid:uid,paymentMethod:method);if(c.mounted){Navigator.pop(c);ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('تم إنشاء الطلبات')));}}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('تعذر إتمام الطلب: $e')));}}},icon:const Icon(Icons.check_circle_outline),label:const Text('إتمام الطلب'))]));}));
  void _orders(BuildContext c,Stream<List<Map<String,dynamic>>> stream,String title,bool seller,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>StreamBuilder<List<Map<String,dynamic>>>(stream:stream,builder:(c,s)=>SizedBox(height:MediaQuery.of(c).size.height*.75,child:ListView(padding:const EdgeInsets.all(20),children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...((s.data??[]).map((x)=>Card(child:ListTile(title:Text('طلب ${x['id']}'),subtitle:Text('${x['quantity']??1} × ${x['totalMinor']??0} ${x['currency']??''}'),trailing:seller?PopupMenuButton<String>(onSelected:(v)=>repo.updateOrderStatus(x['id'],v),itemBuilder:(_)=>const [PopupMenuItem(value:'confirmed',child:Text('تأكيد')),PopupMenuItem(value:'processing',child:Text('تجهيز')),PopupMenuItem(value:'shipped',child:Text('شحن')),PopupMenuItem(value:'delivered',child:Text('تم التسليم')),PopupMenuItem(value:'cancelled',child:Text('إلغاء'))]):Text(x['status']?.toString()??'pending')))))])));
  void _analytics(BuildContext c){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>FutureBuilder<Map<String,int>>(future:MarketplaceRepository().analytics(uid),builder:(c,s){if(!s.hasData)return const SizedBox(height:220,child:Center(child:CircularProgressIndicator()));final a=s.data!;return SizedBox(height:360,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('تحليلات Marketplace',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:16),_stat('الإعلانات',a['products']??0),_stat('المشاهدات',a['views']??0),_stat('الرسائل',a['messages']??0),_stat('الحفظ',a['saves']??0)]));}));}
Widget _stat(String title,int value)=>Card(child:ListTile(title:Text(value.toString(),style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),subtitle:Text(title)));
  void _reviews(BuildContext c,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,builder:(_)=>const Padding(padding:EdgeInsets.all(24),child:Text('تقييمات المنتجات أصبحت مدعومة في طبقة Marketplace.')));
  void _offers(BuildContext c,MarketplaceCommerceRepository repo)=>showModalBottomSheet(context:c,builder:(_)=>const Padding(padding:EdgeInsets.all(24),child:Text('العروض أصبحت مدعومة في طبقة Marketplace.')));
}
