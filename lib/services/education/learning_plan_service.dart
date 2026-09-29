import 'package:cloud_firestore/cloud_firestore.dart';

class LearningPlanService {
  final FirebaseFirestore db;
  LearningPlanService({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _plans(String uid) =>
      db.collection('users').doc(uid).collection('learningPlans');

  Future<void> savePlan({
    required String uid,
    required String title,
    required String track,
    required String subject,
    required String level,
    required int minutesPerDay,
    required List<String> weeklyGoals,
  }) {
    if (title.trim().isEmpty || subject.trim().isEmpty) {
      throw ArgumentError('العنوان والمادة مطلوبان');
    }
    if (minutesPerDay < 5 || minutesPerDay > 480) {
      throw ArgumentError('الوقت اليومي غير صالح');
    }
    return _plans(uid).add({
      'title': title.trim(),
      'track': track,
      'subject': subject.trim(),
      'level': level,
      'minutesPerDay': minutesPerDay,
      'weeklyGoals': weeklyGoals.take(20).toList(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchPlans(String uid) =>
      _plans(uid).orderBy('updatedAt', descending: true).limit(30).snapshots().map(
        (s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      );

  Future<void> markPlanDone(String uid, String planId) =>
      _plans(uid).doc(planId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> saveStudyTask({
    required String uid,
    required String planId,
    required String title,
    required String type,
    required DateTime dueAt,
  }) =>
      _plans(uid).doc(planId).collection('tasks').add({
        'title': title.trim(),
        'type': type,
        'dueAt': Timestamp.fromDate(dueAt),
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Map<String, dynamic>>> watchTasks(String uid, String planId) =>
      _plans(uid).doc(planId).collection('tasks').orderBy('dueAt').limit(100).snapshots().map(
        (s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      );

  Future<void> completeTask(String uid, String planId, String taskId) =>
      _plans(uid).doc(planId).collection('tasks').doc(taskId).update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
}
