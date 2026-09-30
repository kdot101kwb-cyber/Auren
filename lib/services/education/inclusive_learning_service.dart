import 'package:cloud_firestore/cloud_firestore.dart';

enum LearningFormat { text, audio, video, simplifiedVisual, interactiveSteps, captions, signLanguage }
enum AccessibilityNeed { none, lowVision, blind, hardOfHearing, deaf, speech, auditory, learningDifficulty, motor }

class InclusiveLearningProfile {
  final AccessibilityNeed need;
  final bool reducedMotion, largeText, highContrast, voiceControl, captions, audioDescription;
  final String language;
  final double pace;
  const InclusiveLearningProfile({this.need=AccessibilityNeed.none,this.reducedMotion=false,this.largeText=false,this.highContrast=false,this.voiceControl=false,this.captions=true,this.audioDescription=false,this.language='العربية',this.pace=1.0});

  Map<String,dynamic> toMap()=>{'need':need.name,'reducedMotion':reducedMotion,'largeText':largeText,'highContrast':highContrast,'voiceControl':voiceControl,'captions':captions,'audioDescription':audioDescription,'language':language,'pace':pace,'updatedAt':FieldValue.serverTimestamp()};
  static InclusiveLearningProfile fromMap(Map<String,dynamic> d){
    final raw=d['need'] as String? ?? AccessibilityNeed.none.name;
    final n=AccessibilityNeed.values.firstWhere((x)=>x.name==raw,orElse:()=>AccessibilityNeed.none);
    return InclusiveLearningProfile(need:n,reducedMotion:d['reducedMotion']==true,largeText:d['largeText']==true,highContrast:d['highContrast']==true,voiceControl:d['voiceControl']==true,captions:d['captions']!=false,audioDescription:d['audioDescription']==true,language:d['language'] as String? ?? 'العربية',pace:(d['pace'] as num?)?.toDouble() ?? 1.0);
  }
}

class UniversalLesson {
  final String id,title,subject,body,language;
  final List<String> steps;
  final String? audioUrl,videoUrl,signLanguageUrl;
  const UniversalLesson({required this.id,required this.title,required this.subject,required this.body,required this.steps,this.audioUrl,this.videoUrl,this.signLanguageUrl,this.language='العربية'});
  Map<String,dynamic> toMap()=>{'title':title,'subject':subject,'body':body,'steps':steps.take(50).toList(),'audioUrl':audioUrl,'videoUrl':videoUrl,'signLanguageUrl':signLanguageUrl,'language':language};
}

class UniversalLessonEngine {
  const UniversalLessonEngine();
  List<LearningFormat> formatsFor(InclusiveLearningProfile p){
    switch(p.need){
      case AccessibilityNeed.blind:return [LearningFormat.audio,LearningFormat.text,LearningFormat.interactiveSteps];
      case AccessibilityNeed.lowVision:return [LearningFormat.audio,LearningFormat.text,LearningFormat.simplifiedVisual];
      case AccessibilityNeed.deaf:
      case AccessibilityNeed.hardOfHearing:return [LearningFormat.captions,LearningFormat.text,LearningFormat.signLanguage];
      case AccessibilityNeed.learningDifficulty:return [LearningFormat.simplifiedVisual,LearningFormat.interactiveSteps,LearningFormat.audio];
      case AccessibilityNeed.motor:return [LearningFormat.text,LearningFormat.audio,LearningFormat.interactiveSteps];
      case AccessibilityNeed.speech:
      case AccessibilityNeed.auditory:
      case AccessibilityNeed.none:return [LearningFormat.text,LearningFormat.audio,LearningFormat.video,LearningFormat.interactiveSteps];
    }
  }
  String accessibleInstruction(String body,InclusiveLearningProfile p)=>p.need==AccessibilityNeed.learningDifficulty?body.replaceAll(RegExp(r'\\s+'),' ').trim():body;
}

class InclusiveLearningService {
  final FirebaseFirestore db;
  InclusiveLearningService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  DocumentReference<Map<String,dynamic>> _profile(String uid)=>db.collection('users').doc(uid).collection('education').doc('inclusiveProfile');
  Future<void> saveProfile(String uid,InclusiveLearningProfile p)=>_profile(uid).set(p.toMap(),SetOptions(merge:true));
  Stream<InclusiveLearningProfile?> watchProfile(String uid)=>_profile(uid).snapshots().map((d)=>d.exists?InclusiveLearningProfile.fromMap(d.data()??{}):null);
}
