import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent_scout.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/opportunity.dart';
import '../../../services/talent/talent_scout_service.dart';
import 'talent_scout_results_screen.dart';
import '../../../services/talent/talent_scout_repository.dart';

class AurenTalentScoutsScreen extends StatelessWidget {
  const AurenTalentScoutsScreen({super.key});
  static const scouts=<Map<String,String>>[
    {'id':'opportunity','name':'Opportunity Scout','role':'opportunity','desc':'يبحث عن فرص عمل ومشاريع وشراكات مناسبة للمواهب.'},
    {'id':'market','name':'Market Scout','role':'market','desc':'يراقب المهارات المطلوبة واتجاهات السوق والفجوات.'},
    {'id':'talent','name':'Talent Scout','role':'talent','desc':'يكتشف المواهب والمهارات التي قد تناسب فرصاً أو فرقاً.'},
    {'id':'brand','name':'Talent Brand Scout','role':'brand','desc':'يبحث عن فرص ظهور وبناء ملف شخصي ومحتوى للمواهب.'},
    {'id':'learning','name':'Learning Scout','role':'learning','desc':'يكتشف مسارات تعلم ومشاريع عملية لسد فجوات المهارات.'},
    {'id':'sports','name':'Sports Scout','role':'sports','desc':'يطابق الرياضة والتخصص ومستوى الأداء مع فرق ومدربين وفرص رياضية.'},
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
        FilledButton.icon(onPressed:() async { final enabled=saved.values.where((s)=>s.enabled).toList(); if(enabled.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فعّل كشافاً واحداً على الأقل أولاً.')));return;} final talentSnap=await FirebaseFirestore.instance.collection('talents').where('ownerId',isEqualTo:uid).limit(1).get(); if(talentSnap.docs.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أنشئ ملف موهبة أولاً حتى يستطيع الكشافون المطابقة.')));return;} final talent=AurenTalent.fromMap(talentSnap.docs.first.id,talentSnap.docs.first.data()); final oppSnap=await FirebaseFirestore.instance.collection('opportunities').where('status',isEqualTo:'open').limit(100).get(); final opportunities=oppSnap.docs.map((d)=>AurenOpportunity.fromMap(d.id,d.data())).toList(); await TalentScoutService().runNow(uid:uid,scouts:enabled,talent:talent,opportunities:opportunities); if(context.mounted) Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenTalentScoutResultsScreen(talent:talent,scouts:enabled))); },icon:const Icon(Icons.radar),label:const Text('شغّل الكشافين الآن')),
      ]);
    }));
  }
}