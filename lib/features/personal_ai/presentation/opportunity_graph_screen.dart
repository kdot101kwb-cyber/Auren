import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/opportunity_graph_service.dart';

class AurenOpportunityGraphScreen extends StatefulWidget { const AurenOpportunityGraphScreen({super.key}); @override State<AurenOpportunityGraphScreen> createState()=>_AurenOpportunityGraphScreenState(); }
class _AurenOpportunityGraphScreenState extends State<AurenOpportunityGraphScreen> {
  final _auth=FirebaseAurenAuthService();
  final _service=AurenOpportunityGraphService();
  Future<List<AurenOpportunityGraphNode>>? _future;
  @override void initState(){super.initState(); final uid=_auth.currentUserId; if(uid!=null)_future=_service.build(uid);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Personal Opportunity Graph')),body:FutureBuilder<List<AurenOpportunityGraphNode>>(future:_future,builder:(context,s){
    if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return Center(child:Text('تعذر بناء الرسم الآن: ${s.error}'));
    final nodes=s.data??[]; return RefreshIndicator(onRefresh:()async{final uid=_auth.currentUserId;if(uid!=null)setState(()=>_future=_service.build(uid));},child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('شبكة فرصك',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),const Text('يربط أهدافك وسياقك وأعمالك بإشارات فرص عامة. لا يرسل رسائل ولا ينفذ إجراءً تلقائياً.'),
      const SizedBox(height:16),
      for(final n in nodes) Card(child:ListTile(leading:Icon(n.type=='goal'?Icons.flag:n.type=='business'?Icons.storefront:n.type=='opportunity'?Icons.lightbulb_outline:Icons.psychology),title:Text(n.title),subtitle:Text(n.detail),trailing:Text('${(n.score*100).round()}%'))),
    ]));
  }));
}