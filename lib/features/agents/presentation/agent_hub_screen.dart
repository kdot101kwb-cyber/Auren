import 'package:flutter/material.dart';
import 'agent_marketplace_screen.dart';
class AurenAgentHubScreen extends StatelessWidget {
 const AurenAgentHubScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Agents')),body:ListView(padding:const EdgeInsets.all(16),children:const [
 Card(child:ListTile(leading:Icon(Icons.storefront_outlined),title:Text('Agent Marketplace'),subtitle:Text('اكتشف الوكلاء والقدرات المتاحة'))),
 Card(child:ListTile(leading:Icon(Icons.hub_outlined),title:Text('Agent-to-Agent'),subtitle:Text('AUREN-A2A • اتصال بين الوكلاء بإذن وصلاحيات'))),
 Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('Trust & Reputation'),subtitle:Text('هوية، قدرات، سجل تنفيذ وثقة'))),
 Card(child:ListTile(leading:Icon(Icons.account_balance_wallet_outlined),title:Text('Agent Wallet'),subtitle:Text('حدود إنفاق وحجوزات معاملات'))),
 ]));
 }
}