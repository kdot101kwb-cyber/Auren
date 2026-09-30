import 'package:flutter/material.dart';
import '../../../services/education/inclusive_learning_service.dart';
import '../../../services/education/lesson_to_game_service.dart';
import '../../../services/education/adaptive_game_progress_service.dart';

class LessonGamesScreen extends StatefulWidget{
 final UniversalLesson lesson;
 const LessonGamesScreen({super.key,required this.lesson});
 @override State<LessonGamesScreen> createState()=>_LessonGamesScreenState();
}
class _LessonGamesScreenState extends State<LessonGamesScreen>{
 double mastery=.5; int index=0, attempts=0;
 @override Widget build(BuildContext context){
  final games=const LessonToGameEngine().gamesFor(widget.lesson,mastery:mastery);
  return Scaffold(
   appBar:AppBar(title:const Text('الدرس → لعب')),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    Text(widget.lesson.title,style:Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height:8),
    LinearProgressIndicator(value:mastery), Text('الإتقان: ${(mastery*100).round()}%'),
    const SizedBox(height:12),
    const Text('الألعاب تتكيف مع مستوى الإتقان تلقائياً.'),
    const SizedBox(height:12),
    ...games.map((g)=>Card(child:ListTile(
      leading:CircleAvatar(child:Text('${g.difficulty}')),
      title:Text(g.title),
      subtitle:Text('${g.questions.length} أسئلة • ${_type(g.type)}'),
      trailing:const Icon(Icons.play_arrow),
      onTap:()=>_play(g),
    )))   ])
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
  final q=game.questions[index%game.questions.length];
  showDialog(context:context,builder:(_)=>AlertDialog(
    title:Text(game.title),content:Text('السؤال:\n${q.prompt}\n\nالإجابة النموذجية:\n${q.answer}'),
    actions:[
      TextButton(onPressed:(){Navigator.pop(context);_answer(false,game);},child:const Text('خطأ')),
      ElevatedButton(onPressed:(){Navigator.pop(context);_answer(true,game);},child:const Text('صحيح')),
    ],
  ));
 }
 Future<void> _answer(bool correct,LessonGame game) async{
  attempts++;
  final next=AdaptiveLearningService().nextMastery(mastery:mastery,correct:correct,attempts:attempts);
  if(widget.uid!=null){await AdaptiveGameProgressService().recordAnswer(widget.uid!,lessonId:widget.lesson.id,game:game,correct:correct,attempts:attempts);}
  if(!mounted)return;
  setState((){mastery=next;index++;attempts=0;});
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(correct?'أحسنت! المستوى يتقدم.':'سنكرر المحتوى بطريقة أسهل.')));
 }
}