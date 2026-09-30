import 'package:cloud_firestore/cloud_firestore.dart';
import 'inclusive_learning_service.dart';
import 'adaptive_learning_service.dart';

enum LessonGameType { flashcards, matching, quiz, spelling, speedRound, dailyChallenge }

class LessonGameQuestion {
  final String prompt;
  final String answer;
  final List<String> options;
  const LessonGameQuestion({required this.prompt,required this.answer,this.options=const []});
  Map<String,dynamic> toMap()=>{'prompt':prompt,'answer':answer,'options':options};
}

class LessonGame {
  final String id,title,skill;
  final LessonGameType type;
  final int difficulty;
  final List<LessonGameQuestion> questions;
  const LessonGame({required this.id,required this.title,required this.skill,required this.type,required this.difficulty,required this.questions});
}

class LessonToGameEngine {
  const LessonToGameEngine();

  List<LessonGame> gamesFor(UniversalLesson lesson,{double mastery=.5}) {
    final difficulty=mastery<.4?1:(mastery<.75?2:3);
    final pairs=<LessonGameQuestion>[];
    for(final step in lesson.steps.take(8)){
      final clean=step.trim();
      if(clean.isEmpty) continue;
      final answer=clean.length>70?clean.substring(0,70):clean;
      pairs.add(LessonGameQuestion(prompt:lesson.title,answer:answer,options:[answer]));
    }
    final base=pairs.isEmpty
      ? [LessonGameQuestion(prompt:lesson.body.length>90?lesson.body.substring(0,90):lesson.body,answer:lesson.title)]
      : pairs;
    return [
      LessonGame(id:'${lesson.id}_flashcards',title:'بطاقات الدرس',skill:lesson.subject,type:LessonGameType.flashcards,difficulty:difficulty,questions:base),
      LessonGame(id:'${lesson.id}_matching',title:'مطابقة الدرس',skill:lesson.subject,type:LessonGameType.matching,difficulty:difficulty,questions:base.take(8).toList()),
      LessonGame(id:'${lesson.id}_quiz',title:'اختبار سريع',skill:lesson.subject,type:LessonGameType.quiz,difficulty:difficulty,questions:base.take(10).toList()),
      LessonGame(id:'${lesson.id}_spelling',title:'تحدي الكتابة',skill:lesson.subject,type:LessonGameType.spelling,difficulty:difficulty,questions:base.take(8).toList()),
      LessonGame(id:'${lesson.id}_speed',title:'جولة السرعة',skill:lesson.subject,type:LessonGameType.speedRound,difficulty:difficulty,questions:base.take(12).toList()),
      LessonGame(id:'${lesson.id}_daily',title:'تحدي اليوم',skill:lesson.subject,type:LessonGameType.dailyChallenge,difficulty:difficulty,questions:base.take(10).toList()),
    ];
  }
}

class LessonGameProgressService {
  final FirebaseFirestore db;
  LessonGameProgressService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _plays(String uid)=>
      db.collection('users').doc(uid).collection('education').doc('game_history').collection('lesson_plays');

  Future<void> recordResult(String uid,{required LessonGame game,required bool correct,required int xp,int attempts=1}) async {
    final mastery=AdaptiveLearningService.nextMastery(currentMastery:.5,correct:correct,attempts:attempts);
    await _plays(uid).add({
      'lessonGameId':game.id,'lessonId':game.id.split('_').first,'gameType':game.type.name,
      'difficulty':game.difficulty,'correct':correct,'xp':xp,'attempts':attempts,
      'masteryAfter':mastery,'createdAt':FieldValue.serverTimestamp(),
    });
  }
}
