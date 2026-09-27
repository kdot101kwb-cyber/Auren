import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/payments/wallet_service.dart';

class AurenWalletScreen extends StatefulWidget{
 const AurenWalletScreen({super.key});
 @override State<AurenWalletScreen> createState()=>_AurenWalletScreenState();
}
class _AurenWalletScreenState extends State<AurenWalletScreen>{
 final service=AurenWalletService(); final currency=TextEditingController(text:'USD');
 @override void dispose(){currency.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final uid=FirebaseAuth.instance.currentUser?.uid;
  if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً')));
  return Scaffold(appBar:AppBar(title:const Text('AUREN Wallet')),body:StreamBuilder<AurenWallet?>(stream:service.watch(uid),builder:(context,s){
   if(s.hasError)return Center(child:Text('تعذر تحميل المحفظة: ${s.error}'));
   final w=s.data;
   return ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet_outlined),title:Text(w==null?'المحفظة غير مفعّلة':w.currency),subtitle:Text(w==null?'أنشئ محفظتك للبدء':'الرصيد: ${((w.balanceMinor)/100).toStringAsFixed(2)} ${w.currency}'))),
    if(w==null)FilledButton.icon(onPressed:()async{try{await service.initialize(uid:uid,currency:currency.text);if(mounted)setState((){});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}},icon:const Icon(Icons.add),label:const Text('إنشاء المحفظة')),
    if(w!=null)ListTile(title:const Text('حد الإنفاق'),subtitle:const Text('حماية إضافية قبل ربط بوابات الدفع'),trailing:TextButton(onPressed:()=>_limit(context,uid),child:const Text('تعديل'))),
    const SizedBox(height:12),const Text('المعاملات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    StreamBuilder<List<Map<String,dynamic>>>(stream:service.watchTransactions(uid),builder:(context,t){final items=t.data??const [];if(items.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('لا توجد معاملات بعد.')));return Column(children:items.map((x)=>Card(child:ListTile(title:Text(x['type']?.toString()??'Transaction'),subtitle:Text(x['currency']?.toString()??''),trailing:Text(x['amountMinor']?.toString()??'0')))).toList());})
   ]);
  }));
 }
 Future<void> _limit(BuildContext context,String uid)async{
  final c=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('حد الإنفاق'),content:TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'بالوحدة الصغرى للعملة')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حفظ'))]));
  if(ok==true){final v=int.tryParse(c.text.trim());if(v!=null)try{await service.setSpendingLimit(uid:uid,limitMinor:v);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  c.dispose();
 }
}
