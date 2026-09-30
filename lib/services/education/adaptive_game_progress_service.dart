import 'package:cloud_firestore/cloud_firestore.dart';
import 'adaptive_learning_service.dart';
import 'lesson_to_game_service.dart';
import 'education_gamification_service.dart';

class AdaptiveGameProgressService {
  final FirebaseFirestore db;
  AdaptiveGameProgressService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  DocumentReference<Map<String,dynamic>> _state(String uid,String lessonId)=>db.collection('users').doc(uid).collection('education').doc('adaptive_games').collection('lessons').doc(lessonId);
  Stream<Map<String,dynamic>?> watchLesson(String uid,String lessonId)=>_state(uid,lessonId).snapshots().map((s)=>s.data());
  Future<double> recordAnswer(String uid,{required String lessonId,required LessonGame game,required bool correct,required int attempts}) async {
    final ref=_state(uid,lessonId), snap=await ref.get();
    final current=(snap.data()?['mastery'] as num?)?.toDouble() ?? .5;
    final next=AdaptiveLearningService().nextMastery(mastery:current,correct:correct,attempts:attempts);
    final service=AdaptiveLearningService();
    await ref.set({'lessonId':lessonId,'mastery':next,'difficulty':service.difficultyFor(next).name,'explanationMode':service.explanationFor(mastery:next,needsSimplification:false).name,'repetitions':service.repetitionsFor(next),'lastGame':game.type.name,'lastCorrect':correct,'attempts':attempts,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
    await db.collection('users').doc(uid).collection('education').doc('game_history').collection('lesson_plays').add({'lessonId':lessonId,'lessonGameId':game.id,'gameType':game.type.name,'correct':correct,'attempts':attempts,'masteryAfter':next,'difficulty':game.difficulty,'createdAt':FieldValue.serverTimestamp()});
    await EducationGamificationService(firestore:db).awardActivity(uid,xp:correct?10:3);
    return next;
  }
}
