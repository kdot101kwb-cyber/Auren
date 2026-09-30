import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/education_gamification_service.dart';

class EducationGamificationScreen extends StatelessWidget {
  const EducationGamificationScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    if(uid==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    final service=EducationGamificationService();
    return Scaffold(appBar:AppBar(title:const Text('تعلم + إنجازات')),body:StreamBuilder<EducationGamificationState>(
      stream:service.watch(uid),builder:(context,s){
        final x=s.data??const EducationGamificationState();
        return ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('المستوى ${x.level}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),LinearProgressIndicator(value:x.progress),
            const SizedBox(height:8),Text('${x.levelXp}/100 XP للمستوى التالي • إجمالي ${x.xp} XP'),
            const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_stat(Icons.local_fire_department,'${x.streak}','Streak'),_stat(Icons.task_alt,'${x.completedMissions}','أنشطة'),_stat(Icons.workspace_premium,'${x.badges.length}','Badges')])
          ]))),
          const SizedBox(height:12),const Text('المهمة اليومية',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          Card(child:ListTile(leading:const Icon(Icons.today),title:const Text('أكمل نشاطاً تعليمياً اليوم'),subtitle:Text(x.lastActiveDay==_today()?'مكتملة اليوم':'غير مكتملة'),trailing:const Text('+10 XP'))),
          const SizedBox(height:12),const Text('الإنجازات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          ...EducationGamificationService.badges.map((b)=>Card(child:ListTile(leading:Icon(x.badges.contains(b.id)?Icons.workspace_premium:Icons.lock_outline),title:Text(b.title),subtitle:Text(b.description),trailing:Text('+${b.xp} XP'))))
        ]);
      }));
  }
  static String _today(){final d=DateTime.now().toUtc();return d.year.toString().padLeft(4,'0')+'-'+d.month.toString().padLeft(2,'0')+'-'+d.day.toString().padLeft(2,'0');}
  static Widget _stat(IconData i,String v,String l)=>Column(children:[Icon(i),Text(v,style:const TextStyle(fontWeight:FontWeight.bold)),Text(l)]);
}