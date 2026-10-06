import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/auren_production_service.dart';
import '../models/auren_production_models.dart';

class AurenProductionStudioScreen extends StatefulWidget {
  const AurenProductionStudioScreen({super.key});
  @override State<AurenProductionStudioScreen> createState()=>_AurenProductionStudioScreenState();
}
class _AurenProductionStudioScreenState extends State<AurenProductionStudioScreen> {
  final _service=AurenProductionService.instance;
  final _title=TextEditingController();
  AurenProductionType _type=AurenProductionType.film;
  AurenVideoEngine _engine=AurenVideoEngine.skyReelsV3;
  double _minutes=90;
  @override void dispose(){_title.dispose();super.dispose();}
  Future<void> _create() async {
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سجّل الدخول أولاً.')));return;}
    await _service.createJob(uid:uid,title:_title.text,type:_type,targetMinutes:_minutes.round(),engine:_engine);
    if(mounted){_title.clear();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة الإنتاج إلى الطابور.')));}
  }
  String _status(AurenProductionStatus s)=>switch(s){AurenProductionStatus.queued=>'Queued',AurenProductionStatus.planning=>'Planning',AurenProductionStatus.generating=>'Generating',AurenProductionStatus.assembling=>'Assembling',AurenProductionStatus.review=>'AI review',AurenProductionStatus.completed=>'Completed',AurenProductionStatus.failed=>'Failed',AurenProductionStatus.cancelled=>'Cancelled'};
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar:AppBar(title:const Text('AUREN Production Studio')),body:uid==null?const Center(child:Text('سجّل الدخول لاستخدام الاستوديو.')):StreamBuilder<List<AurenProductionJob>>(
      stream:_service.watchJobs(uid),builder:(context,snapshot){final jobs=snapshot.data??const <AurenProductionJob>[];
      return ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Create production',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),
          TextField(controller:_title,decoration:const InputDecoration(labelText:'Title',hintText:'My first AUREN film')),const SizedBox(height:12),
          DropdownButtonFormField<AurenProductionType>(initialValue:_type,decoration:const InputDecoration(labelText:'Type'),items:AurenProductionType.values.map((v)=>DropdownMenuItem(value:v,child:Text(v.label))).toList(),onChanged:(v)=>setState(()=>_type=v??_type)),const SizedBox(height:12),
          DropdownButtonFormField<AurenVideoEngine>(initialValue:_engine,decoration:const InputDecoration(labelText:'Video engine'),items:AurenVideoEngine.values.map((v)=>DropdownMenuItem(value:v,child:Text(v.label))).toList(),onChanged:(v)=>setState(()=>_engine=v??_engine)),const SizedBox(height:8),
          Text('Target length: '+_minutes.round().toString()+' min'),Slider(value:_minutes,min:_type==AurenProductionType.short?1:10,max:_type==AurenProductionType.seriesEpisode?120:240,divisions:_type==AurenProductionType.short?9:23,onChanged:(v)=>setState(()=>_minutes=v)),
          SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_create,icon:const Icon(Icons.movie_creation_outlined),label:const Text('Start production'))),
        ]))),
        const SizedBox(height:16),const Text('Production History',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),
        if(jobs.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد أعمال في الطابور حتى الآن.'))) else ...jobs.map((job)=>Card(child:ListTile(
          leading:CircleAvatar(child:Icon(job.type==AurenProductionType.film?Icons.movie:Icons.video_library)),
          title:Text(job.title),subtitle:Text(job.type.label+' • '+job.targetMinutes.toString()+' min • '+job.engine.label+'\n'+_status(job.status)+' • '+job.progress.toString()+'%'),isThreeLine:true,
          trailing:PopupMenuButton<String>(onSelected:(action)async{if(action=='cancel')await _service.requestCancel(uid,job.id);if(action=='retry')await _service.retry(uid,job);},itemBuilder:(_)=>[
            if(job.status!=AurenProductionStatus.completed&&job.status!=AurenProductionStatus.cancelled)const PopupMenuItem(value:'cancel',child:Text('Cancel')),
            if(job.status==AurenProductionStatus.failed||job.status==AurenProductionStatus.cancelled)const PopupMenuItem(value:'retry',child:Text('Retry')),
          ]),
        ))),
      ]);},
    ));
  }
}