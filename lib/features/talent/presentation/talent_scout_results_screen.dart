import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/talent_scout.dart';
import '../../../core/models/talent_scout_finding.dart';
import '../../../services/talent/talent_scout_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentScoutResultsScreen extends StatelessWidget {
  final AurenTalent talent;
  final List<AurenTalentScout> scouts;
  const AurenTalentScoutResultsScreen({super.key,required this.talent,required this.scouts});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final service=TalentScoutService();
    return Scaffold(appBar:AppBar(title:const Text('Scout Results')),body:StreamBuilder<List<AurenTalentScoutFinding>>(
      stream:service.watchFindings(uid),builder:(context,snapshot){
        if(snapshot.hasError)return Center(child:Text('تعذر تحميل النتائج: ${snapshot.error}'));
        final items=snapshot.data??const <AurenTalentScoutFinding>[];
        if(items.isEmpty)return const Center(child:Text('لا توجد نتائج بعد. شغّل الكشافين الآن.'));
        return ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,i){
          final f=items[i];
          return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(f.title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold))),Text('${f.score}%')]),
            const SizedBox(height:8),Text(f.description),
            if(f.matchedSkills.isNotEmpty)...[const SizedBox(height:8),Text('مطابق: ${f.matchedSkills.join(' • ')}')],
            if(f.missingSkills.isNotEmpty)...[const SizedBox(height:4),Text('ناقص: ${f.missingSkills.join(' • ')}')],
            const SizedBox(height:10),
            FilledButton.icon(icon:const Icon(Icons.auto_awesome),label:const Text('حلل مع AUREN'),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'حلل نتيجة كشاف المواهب: ${f.title}. ${f.description}. المهارات المتطابقة: ${f.matchedSkills.join(', ')}. المهارات الناقصة: ${f.missingSkills.join(', ')}. اقترح الخطوة التالية ولا تنفذ إجراءً حساساً دون موافقتي.')))),
          ])));
        });
      }),
    );
  }
}
