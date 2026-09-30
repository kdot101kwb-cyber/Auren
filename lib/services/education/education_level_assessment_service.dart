import 'package:cloud_firestore/cloud_firestore.dart';
class EducationAssessmentQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String skill;
  final String level;
  const EducationAssessmentQuestion({required this.id,required this.prompt,required this.options,required this.correctIndex,required this.skill,required this.level});
}

class EducationAssessmentResult {
  final int score;
  final int total;
  final String level;
  final List<String> strengths;
  final List<String> focusAreas;
  const EducationAssessmentResult({required this.score,required this.total,required this.level,required this.strengths,required this.focusAreas});
}

class EducationLevelAssessmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveResult({required String uid, required String subject, required EducationAssessmentResult result}) async {
    await _db.collection('users').doc(uid).collection('educationAssessments').add({
      'subject': subject, 'level': result.level, 'score': result.score, 'total': result.total,
      'strengths': result.strengths, 'focusAreas': result.focusAreas, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static const questions = <EducationAssessmentQuestion>[
    EducationAssessmentQuestion(id:'q1',prompt:'Which sentence is correct?',options:['She go to school.','She goes to school.','She going school.','She gone school.'],correctIndex:1,skill:'Grammar',level:'Beginner'),
    EducationAssessmentQuestion(id:'q2',prompt:'Choose the best meaning of “improve”.',options:['To make better','To make smaller','To stop','To forget'],correctIndex:0,skill:'Vocabulary',level:'Elementary'),
    EducationAssessmentQuestion(id:'q3',prompt:'If I had more time, I ___ another course.',options:['take','will take','would take','took'],correctIndex:2,skill:'Grammar',level:'Intermediate'),
    EducationAssessmentQuestion(id:'q4',prompt:'Choose the best connector: “The task was difficult; ___, we finished it.”',options:['however','because','unless','before'],correctIndex:0,skill:'Reading',level:'Upper Intermediate'),
    EducationAssessmentQuestion(id:'q5',prompt:'Which sentence expresses a hypothetical past result?',options:['I study every day.','I was studying yesterday.','If I had studied, I would have passed.','I will study tomorrow.'],correctIndex:2,skill:'Advanced Grammar',level:'Advanced'),
  ];

  EducationAssessmentResult evaluate(List<int> answers) {
    var score = 0;
    final strengths = <String>[];
    final focus = <String>[];
    for (var i = 0; i < questions.length; i++) {
      final answer = i < answers.length ? answers[i] : -1;
      if (answer == questions[i].correctIndex) { score++; strengths.add(questions[i].skill); }
      else { focus.add(questions[i].skill); }
    }
    final ratio = questions.isEmpty ? 0.0 : score / questions.length;
    final level = ratio >= .9 ? 'Advanced' : ratio >= .7 ? 'Upper Intermediate' : ratio >= .5 ? 'Intermediate' : ratio >= .3 ? 'Elementary' : 'Beginner';
    return EducationAssessmentResult(score:score,total:questions.length,level:level,strengths:strengths.toSet().toList(),focusAreas:focus.toSet().toList());
  }

  String buildTutorPrompt({required String subject, required EducationAssessmentResult result}) {
    return 'أنا أتعلم $subject. نتيجة اختبار تحديد المستوى: ${result.level} (${result.score}/${result.total}). نقاط القوة: ${result.strengths.join(', ')}. أحتاج التركيز على: ${result.focusAreas.join(', ')}. ابنِ لي أول درس مناسب لمستواي، ثم تمريناً قصيراً، ولا تنتقل للمستوى التالي إلا بعد التأكد من الفهم.';
  }
}
