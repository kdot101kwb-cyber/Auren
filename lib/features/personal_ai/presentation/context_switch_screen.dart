import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/context_switch_service.dart';

class AurenContextSwitchScreen extends StatefulWidget { const AurenContextSwitchScreen({super.key}); @override State<AurenContextSwitchScreen> createState()=>_AurenContextSwitchScreenState(); }
class _AurenContextSwitchScreenState extends State<AurenContextSwitchScreen>{
 final _auth=FirebaseAurenAuthService(); final _service=ContextSwitchService(); String _mode='work'; bool _loading=false; AurenContextState? _state;
 final _labels={'work':'Work','learning':'Learning','travel':'Travel','personal':'Personal'};
 final _desc={'work':'تركيز على العمل والمهام.','learning':'تركيز على التعلم والمهارات.','travel':'تركيز على السفر والمكان.','personal':'تركيز على الحياة الشخصية.'};
 Future<void> _switch() async{final uid=_auth.currentUserId;if(uid==null)return;setState(()=>_loading=true);try{final s=await _service.switchTo(uid,mode:_mode,label:_labels[_mode]!,description:_desc[_mode]!);if(mounted)setState(()=>_state=s);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تبديل السياق: '+e.toString())));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Context Switch')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('بدّل سياقك بدون فقدان السياق السابق',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:8),
  const Text('اختَر الوضع الذي تريد أن يركز عليه AUREN الآن.'),const SizedBox(height:18),
  SegmentedButton<String>(segments:_labels.entries.map((e)=>ButtonSegment(value:e.key,label:Text(e.value))).toList(),selected:{_mode},onSelectionChanged:(v)=>setState(()=>_mode=v.first)),
  const SizedBox(height:18),FilledButton.icon(onPressed:_loading?null:_switch,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.swap_horiz),label:Text(_loading?'جاري التبديل…':'تبديل السياق')),
  if(_state!=null)...[const SizedBox(height:18),Card(child:ListTile(title:Text(_state!.label),subtitle:Text(_state!.description),leading:const Icon(Icons.check_circle_outline)))]
 ]));}