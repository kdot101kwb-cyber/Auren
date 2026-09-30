import 'package:cloud_firestore/cloud_firestore.dart';

enum LearningDifficulty { beginner, standard, advanced }
enum ExplanationMode { simple, standard, deep }

class AdaptiveLearnerState {
  final String level;
  final double mastery;
  final double pace;
  final int repetition;
  final List<String> weakSkills;
  final ExplanationMode explanationMode;
  const AdaptiveLearnerState({
    required this.level, required this.mastery, required this.pace,
    required this.repetition, required this.weakSkills, required this.explanationMode,
  });
  Map<String,dynamic> toMap()=>{
    'level':level,'mastery':mastery,'pace':pace,'repetition':repetition,
    'weakSkills':weakSkills,'explanationMode':explanationMode.name,
    'updatedAt':FieldValue.serverTimestamp(),
  };
}

class AdaptiveLearningService {
  final FirebaseFirestore _db;
  AdaptiveLearningService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;

  Future<void> saveState(String uid, AdaptiveLearnerState state) async {
    await _db.collection('users').doc(uid).collection('education')
      .doc('adaptive_learning').set(state.toMap(),SetOptions(merge:true));
  }

  Stream<Map<String,dynamic>?> watchState(String uid) =>
    _db.collection('users').doc(uid).collection('education').doc('adaptive_learning').snapshots()
      .map((s)=>s.data());

  LearningDifficulty difficultyFor(double mastery) {
    if(mastery < .4) return LearningDifficulty.beginner;
    if(mastery < .75) return LearningDifficulty.standard;
    return LearningDifficulty.advanced;
  }

  ExplanationMode explanationFor({required double mastery, required bool needsSimplification}) {
    if(needsSimplification || mastery < .4) return ExplanationMode.simple;
    if(mastery > .85) return ExplanationMode.deep;
    return ExplanationMode.standard;
  }

  int repetitionsFor(double mastery) => mastery < .4 ? 3 : mastery < .75 ? 2 : 1;

  double nextMastery({required double mastery, required bool correct, required int attempts}) {
    final step = correct ? .08 : -.06;
    final penalty = attempts > 2 ? .02 : 0;
    return (mastery + step - penalty).clamp(0,1);
  }
}
