import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityLessonPlan {
  final bool audioDescription;
  final bool captions;
  final bool simplifiedText;
  final bool largeText;
  final bool highContrast;
  final bool reducedMotion;
  final bool voiceNavigation;
  final double pace;

  const AccessibilityLessonPlan({
    this.audioDescription=false,
    this.captions=true,
    this.simplifiedText=false,
    this.largeText=false,
    this.highContrast=false,
    this.reducedMotion=false,
    this.voiceNavigation=false,
    this.pace=1.0,
  });

  Map<String,dynamic> toMap()=>{'audioDescription':audioDescription,'captions':captions,'simplifiedText':simplifiedText,'largeText':largeText,'highContrast':highContrast,'reducedMotion':reducedMotion,'voiceNavigation':voiceNavigation,'pace':pace};
}

class SpeechPracticeResult {
  final String prompt;
  final String transcript;
  final double pronunciationScore;
  final List<String> feedback;
  final DateTime createdAt;

  const SpeechPracticeResult({required this.prompt,required this.transcript,required this.pronunciationScore,required this.feedback,required this.createdAt});

  Map<String,dynamic> toMap()=>{'prompt':prompt,'transcript':transcript,'pronunciationScore':pronunciationScore,'feedback':feedback,'createdAt':Timestamp.fromDate(createdAt)};
}

class AccessibilityLessonPlanner {
  const AccessibilityLessonPlanner();

  AccessibilityLessonPlan plan({
    required bool visualImpairment,
    required bool hearingImpairment,
    required bool learningDifficulty,
    required bool motorDifficulty,
    double pace=1.0,
  })=>AccessibilityLessonPlan(
    audioDescription: visualImpairment,
    captions: true,
    simplifiedText: learningDifficulty,
    largeText: visualImpairment,
    highContrast: visualImpairment,
    reducedMotion: motorDifficulty,
    voiceNavigation: motorDifficulty,
    pace: pace.clamp(.5,1.5),
  );
}

class SpeechPracticeService {
  final FirebaseFirestore db;
  SpeechPracticeService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;

  Future<void> saveResult(String uid, SpeechPracticeResult result) async {
    await db.collection('users').doc(uid).collection('education').doc('speech').collection('practice').add(result.toMap());
  }
}
