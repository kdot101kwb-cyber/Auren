import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/payments/agentic_commerce_service.dart';

class AurenAgenticCommerceScreen extends StatelessWidget{
 const AurenAgenticCommerceScreen({super.key});
 @override Widget build(BuildContext context){
  final uid=FirebaseAuth.instance.currentUser?.uid;
  if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً')));
  final service=AurenCommerceService();
  return Scaffold(appBar:AppBar(title:const Text('AUREN Commerce AI')),body:StreamBuilder<List<AurenCommerceIntent>>(stream:service.watch(uid),builder:(context,s){
    if(s.hasError)return Center(child:Text('تعذر تحميل العمليات: ${s.error}'));
    final items=s.data??const [];
    if(items.isEmpty)return const Center(child:Text('لا توجد عمليات شراء مقترحة.'));
    return ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,i){
      final x=items[i];
      return Card(child:ListTile(title:Text(x.action=='purchase'?'شراء':'عملية'),subtitle:Text('${x.amountMinor/100} ${x.currency} • ${x.status}'),trailing:x.status=='awaiting_approval'?Wrap(children:[IconButton(icon:const Icon(Icons.check),onPressed:()=>service.approve(uid,x.id)),IconButton(icon:const Icon(Icons.close),onPressed:()=>service.cancel(uid,x.id))]):null));
    });
  }));
 }
}
