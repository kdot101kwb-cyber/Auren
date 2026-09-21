import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/education.dart';

class EducationRepository {
  final FirebaseFirestore db;
  EducationRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenCourse>> watchCourses() => db.collection('courses').where('status', isEqualTo: 'published').limit(100).snapshots().map((s) => s.docs.map((d) => AurenCourse.fromMap(d.id, d.data())).toList());
  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> enroll(String uid, String courseId) => db.collection('users').doc(uid).collection('enrollments').doc(courseId).set({'courseId': courseId, 'completedLessons': 0, 'createdAt': FieldValue.serverTimestamp()});
  Future<void> setProgress(String uid, String courseId, int completed) => db.collection('users').doc(uid).collection('enrollments').doc(courseId).update({'completedLessons': completed, 'updatedAt': FieldValue.serverTimestamp()});
  Stream<List<AurenLearningProgress>> watchMyLearning(String uid) => db.collection('users').doc(uid).collection('enrollments').snapshots().map((s) => s.docs.map((d) => AurenLearningProgress(courseId: d.id, completedLessons: (d.data()['completedLessons'] as num?)?.toInt() ?? 0, enrolled: true)).toList());
  Future<void> toggleSaved(String uid, String courseId, bool saved) => saved ? db.collection('users').doc(uid).collection('savedCourses').doc(courseId).set({'courseId': courseId, 'createdAt': FieldValue.serverTimestamp()}) : db.collection('users').doc(uid).collection('savedCourses').doc(courseId).delete();
  Stream<List<AurenCourse>> watchSavedCourses(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().asyncMap((s) async { final out=<AurenCourse>[]; for(final d in s.docs){ final c=await db.collection('courses').doc(d.id).get(); if(c.exists && (c.data()?['status']=='published')) out.add(AurenCourse.fromMap(c.id,c.data()!)); } return out; });
}
