import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/handoff_service.dart';
class AurenHandoffScreen extends StatefulWidget { const AurenHandoffScreen({super.key}); @override State<AurenHandoffScreen> createState()=>_AurenHandoffScreenState(); }
class _AurenHandoffScreenState extends State<AurenHandoffScreen>{
 final _auth=FirebaseAurenAuthService(); final _service=HandoffService(); final _destination=TextEditingController(text:'AUREN'); AurenHandoff? _handoff; bool _loading=false;
 Future<void> _create() async{final uid=_auth.currentUserId;if(uid==null)return;setState(()=>_loading=true);try{final h=await _service.build(uid,destination:_destination.text);if(mounted)setState(()=>_handoff=h);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إنشاء التسليم: '+e.toString())));}finally{if(mounted)setState(()=>_loading=false);}}
 @override void dispose(){_destination.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Handoff')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('سلّم المهمة بدون إعادة الشرح',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:8),const Text('AUREN يجمع السياق المهم في حزمة تسليم، بدون نقل أو حذف بياناتك الأصلية.'),
  const SizedBox(height:20),TextField(controller:_destination,decoration:const InputDecoration(labelText:'إلى من؟',border:OutlineInputBorder())),const SizedBox(height:12),
  FilledButton.icon(onPressed:_loading?null:_create,icon:_loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.forward_outlined),label:Text(_loading?'جاري التجهيز…':'أنشئ Handoff')),
  if(_handoff!=null)...[const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(_handoff!.summary,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:12),Text('الوجهة: '+_handoff!.destination),const SizedBox(height:8),..._handoff!.context.map((x)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.link_outlined),title:Text(x)))
  ])))]
 ]));}