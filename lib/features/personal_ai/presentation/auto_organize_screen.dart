import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/auto_organize_service.dart';

class AurenAutoOrganizeScreen extends StatefulWidget{
  const AurenAutoOrganizeScreen({super.key});
  @override State<AurenAutoOrganizeScreen> createState()=>_AurenAutoOrganizeScreenState();
}
class _AurenAutoOrganizeScreenState extends State<AurenAutoOrganizeScreen>{
  final _auth=FirebaseAurenAuthService(); final _service=AutoOrganizeService(); String? _uid; bool _busy=false;
  @override void initState(){super.initState();_uid=_auth.currentUserId;}
  Future<void> _run() async{
    final uid=_uid;if(uid==null||_busy)return;setState(()=>_busy=true);
    try{await _service.build(uid);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تنظيم السياق واقتراح التصنيفات.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر التنظيم: $e')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context){
    final uid=_uid;if(uid==null)return const Scaffold(body:Center(child:Text('Sign in required.')));
    return Scaffold(appBar:AppBar(title:const Text('AUREN Auto-Organize')),body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      stream:_service.watch(uid),builder:(context,s){
        final data=s.data?.data();final raw=data?['items'];final items=raw is List?raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():const <Map<String,dynamic>>[];
        return ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('تنظيم ذكي بدون حذف',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
            const Text('AUREN يقرأ السياق المتاح ويقترح تجميعه إلى فئات واضحة. لا يغيّر أو يحذف بياناتك تلقائيًا.'),
            const SizedBox(height:12),FilledButton.icon(onPressed:_busy?null:_run,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome),label:const Text('نظّم الآن')),
          ]))),
          if(data!=null)...[
            const SizedBox(height:8),
            Card(child:ListTile(title:Text('الذكريات: ${data['memoryCount']??0}'),subtitle:Text('الأهداف النشطة: ${data['activeGoalCount']??0}'))),
            ...items.map((m)=>Card(child:ListTile(leading:const Icon(Icons.folder_outlined),title:Text(m['title']?.toString()??''),subtitle:Text('${m['category']??''}\n${m['reason']??''}'),isThreeLine:true))),
          ]else const Card(child:ListTile(title:Text('لا توجد خطة تنظيم حالية'),subtitle:Text('اضغط «نظّم الآن» لبناء اقتراحات من بياناتك الحالية.'))),
        ]);
      }));
  }
}