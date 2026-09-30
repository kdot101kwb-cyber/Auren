import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/adaptive_learning_service.dart';
import '../../../services/education/education_game_engine.dart';

class AdaptiveLearningPlayScreen extends StatefulWidget {
  const AdaptiveLearningPlayScreen({super.key});
  @override State<AdaptiveLearningPlayScreen> createState()=>_AdaptiveLearningPlayScreenState();
}
class _AdaptiveLearningPlayScreenState extends State<AdaptiveLearningPlayScreen>{
  final adaptive=AdaptiveLearningService();
  double mastery=.5;
  @override Widget build(BuildContext context){
    final games=EducationGameEngine().gamesFor(mastery:mastery,skill:'Language');
    final mode=adaptive.explanationFor(mastery:mastery,needsSimplification:false);
    return Scaffold(appBar:AppBar(title:const Text('Adaptive Learning + Play')),body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('تعلم يتغير مع مستواك',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),Text('Mastery: ${(mastery*100).round()}% • Explanation: ${mode.name}'),
      Slider(value:mastery,min:0,max:1,onChanged:(v)=>setState(()=>mastery=v)),
      const SizedBox(height:8),const Text('الألعاب المقترحة لك'),
      ...games.map((g)=>Card(child:ListTile(leading:const Icon(Icons.sports_esports),title:Text(g.title),subtitle:Text('${g.questions} questions • Level ${g.difficulty}'),trailing:const Icon(Icons.play_arrow),onTap:() async {
        final uid=FirebaseAuth.instance.currentUser?.uid;
        if(uid!=null) await EducationGameEngine().recordResult(uid:uid,gameId:g.id,correct:true,xp:10);
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل الجولة — +10 XP')));
      }))),
      const SizedBox(height:12),const Text('النظام يرفع أو يخفض الصعوبة حسب الأداء، ويزيد التكرار عند ضعف الإتقان.'),
    ]));
  }
}
