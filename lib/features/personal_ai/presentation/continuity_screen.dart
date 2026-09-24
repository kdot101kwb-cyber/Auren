import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/continuity_service.dart';
class AurenContinuityScreen extends StatefulWidget { const AurenContinuityScreen({super.key}); @override State<AurenContinuityScreen> createState()=>_AurenContinuityScreenState(); }
class _AurenContinuityScreenState extends State<AurenContinuityScreen>{
 final _auth=FirebaseAurenAuthService(); final _service=ContinuityService(); AurenContinuitySnapshot? _snapshot; bool _loading=false;
 Future<void> _resume() async{final uid=_auth.currentUserId;if(uid==null)return;setState(()=>_loading=true);try{final s=await _service.resume(uid);if(mounted)setState(()=>_snapshot=s);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر استئناف السياق: '+e.toString())));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Continuity')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('كمّل من حيث توقفت',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:8),
  const Text('AUREN يعيد بناء نقطة الاستئناف من أهدافك وذاكرتك المفعّلة، بدون إنشاء نسخة ثانية من بياناتك.'),const SizedBox(height:20),
  FilledButton.icon(onPressed:_loading?null:_resume,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.play_circle_outline),label:Text(_loading?'جاري الاستئناف…':'استأنف الآن')),
  if(_snapshot!=null)...[const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(_snapshot!.summary,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:12),Text('أهداف نشطة: '+_snapshot!.activeGoals.toString()),Text('ذكريات مفعّلة: '+_snapshot!.enabledMemories.toString()),if(_snapshot!.focus!=null)Text('التركيز: '+_snapshot!.focus!)
  ])))]
 ]));}