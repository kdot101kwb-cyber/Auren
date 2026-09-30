import 'package:flutter/material.dart';
import '../../../services/education/inclusive_learning_service.dart';
import 'lesson_games_screen.dart';

class UniversalLessonScreen extends StatelessWidget{
 final UniversalLesson lesson; final InclusiveLearningProfile profile;
 const UniversalLessonScreen({super.key,required this.lesson,this.profile=const InclusiveLearningProfile()});
 @override Widget build(BuildContext context){final engine=const UniversalLessonEngine();final formats=engine.formatsFor(profile);return Scaffold(appBar:AppBar(title:Text(lesson.title)),body:ListView(padding:const EdgeInsets.all(16),children:[
 Text(lesson.subject,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:10),
 Card(child:Padding(padding:const EdgeInsets.all(18),child:Text(engine.accessibleInstruction(lesson.body,profile),style:Theme.of(context).textTheme.bodyLarge))),
 const SizedBox(height:14),const Text('طرق عرض هذا الدرس',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Wrap(spacing:8,children:formats.map((f)=>Chip(label:Text(_label(f)))).toList()),
 const SizedBox(height:18),ElevatedButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>LessonGamesScreen(lesson:lesson))),icon:const Icon(Icons.sports_esports),label:const Text('حوّل الدرس إلى لعبة')),const SizedBox(height:18),const Text('الخطوات',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 ...lesson.steps.asMap().entries.map((e)=>Card(child:ListTile(leading:CircleAvatar(child:Text('${e.key+1}')),title:Text(e.value)))),
 if(lesson.audioUrl!=null)const ListTile(leading:Icon(Icons.volume_up),title:Text('نسخة صوتية متاحة')),
 if(lesson.videoUrl!=null)const ListTile(leading:Icon(Icons.video_library),title:Text('نسخة فيديو متاحة')),
 if(lesson.signLanguageUrl!=null)const ListTile(leading:Icon(Icons.sign_language),title:Text('نسخة بلغة الإشارة متاحة')),
 ]));}
 static String _label(LearningFormat f){switch(f){case LearningFormat.text:return 'نص';case LearningFormat.audio:return 'صوت';case LearningFormat.video:return 'فيديو';case LearningFormat.simplifiedVisual:return 'صور مبسطة';case LearningFormat.interactiveSteps:return 'خطوات تفاعلية';case LearningFormat.captions:return 'ترجمة نصية';case LearningFormat.signLanguage:return 'لغة الإشارة';}}
}
