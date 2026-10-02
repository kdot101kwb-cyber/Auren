import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/education.dart';

class EducationRepository {
  final FirebaseFirestore db;
  EducationRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenCourse>> watchCourses() => db.collection('courses').where('status', isEqualTo: 'published').limit(100).snapshots().map((s) => s.docs.map((d) => AurenCourse.fromMap(d.id, d.data())).toList());
  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> enroll(String uid, String courseId) => db.collection('users').doc(uid).collection('enrollments').doc(courseId).set({'courseId': courseId, 'completedLessons': 0, 'progress': 0, 'status':'active', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge:true));

  Future<void> completeLesson(String uid, AurenCourse course, int completed) async {
    if (completed < 0 || completed > course.lessonCount) throw ArgumentError('عدد الدروس غير صالح');
    final ref=db.collection('users').doc(uid).collection('enrollments').doc(course.id);
    final snap=await ref.get();
    if(!snap.exists) throw StateError('سجّل في الدورة أولاً');
    final progress=course.lessonCount==0?100:((completed/course.lessonCount)*100).round();
    await ref.update({'completedLessons':completed,'progress':progress,'status':progress>=100?'completed':'active','updatedAt':FieldValue.serverTimestamp()});
    if(progress>=100 && course.skills.isNotEmpty){
      final profile=db.collection('users').doc(uid).collection('profile_modes').doc('professional');
      final p=await profile.get();
      final data=p.data()??{};
      final current=data['skills'] is List ? List<String>.from(data['skills'].whereType<String>()) : <String>[];
      final merged={...current,...course.skills.map((e)=>e.trim().toLowerCase()).where((e)=>e.isNotEmpty)};
      await profile.set({
        'mode':'professional','headline':data['headline']?.toString()??'','bio':data['bio']?.toString()??'',
        'skills':merged.take(20).toList(),'interests':data['interests'] is List?List<String>.from(data['interests'].whereType<String>()):<String>[],
        'links':data['links'] is List?List<String>.from(data['links'].whereType<String>()):<String>[],
        'goals':data['goals'] is List?List<String>.from(data['goals'].whereType<String>()):<String>[],
        'languages':data['languages'] is List?List<String>.from(data['languages'].whereType<String>()):<String>[],
        'services':data['services'] is List?List<String>.from(data['services'].whereType<String>()):<String>[],
        'achievements':data['achievements'] is List?List<String>.from(data['achievements'].whereType<String>()):<String>[],
        'discoverable':data['discoverable'] != false,'showContact':data['showContact']==true,
        'updatedAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
    }
  }

  /// Updates enrollment progress only after validating the course and enrollment.
  /// Progress is derived from the published course's lesson count, never trusted
  /// from a caller-provided percentage.
  Future<void> setProgress(String uid, String courseId, int completed) async {
    if (uid.trim().isEmpty || courseId.trim().isEmpty || completed < 0) {
      throw ArgumentError('بيانات التقدم غير صالحة');
    }
    final courseRef = db.collection('courses').doc(courseId);
    final enrollmentRef = db.collection('users').doc(uid).collection('enrollments').doc(courseId);
    await db.runTransaction((tx) async {
      final courseSnap = await tx.get(courseRef);
      final enrollmentSnap = await tx.get(enrollmentRef);
      if (!courseSnap.exists || courseSnap.data()?['status'] != 'published') {
        throw StateError('الدورة غير متاحة');
      }
      if (!enrollmentSnap.exists) throw StateError('سجّل في الدورة أولاً');
      final lessonCount = (courseSnap.data()?['lessonCount'] as num?)?.toInt() ?? 0;
      if (lessonCount < 1 || completed > lessonCount) {
        throw ArgumentError('عدد الدروس غير صالح');
      }
      final progress = ((completed / lessonCount) * 100).round();
      tx.update(enrollmentRef, {
        'completedLessons': completed,
        'progress': progress,
        'status': progress >= 100 ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<AurenLearningProgress>> watchMyLearning(String uid) => db.collection('users').doc(uid).collection('enrollments').snapshots().map((s) => s.docs.map((d) => AurenLearningProgress(courseId: d.id, completedLessons: (d.data()['completedLessons'] as num?)?.toInt() ?? 0, enrolled: true)).toList());
  Future<void> toggleSaved(String uid, String courseId, bool saved) => saved ? db.collection('users').doc(uid).collection('savedCourses').doc(courseId).set({'courseId': courseId, 'createdAt': FieldValue.serverTimestamp()}) : db.collection('users').doc(uid).collection('savedCourses').doc(courseId).delete();
  Stream<List<AurenCourse>> watchSavedCourses(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().asyncMap((s) async { final out=<AurenCourse>[]; for(final d in s.docs){ final c=await db.collection('courses').doc(d.id).get(); if(c.exists && (c.data()?['status']=='published')) out.add(AurenCourse.fromMap(c.id,c.data()!)); } return out; });
}
