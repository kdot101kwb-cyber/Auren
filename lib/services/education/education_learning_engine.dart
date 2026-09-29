import 'package:cloud_firestore/cloud_firestore.dart';

class EducationLearningEngine {
  final FirebaseFirestore db;
  EducationLearningEngine({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String,dynamic>> _plans(String uid) =>
      db.collection('users').doc(uid).collection('learningPlans');

  Future<void> buildNextSteps({
    required String uid,
    required String planId,
    required String subject,
    required String level,
    required int minutesPerDay,
    List<String> focusAreas = const [],
  }) async {
    final plan = _plans(uid).doc(planId);
    final existing = await plan.collection('tasks').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final safeMinutes = minutesPerDay.clamp(5, 180);
    final tasks = <Map<String,dynamic>>[
      {'title':'مراجعة سريعة: $subject','type':'review','minutes':(safeMinutes * .15).round().clamp(5,30)},
      {'title':'درس جديد في $subject','type':'lesson','minutes':(safeMinutes * .45).round().clamp(5,90)},
      {'title':'تمرين تطبيقي','type':'practice','minutes':(safeMinutes * .30).round().clamp(5,60)},
      {'title':'اختبار قصير ومراجعة الأخطاء','type':'assessment','minutes':(safeMinutes * .10).round().clamp(5,30)},
    ];

    final batch = db.batch();
    final now = DateTime.now();
    for (var i=0; i<tasks.length; i++) {
      final t=tasks[i];
      final ref=plan.collection('tasks').doc();
      batch.set(ref,{
        ...t,
        'level':level,
        'focusAreas':focusAreas.take(10).toList(),
        'completed':false,
        'order':i,
        'dueAt':Timestamp.fromDate(now.add(Duration(days:i))),
        'createdAt':FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await plan.set({'engineVersion':1,'nextAction':'lesson','updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
  }

  Future<void> completeTask({
    required String uid,
    required String planId,
    required String taskId,
    required String subject,
  }) async {
    final ref=_plans(uid).doc(planId).collection('tasks').doc(taskId);
    await ref.update({'completed':true,'completedAt':FieldValue.serverTimestamp()});
    await _plans(uid).doc(planId).set({
      'lastCompletedTask':taskId,
      'nextAction':'continue',
      'lastActivityAt':FieldValue.serverTimestamp(),
      'updatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));

    await db.collection('users').doc(uid).collection('educationSkills').doc(subject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'),'_')).set({
      'name':subject,'level':levelFromTask(subject),'lastActivityAt':FieldValue.serverTimestamp(),
      'source':'learning_plan',
    },SetOptions(merge:true));
  }

  String levelFromTask(String subject) => 'in_progress';

  String buildNextLessonPrompt({required String subject, required String level, List<String> focusAreas=const []}) {
    final focus=focusAreas.isEmpty ? 'نقاط الضعف غير محددة بعد' : focusAreas.join('، ');
    return 'أنا أتعلم $subject. مستواي $level. نقاط التركيز: $focus. ابدأ بالدرس التالي فقط، بشرح بسيط، ثم سؤالين قصيرين للتأكد من الفهم. إذا أجبت بشكل صحيح، زد الصعوبة تدريجياً.';
  }
}
