import 'package:flutter/material.dart';
import 'agent_marketplace_screen.dart';
import '../../../services/agents/agent_plugin_repository.dart';
class AurenAgentHubScreen extends StatefulWidget {
 const AurenAgentHubScreen({super.key});
 @override State<AurenAgentHubScreen> createState()=>_AurenAgentHubScreenState();
}
class _AurenAgentHubScreenState extends State<AurenAgentHubScreen>{
 bool busy=false;
 Future<void> validatePlugin() async {
  setState(()=>busy=true);
  try {
   final result=await AurenAgentPluginRepository().validate({'pluginId':'auren.demo.plugin','name':'AUREN Demo Plugin','version':'1.0.0','capabilities':['actions.discover'],'entrypoint':'demo://plugin'});
   if(!mounted)return;
   showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Plugin Validated'),content:Text('Sandbox: '+(result.policy['sandbox']??'')+'\nNetwork: '+(result.policy['network']??'')+'\nSecrets: '+(result.policy['secrets']??'')+'\nTimeout: '+(result.policy['executionTimeoutMs']??'').toString()+'ms'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))]));
  } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); }
  finally { if(mounted)setState(()=>busy=false); }
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Agents')),body:ListView(padding:const EdgeInsets.all(16),children:[
  Card(child:ListTile(leading:const Icon(Icons.storefront_outlined),title:const Text('Agent Marketplace'),subtitle:const Text('اكتشف الوكلاء والقدرات المتاحة'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AgentMarketplaceScreen())))),
  Card(child:ListTile(leading:const Icon(Icons.extension_outlined),title:const Text('Developer / Plugins'),subtitle:const Text('تحقق من Plugin Manifest قبل النشر'),trailing:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator()):const Icon(Icons.verified_outlined),onTap:busy?null:validatePlugin)),
  const Card(child:ListTile(leading:Icon(Icons.hub_outlined),title:Text('Agent-to-Agent'),subtitle:Text('AUREN-A2A • هوية وصلاحيات وAudit'))),
  const Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('Trust & Reputation'),subtitle:Text('هوية، قدرات، سجل تنفيذ وثقة'))),
  const Card(child:ListTile(leading:Icon(Icons.account_balance_wallet_outlined),title:Text('Agent Wallet'),subtitle:Text('حدود إنفاق وحجوزات معاملات'))),
 ]));
}