import 'package:flutter/material.dart';
import 'agent_marketplace_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/agents/agent_plugin_repository.dart';
class AurenAgentHubScreen extends StatefulWidget {
 const AurenAgentHubScreen({super.key});
 @override State<AurenAgentHubScreen> createState()=>_AurenAgentHubScreenState();
}
class _AurenAgentHubScreenState extends State<AurenAgentHubScreen>{
 bool busy=false;
 final _actionRepo = ActionRepository();
 static const _allowedActions = ['demo.echo', 'demo.create_note', 'memory.save'];
 Future<void> validatePlugin() async {
  setState(()=>busy=true);
  try {
   final result=await AurenAgentPluginRepository().validate({'pluginId':'auren.demo.plugin','name':'AUREN Demo Plugin','version':'1.0.0','capabilities':['actions.discover'],'entrypoint':'demo://plugin'});
   if(!mounted)return;
   showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Plugin Validated'),content:Text('Sandbox: '+(result.policy['sandbox']??'')+'\nNetwork: '+(result.policy['network']??'')+'\nSecrets: '+(result.policy['secrets']??'')+'\nTimeout: '+(result.policy['executionTimeoutMs']??'').toString()+'ms'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))]));
  } catch(e) { if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); }
  finally { if(mounted)setState(()=>busy=false); }
 }
 Future<void> _setAgentEnabled(bool enabled, Map<String,dynamic>? current) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await _actionRepo.setPermissionLedger(uid, enabled: enabled,
    allowedActions: List<String>.from(current?['allowedActions'] ?? _allowedActions),
    dailySpendingLimitMinor: current?['dailySpendingLimitMinor'] as int?);
 }
 Future<void> _showAudit(String uid) async {
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) =>
    StreamBuilder<List<Map<String,dynamic>>>(
      stream: _actionRepo.watchAudit(uid, limit: 30),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Map<String,dynamic>>[];
        return SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('AUREN Audit Trail', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (events.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد عمليات مسجلة حتى الآن.')),
            ...events.map((e) => Card(child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(e['actionType']?.toString() ?? 'agent.action'),
              subtitle: Text((e['status']?.toString() ?? 'unknown') + ' • risk: ' + (e['riskLevel']?.toString() ?? 'unknown') + '\n' + (e['result']?.toString() ?? 'تم تسجيل الحدث.')),
            ))),
          ]),
        ));
      },
    ),
  );
 }

 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Agents')),body: StreamBuilder<Map<String,dynamic>?>(
 stream: FirebaseAuth.instance.currentUser == null ? const Stream.empty() : _actionRepo.watchPermissionLedger(FirebaseAuth.instance.currentUser!.uid),
 builder: (context, permissionSnapshot) {
  final permission = permissionSnapshot.data;
  final enabled = permission?['enabled'] == true;
  return ListView(padding:const EdgeInsets.all(16),children:[
  Card(child:ListTile(leading:const Icon(Icons.security_outlined),title:const Text('Agent Permission Ledger'),subtitle:Text(enabled ? 'الصلاحيات مفعّلة' : 'الصلاحيات متوقفة'),trailing:Switch(value:enabled,onChanged:(v)=>_setAgentEnabled(v,permission)))),
  Card(child:ListTile(leading:const Icon(Icons.receipt_long_outlined),title:const Text('Audit Trail'),subtitle:const Text('سجل التنفيذ والموافقات والنتائج'),onTap:FirebaseAuth.instance.currentUser==null?null:()=>_showAudit(FirebaseAuth.instance.currentUser!.uid))),

  Card(child:ListTile(leading:const Icon(Icons.storefront_outlined),title:const Text('Agent Marketplace'),subtitle:const Text('اكتشف الوكلاء والقدرات المتاحة'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AgentMarketplaceScreen())))),
  Card(child:ListTile(leading:const Icon(Icons.extension_outlined),title:const Text('Developer / Plugins'),subtitle:const Text('تحقق من Plugin Manifest قبل النشر'),trailing:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator()):const Icon(Icons.verified_outlined),onTap:busy?null:validatePlugin)),
  const Card(child:ListTile(leading:Icon(Icons.hub_outlined),title:Text('Agent-to-Agent'),subtitle:Text('AUREN-A2A • هوية وصلاحيات وAudit'))),
  const Card(child:ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('Trust & Reputation'),subtitle:Text('هوية، قدرات، سجل تنفيذ وثقة'))),
  const Card(child:ListTile(leading:Icon(Icons.account_balance_wallet_outlined),title:Text('Agent Wallet'),subtitle:Text('حدود إنفاق وحجوزات معاملات'))),
 ]);
 },
 ) );
}