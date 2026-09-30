import 'package:cloud_firestore/cloud_firestore.dart';

enum LearningGameType { flashcards, matching, listening, spelling, quiz, speedRound, dailyChallenge }

class LearningGame {
  final String id;
  final String title;
  final LearningGameType type;
  final String skill;
  final int difficulty;
  final int questions;
  const LearningGame({required this.id,required this.title,required this.type,required this.skill,required this.difficulty,required this.questions});
}

class EducationGameEngine {
  List<LearningGame> gamesFor({required double mastery, String skill='General'}) {
    final d = mastery < .4 ? 1 : mastery < .75 ? 2 : 3;
    return [
      LearningGame(id:'flashcards',title:'Flashcards',type:LearningGameType.flashcards,skill:skill,difficulty:d,questions:8),
      LearningGame(id:'matching',title:'Match It',type:LearningGameType.matching,skill:skill,difficulty:d,questions:8),
      LearningGame(id:'listening',title:'Listen & Choose',type:LearningGameType.listening,skill:skill,difficulty:d,questions:6),
      LearningGame(id:'spelling',title:'Spell It',type:LearningGameType.spelling,skill:skill,difficulty:d,questions:8),
      LearningGame(id:'quiz',title:'Quick Quiz',type:LearningGameType.quiz,skill:skill,difficulty:d,questions:10),
      LearningGame(id:'speed',title:'Speed Round',type:LearningGameType.speedRound,skill:skill,difficulty:d,questions:12),
      LearningGame(id:'daily',title:'Daily Challenge',type:LearningGameType.dailyChallenge,skill:skill,difficulty:d,questions:10),
    ];
  }

  Future<void> recordResult({required String uid, required String gameId, required bool correct, required int xp}) =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('education')
      .doc('game_history').collection('plays').add({
        'gameId':gameId,'correct':correct,'xp':xp,'createdAt':FieldValue.serverTimestamp(),
      });
}
