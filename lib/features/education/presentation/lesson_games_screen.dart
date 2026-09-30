import 'package:flutter/material.dart';
import '../../../services/education/inclusive_learning_service.dart';
import '../../../services/education/lesson_to_game_service.dart';

class LessonGamesScreen extends StatefulWidget{
 final UniversalLesson lesson;
 const LessonGamesScreen({super.key,required this.lesson});
 @override State<LessonGamesScreen> createState()=>_LessonGamesScreenState();
}
class _LessonGamesScreenState extends State<LessonGamesScreen>{
 int mastery=50;
 @override Widget build(BuildContext context){
  final games=const LessonToGameEngine().gamesFor(widget.lesson,mastery:mastery/100);
  return Scaffold(
   appBar:AppBar(title:const Text('الدرس → لعب')),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    Text(widget.lesson.title,style:Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height:8),
    Text('مستوى الإتقان: $mastery%'),
    Slider(value:mastery.toDouble(),min:0,max:100,divisions:20,onChanged:(v)=>setState(()=>mastery=v.round())),
    const Text('الألعاب تتكيف مع مستوى الإتقان تلقائياً.'),
    const SizedBox(height:12),
    ...games.map((g)=>Card(child:ListTile(
      leading:CircleAvatar(child:Text('${g.difficulty}')),
      title:Text(g.title),
      subtitle:Text('${g.questions.length} أسئلة • ${_type(g.type)}'),
      trailing:const Icon(Icons.play_arrow),
      onTap:()=>_play(g),
    )))
   ])
  );
 }
 String _type(LessonGameType t)=>switch(t){
  LessonGameType.flashcards=>'بطاقات',
  LessonGameType.matching=>'مطابقة',
  LessonGameType.quiz=>'اختبار',
  LessonGameType.spelling=>'كتابة',
  LessonGameType.speedRound=>'سرعة',
  LessonGameType.dailyChallenge=>'تحدي يومي',
 };
 void _play(LessonGame game){
  final q=game.questions.first;
  showDialog(context:context,builder:(_)=>AlertDialog(
   title:Text(game.title),
   content:Text('السؤال:\n${q.prompt}\n\nالإجابة النموذجية:\n${q.answer}'),
   actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),ElevatedButton(onPressed:()=>Navigator.pop(context),child:const Text('أكملت'))],
  ));
 }
}
