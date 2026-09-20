import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agents/agent_wallet_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
class AgentWalletScreen extends StatelessWidget {
 const AgentWalletScreen({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null)return const Scaffold(body:Center(child:Text('يجب تسجيل الدخول.')));
  final repo=AurenAgentWalletRepository();
  return Scaffold(appBar:AppBar(title:const Text('Agent Wallet')),body:ListView(padding:const EdgeInsets.all(16),children:[
   StreamBuilder(stream:repo.watch(uid),builder:(context,s){final w=s.data; return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('الرصيد والحدود',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:12),
    Text(w==null?'لم يتم إنشاء المحفظة بعد.':'الرصيد المتاح: '+(w.availableMinor/100).toStringAsFixed(2)+' '+w.currency),
    if(w!=null)Text('محجوز: '+(w.reservedMinor/100).toStringAsFixed(2)+' • الحد اليومي: '+(w.dailyLimitMinor/100).toStringAsFixed(2)+' '+w.currency)
   ])));}),
   const SizedBox(height:12),FilledButton.icon(onPressed:() async { try { await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('fundAurenAgentWallet').call({'amountMinor':1000,'currency':'USD'}); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة رصيد تجريبي.'))); } catch(e) { if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تمويل المحفظة: $e'))); } }, icon:const Icon(Icons.add_card), label:const Text('إضافة رصيد تجريبي')),const SizedBox(height:16),const Text('آخر العمليات',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:8),
   StreamBuilder(stream:repo.watchTransactions(uid),builder:(context,s){final tx=s.data??const []; return tx.isEmpty?const Text('لا توجد عمليات مالية بعد.'):Column(children:tx.map<Widget>((x)=>ListTile(leading:const Icon(Icons.receipt_long_outlined),title:Text(x['type']?.toString()??'transaction'),subtitle:Text(x['status']?.toString()??'unknown'),trailing:Text(x['amountMinor']?.toString()??'0'))).toList());})
  ]));
 }
}
