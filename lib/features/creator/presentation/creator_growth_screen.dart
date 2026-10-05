import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/creator/creator_growth_repository.dart';

class AurenCreatorGrowthScreen extends StatefulWidget {
  const AurenCreatorGrowthScreen({super.key});
  @override State<AurenCreatorGrowthScreen> createState() => _AurenCreatorGrowthScreenState();
}
class _AurenCreatorGrowthScreenState extends State<AurenCreatorGrowthScreen> {
  final _repo = AurenCreatorGrowthRepository();
  final _title = TextEditingController();
  String _format = 'post';
  DateTime? _scheduledAt;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  @override void dispose(){_title.dispose();super.dispose();}
  Future<void> _addPlan() async {
    final uid=_uid;
    if(uid==null||_title.text.trim().isEmpty)return;
    try{await _repo.addPlan(uid:uid,title:_title.text.trim(),format:_format,scheduledAt:_scheduledAt);_title.clear();if(mounted)setState(()=>_scheduledAt=null);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الحفظ: $e')));}
  }
  void _openAi([AurenCreatorPlanItem? plan]){
    final prompt=plan==null?'أنا Creator داخل AUREN. ساعدني في تطوير فكرة محتوى وخطة نشر.':'طوّر لي هذه الخطة كـ Creator داخل AUREN: ${plan.title}. الصيغة: ${plan.format}.';
    Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt)));
  }
  @override Widget build(BuildContext context){
    final uid=_uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('Sign in required')));
    return Scaffold(appBar:AppBar(title:const Text('Creator Growth Engine')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('Creator AI Assistant'),subtitle:const Text('طوّر أفكارك وخططك مع AUREN AI.'),onTap:_openAi)),
      const SizedBox(height:12),
      FutureBuilder<AurenCreatorGrowthSummary>(future:_repo.summary(uid),builder:(context,snap){final x=snap.data;return Wrap(spacing:8,runSpacing:8,children:[_stat('المحتوى',x?.posts??0),_stat('الإعجابات',x?.likes??0),_stat('التعليقات',x?.comments??0),_stat('مجدول',x?.scheduled??0),_stat('Engagement',x?.engagementRate.toStringAsFixed(1)??'0.0')]);}),
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        const Align(alignment:AlignmentDirectional.centerStart,child:Text('Content Planner',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
        const SizedBox(height:10),
        TextField(controller:_title,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'شنو المحتوى الجاي؟')),
        const SizedBox(height:8),
        DropdownButtonFormField<String>(value:_format,items:const[DropdownMenuItem(value:'post',child:Text('Post')),DropdownMenuItem(value:'short',child:Text('Short')),DropdownMenuItem(value:'video',child:Text('Video')),DropdownMenuItem(value:'live',child:Text('Live')),DropdownMenuItem(value:'audio',child:Text('Audio'))],onChanged:(v)=>setState(()=>_format=v??'post'),decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'Format')),
        const SizedBox(height:8),
        OutlinedButton(onPressed:()async{final now=DateTime.now();final picked=await showDatePicker(context:context,firstDate:now,lastDate:now.add(const Duration(days:365)),initialDate:now);if(picked!=null)setState(()=>_scheduledAt=picked);},child:Text(_scheduledAt==null?'اختيار موعد':'تم اختيار موعد')),
        const SizedBox(height:8),
        FilledButton(onPressed:_addPlan,child:const Text('إضافة للخطة')),
      ]))),
      const SizedBox(height:16),
      StreamBuilder<List<AurenCreatorPlanItem>>(stream:_repo.watchPlan(uid),builder:(context,snap){final plans=snap.data??const <AurenCreatorPlanItem>[];if(plans.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('لا توجد خطط محتوى بعد.')));return Column(children:plans.map((p)=>Card(child:ListTile(title:Text(p.title),subtitle:Text('${p.format} • ${p.status}'),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='ai')_openAi(p);if(v=='delete')await _repo.deletePlan(uid,p.id);},itemBuilder:(_)=>const[PopupMenuItem(value:'ai',child:Text('مساعدة AI')),PopupMenuItem(value:'delete',child:Text('حذف'))])))).toList());}),
    ]));
  }
  Widget _stat(String label,dynamic value)=>SizedBox(width:120,child:Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Text(value.toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text(label)]))));
}