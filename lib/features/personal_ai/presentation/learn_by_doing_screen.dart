import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/learn_by_doing_service.dart';

class AurenLearnByDoingScreen extends StatefulWidget{const AurenLearnByDoingScreen({super.key});@override State<AurenLearnByDoingScreen> createState()=>_AurenLearnByDoingScreenState();}
class _AurenLearnByDoingScreenState extends State<AurenLearnByDoingScreen>{
 final _auth=FirebaseAurenAuthService(); final _service=AurenLearnByDoingService(); Future<AurenLearnByDoingPlan>? _future; final _skill=TextEditingController();
 @override void initState(){super.initState();_load();} void _load(){final uid=_auth.currentUserId;if(uid!=null)setState(()=>_future=_service.build(uid,skill:_skill.text));}
 @override void dispose(){_skill.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Learn by Doing')),body:FutureBuilder<AurenLearnByDoingPlan>(future:_future,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('تعذر بناء المسار: ${s.error}'));final p=s.data; if(p==null)return const SizedBox.shrink(); final done=p.steps.where((x)=>x.completed).length; return ListView(padding:const EdgeInsets.all(16),children:[
 const Text('تعلّم بالتطبيق',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('الهدف: ${p.goalTitle}'),Text('المهارة: ${p.skill}'),const SizedBox(height:12),LinearProgressIndicator(value:p.steps.isEmpty?0:done/p.steps.length),const SizedBox(height:16),
 TextField(controller:_skill,decoration:const InputDecoration(labelText:'مهارة اختيارية',hintText:'مثال: التسويق الرقمي'),onSubmitted:(_)=>_load()),const SizedBox(height:8),
 FilledButton.icon(onPressed:_load,icon:const Icon(Icons.auto_awesome),label:const Text('ابنِ المسار')),const SizedBox(height:12),
 for(final step in p.steps) Card(child:CheckboxListTile(value:step.completed,onChanged:(v){final uid=_auth.currentUserId;if(uid!=null&&v!=null){_service.toggle(uid,step.id,v).then((_)=>_load());}},title:Text(step.title),subtitle:Text('${step.description}\n${step.action}'))),
 ]);});
}