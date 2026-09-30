import 'package:cloud_firestore/cloud_firestore.dart';

enum LanguageGameMode { vocabulary, matching, listening, spelling, quiz }

class LanguageWord {
  final String id;
  final String prompt;
  final String answer;
  final String? hint;
  const LanguageWord({required this.id, required this.prompt, required this.answer, this.hint});
}

class LanguageGameSession {
  final String language;
  final LanguageGameMode mode;
  final int xp;
  final int correct;
  final int total;
  final int streak;
  const LanguageGameSession({required this.language, required this.mode, required this.xp, required this.correct, required this.total, required this.streak});
  double get accuracy => total == 0 ? 0 : correct / total;
  Map<String, dynamic> toMap() => {
    'language': language, 'mode': mode.name, 'xp': xp, 'correct': correct,
    'total': total, 'streak': streak, 'updatedAt': FieldValue.serverTimestamp(),
  };
}

class LanguageLearningGameService {
  static const languages = <String>[
    'Arabic','English','French','Spanish','German','Italian','Portuguese','Turkish',
    'Chinese','Japanese','Korean','Russian','Hindi','Urdu','Swahili','Amharic',
    'Dutch','Greek','Hebrew','Indonesian','Malay','Thai','Vietnamese','Persian',
    'Bengali','Tamil','Telugu','Polish','Ukrainian','Romanian','Czech','Hungarian',
    'Danish','Norwegian','Finnish','Filipino','Somali',
  ];

  static const starterWords = <LanguageWord>[
    LanguageWord(id:'hello', prompt:'Hello', answer:'مرحبا', hint:'A common greeting'),
    LanguageWord(id:'thanks', prompt:'Thank you', answer:'شكراً', hint:'Used to show gratitude'),
    LanguageWord(id:'water', prompt:'Water', answer:'ماء'),
    LanguageWord(id:'book', prompt:'Book', answer:'كتاب'),
    LanguageWord(id:'friend', prompt:'Friend', answer:'صديق'),
  ];

  final FirebaseFirestore _db;
  LanguageLearningGameService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> watchProgress(String uid, String language) =>
    _db.collection('users').doc(uid).collection('education').doc('language_progress')
      .collection('languages').doc(language.toLowerCase()).snapshots().map((s) => s.data());

  Future<void> saveSession(String uid, LanguageGameSession session) async {
    final ref = _db.collection('users').doc(uid).collection('education').doc('language_progress')
      .collection('languages').doc(session.language.toLowerCase());
    await ref.set(session.toMap(), SetOptions(merge:true));
  }

  int xpForAnswer({required bool correct, required int streak}) =>
    correct ? 10 + (streak.clamp(0,5) * 2) : 0;
}
