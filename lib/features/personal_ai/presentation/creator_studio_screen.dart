import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/business/business_repository.dart';
import '../../../services/business/business_analytics_service.dart';
import '../../../core/models/business.dart';
import '../../../services/personal_ai/creator_studio_service.dart';

class AurenCreatorStudioScreen extends StatefulWidget {
  const AurenCreatorStudioScreen({super.key});
  @override State<AurenCreatorStudioScreen> createState()=>_AurenCreatorStudioScreenState();
}
class _AurenCreatorStudioScreenState extends State<AurenCreatorStudioScreen>{
  final _title=TextEditingController(),_caption=TextEditingController(),_audience=TextEditingController();
  String _format='Short'; bool _saving=false;
  @override void dispose(){_title.dispose();_caption.dispose();_audience.dispose();super.dispose();}
  Future<void> _save(String uid) async {
    if(_title.text.trim().isEmpty)return;
    setState(()=>_saving=true);
    await CreatorStudioService().saveDraft(uid:uid,title:_title.text,caption:_caption.text,format:_format,audience:_audience.text);
    if(!mounted)return; setState(()=>_saving=false); _title.clear();_caption.clear();_audience.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ المسودة')));
  }
  @override Widget build(BuildContext context){
    final uid=FirebaseAurenAuthService().currentUserId;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول لاستخدام Creator Studio.')));
    return Scaffold(appBar:AppBar(title:const Text('Creator Studio')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('من الفكرة إلى مسودة جاهزة للمراجعة. النشر والرفع الفعلي للوسائط يجي في طبقة Media القادمة.'))),
      TextField(controller:_title,decoration:const InputDecoration(labelText:'عنوان / فكرة')),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:_format,items:const ['Short','Post','Story','Series'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>_format=v??'Short')),
      const SizedBox(height:10),
      TextField(controller:_audience,decoration:const InputDecoration(labelText:'الجمهور')),
      const SizedBox(height:10),
      TextField(controller:_caption,maxLines:4,decoration:const InputDecoration(labelText:'الكابشن / النص')),
      const SizedBox(height:14),
      FilledButton.icon(onPressed:_saving?null:()=>_save(uid),icon:const Icon(Icons.save_outlined),label:Text(_saving?'جاري الحفظ…':'حفظ المسودة')),
      const SizedBox(height:18),
      StreamBuilder<List<AurenCreatorDraft>>(stream:CreatorStudioService().watch(uid),builder:(context,s){
        final drafts=s.data??const <AurenCreatorDraft>[];
        if(drafts.isEmpty)return const Card(child:ListTile(title:Text('ما عندك مسودات لسه.')));
        return Column(children:drafts.map((d)=>Card(child:ExpansionTile(title:Text(d.title),subtitle:Text(d.format+' • '+d.status),children:[
          if(d.caption.isNotEmpty)Padding(padding:const EdgeInsets.all(16),child:Text(d.caption)),
          ...d.ideas.map((x)=>ListTile(leading:const Icon(Icons.lightbulb_outline),title:Text(x))),
          ...d.steps.map((x)=>ListTile(leading:const Icon(Icons.checklist_outlined),title:Text(x))),
          ButtonBar(children:[
            TextButton(onPressed:()=>CreatorStudioService().updateStatus(uid,d.id,'ready'),child:const Text('Ready')),
            TextButton(onPressed:()=>CreatorStudioService().delete(uid,d.id),child:const Text('Delete')),
          ])
        ])).toList());
      }),
    ]));
  }
}
