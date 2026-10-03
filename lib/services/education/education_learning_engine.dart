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
    final cleanUid=uid.trim(), cleanPlanId=planId.trim(), cleanSubject=subject.trim(), cleanLevel=level.trim();
    final cleanFocus=focusAreas.map((e)=>e.trim()).where((e)=>e.isNotEmpty).take(10).toList();
    if (cleanUid.isEmpty || cleanUid.length>128 || cleanPlanId.isEmpty || cleanPlanId.length>128 ||
        cleanSubject.isEmpty || cleanSubject.length>120 || cleanLevel.isEmpty || cleanLevel.length>40 ||
        focusAreas.any((e)=>e.trim().length>80)) {
      throw ArgumentError('بيانات خطة التعلم غير صالحة');
    }
    final plan = _plans(cleanUid).doc(cleanPlanId);
    final existing = await plan.collection('tasks').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final safeMinutes = minutesPerDay.clamp(5, 180);
    final tasks = <Map<String,dynamic>>[
      {'title':'مراجعة سريعة: $cleanSubject','type':'review','minutes':(safeMinutes * .15).round().clamp(5,30)},
      {'title':'درس جديد في $cleanSubject','type':'lesson','minutes':(safeMinutes * .45).round().clamp(5,90)},
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
        'level':cleanLevel,
        'focusAreas':cleanFocus,
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
    final cleanUid=uid.trim(), cleanPlanId=planId.trim(), cleanTaskId=taskId.trim(), cleanSubject=subject.trim();
    if (cleanUid.isEmpty || cleanUid.length>128 || cleanPlanId.isEmpty || cleanPlanId.length>128 ||
        cleanTaskId.isEmpty || cleanTaskId.length>128 || cleanSubject.isEmpty || cleanSubject.length>120) {
      throw ArgumentError('بيانات المهمة غير صالحة');
    }
    final ref=_plans(cleanUid).doc(cleanPlanId).collection('tasks').doc(cleanTaskId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['completed'] == true) return;
    await ref.update({'completed':true,'completedAt':FieldValue.serverTimestamp()});
    await _plans(cleanUid).doc(cleanPlanId).set({
      'lastCompletedTask':cleanTaskId,
      'nextAction':'continue',
      'lastActivityAt':FieldValue.serverTimestamp(),
      'updatedAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));

    await db.collection('users').doc(cleanUid).collection('educationSkills').doc(cleanSubject.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'),'_').substring(0, 120)).set({
      'name':cleanSubject,'level':levelFromTask(cleanSubject),'lastActivityAt':FieldValue.serverTimestamp(),
      'source':'learning_plan',
    },SetOptions(merge:true));
  }

  String levelFromTask(String subject) => 'in_progress';

  String buildNextLessonPrompt({required String subject, required String level, List<String> focusAreas=const []}) {
    final focus=focusAreas.isEmpty ? 'نقاط الضعف غير محددة بعد' : focusAreas.join('، ');
    return 'أنا أتعلم $subject. مستواي $level. نقاط التركيز: $focus. ابدأ بالدرس التالي فقط، بشرح بسيط، ثم سؤالين قصيرين للتأكد من الفهم. إذا أجبت بشكل صحيح، زد الصعوبة تدريجياً.';
  }
}
