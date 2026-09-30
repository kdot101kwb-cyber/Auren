import 'package:cloud_firestore/cloud_firestore.dart';

class PlacementQuestion {
  final String id, prompt;
  final List<String> options;
  final int correctIndex;
  const PlacementQuestion({required this.id, required this.prompt, required this.options, required this.correctIndex});
}

class PlacementResult {
  final String level;
  final int score, total;
  final double percentage;
  const PlacementResult({required this.level, required this.score, required this.total, required this.percentage});
}

class PlacementService {
  final FirebaseFirestore db;
  PlacementService({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  static const questions = <PlacementQuestion>[
    PlacementQuestion(id: 'q1', prompt: 'Which sentence is correct?', options: ['She go to school.', 'She goes to school.', 'She going school.'], correctIndex: 1),
    PlacementQuestion(id: 'q2', prompt: 'Choose the best word: “I have ___ this book before.”', options: ['read', 'reads', 'reading'], correctIndex: 0),
    PlacementQuestion(id: 'q3', prompt: 'Choose the best connector: “I studied hard, ___ I passed.”', options: ['because', 'so', 'although'], correctIndex: 1),
    PlacementQuestion(id: 'q4', prompt: 'Choose the most natural sentence.', options: ['If I had known, I would have called.', 'If I know, I would called.', 'If I knew, I will have called.'], correctIndex: 0),
  ];

  PlacementResult evaluate(List<int?> answers) {
    var score = 0;
    for (var i = 0; i < questions.length && i < answers.length; i++) {
      if (answers[i] == questions[i].correctIndex) score++;
    }
    final percentage = questions.isEmpty ? 0.0 : score / questions.length;
    final level = percentage >= .85 ? 'Advanced' : percentage >= .65 ? 'Intermediate' : percentage >= .4 ? 'Elementary' : 'Beginner';
    return PlacementResult(level: level, score: score, total: questions.length, percentage: percentage);
  }

  Future<void> saveResult({required String uid, required String subject, required PlacementResult result}) {
    return db.collection('users').doc(uid).collection('placementResults').add({
      'subject': subject.trim(),
      'level': result.level,
      'score': result.score,
      'total': result.total,
      'percentage': result.percentage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
