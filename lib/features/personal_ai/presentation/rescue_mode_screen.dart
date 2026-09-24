import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/rescue_mode_service.dart';
class AurenRescueModeScreen extends StatefulWidget { const AurenRescueModeScreen({super.key}); @override State<AurenRescueModeScreen> createState()=>_AurenRescueModeScreenState(); }
class _AurenRescueModeScreenState extends State<AurenRescueModeScreen>{
 final _auth=FirebaseAurenAuthService(); final _service=RescueModeService(); AurenRescuePlan? _plan; bool _loading=false;
 Future<void> _start() async { final uid=_auth.currentUserId;if(uid==null)return;setState(()=>_loading=true);try{final p=await _service.build(uid);if(mounted)setState(()=>_plan=p);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تشغيل Rescue Mode: ${e}')));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Rescue Mode')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('لما تكون مشتّت أو متوقف…',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:8),
  const Text('AUREN يقلل الحمل إلى أولوية واحدة وخطوات صغيرة. لا ينفذ إجراءات حساسة تلقائيًا.'),const SizedBox(height:20),
  FilledButton.icon(onPressed:_loading?null:_start,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.health_and_safety_outlined),label:Text(_loading?'جاري التجهيز…':'ابدأ Rescue Mode')),
  if(_plan!=null)...[const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(_plan!.summary,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:12),
   ..._plan!.steps.map((s)=>ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(child:Text('${s.order}')),title:Text(s.title),subtitle:Text('${s.action}\n${s.reason}')))
  ])))]
 ])); }