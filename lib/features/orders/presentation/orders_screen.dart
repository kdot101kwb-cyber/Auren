import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/orders/order_service.dart';
class AurenOrdersScreen extends StatelessWidget{
 const AurenOrdersScreen({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً')));final s=AurenOrderService();return Scaffold(appBar:AppBar(title:const Text('Orders & Delivery')),body:StreamBuilder<List<AurenOrder>>(stream:s.watchBuyer(uid),builder:(c,x){if(x.hasError)return Center(child:Text('تعذر تحميل الطلبات: ${x.error}'));final a=x.data??const [];if(a.isEmpty)return const Center(child:Text('لا توجد طلبات بعد.'));return ListView.builder(padding:const EdgeInsets.all(16),itemCount:a.length,itemBuilder:(c,i){final o=a[i];return Card(child:ListTile(title:Text(o.title),subtitle:Text('${o.amountMinor/100} ${o.currency} • ${o.deliveryStatus}'),leading:const Icon(Icons.local_shipping_outlined)));});}));}
}