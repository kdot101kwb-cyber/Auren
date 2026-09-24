import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent_scout.dart';
import '../../../services/talent/talent_scout_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentScoutsScreen extends StatelessWidget {
  const AurenTalentScoutsScreen({super.key});
  static const scouts=<Map<String,String>>[
    {'id':'opportunity','name':'Opportunity Scout','role':'opportunity','desc':'يبحث عن فرص عمل ومشاريع وشراكات مناسبة للمواهب.'},
    {'id':'market','name':'Market Scout','role':'market','desc':'يراقب المهارات المطلوبة واتجاهات السوق والفجوات.'},
    {'id':'talent','name':'Talent Scout','role':'talent','desc':'يكتشف المواهب والمهارات التي قد تناسب فرصاً أو فرقاً.'},
    {'id':'brand','name':'Talent Brand Scout','role':'brand','desc':'يبحث عن فرص ظهور وبناء ملف شخصي ومحتوى للمواهب.'},
    {'id':'learning','name':'Learning Scout','role':'learning','desc':'يكتشف مسارات تعلم ومشاريع عملية لسد فجوات المهارات.'},
  ];
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final repo=TalentScoutRepository();
    return Scaffold(appBar:AppBar(title:const Text('AUREN Talent Scouts')),body:StreamBuilder<List<AurenTalentScout>>(stream:repo.watch(uid),builder:(context,snapshot){
      final saved={for(final s in snapshot.data??const <AurenTalentScout>[])s.id:s};
      return ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('كشافو المواهب',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),const Text('مساعدون لاكتشاف الفرص والمهارات والظهور ومسارات التعلم. لا ينفذون إجراءات حساسة تلقائياً.')] ))),
        ...scouts.map((d){final enabled=saved[d['id']]?.enabled??false;return Card(child:SwitchListTile(value:enabled,onChanged:(v)=>repo.upsert(uid:uid,id:d['id']!,name:d['name']!,role:d['role']!,description:d['desc']!,enabled:v),title:Text(d['name']!),subtitle:Text(d['desc']!),secondary:Icon(enabled?Icons.radar:Icons.radar_outlined)));}),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'أنت نظام كشافين للمواهب في AUREN. حلّل مهاراتي وأهدافي واقترح فرصاً مناسبة، مهارات مطلوبة، طرق ظهور، ومسارات تعلم. رتّب النتائج حسب الصلة ولا تنفذ أي إجراء حساس دون موافقتي.'))),icon:const Icon(Icons.auto_awesome),label:const Text('شغّل تحليل الكشافين مع AUREN')),
      ]);
    }));
  }
}