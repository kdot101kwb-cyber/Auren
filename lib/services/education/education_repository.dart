import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/models/education.dart';
import 'education_gamification_service.dart';

class EducationRepository {
  final FirebaseFirestore db;
  final EducationGamificationService gamification;
  EducationRepository({FirebaseFirestore? firestore, EducationGamificationService? gamificationService})
      : db = firestore ?? FirebaseFirestore.instance,
        gamification = gamificationService ?? EducationGamificationService();

  Stream<List<AurenCourse>> watchCourses() => db.collection('courses').where('status', isEqualTo: 'published').limit(100).snapshots().map((s) => s.docs.map((d) => AurenCourse.fromMap(d.id, d.data())).toList());
  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> enroll(String uid, String courseId) => db.collection('users').doc(uid).collection('enrollments').doc(courseId).set({'courseId': courseId, 'completedLessons': 0, 'progress': 0, 'status':'active', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge:true));

  Future<void> completeLesson(String uid, AurenCourse course, int completed) async {
    if (completed < 0 || completed > course.lessonCount) throw ArgumentError('عدد الدروس غير صالح');
    final result = await CloudFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('completeAurenEducationLesson')
        .call({'courseId': course.id, 'completed': completed});
    final response = Map<String, dynamic>.from(result.data as Map);
    final progress = (response['progress'] as num?)?.toInt() ?? 0;

    if(progress>=100 && course.skills.isNotEmpty){
      final profile=db.collection('users').doc(uid).collection('profile_modes').doc('professional');
      final p=await profile.get();
      final data=p.data()??{};
      final current=data['skills'] is List ? List<String>.from(data['skills'].whereType<String>()) : <String>[];
      final merged={...current,...course.skills.map((e)=>e.trim().toLowerCase()).where((e)=>e.isNotEmpty)};
      await profile.set({'mode':'professional','headline':data['headline']?.toString()??'','bio':data['bio']?.toString()??'','skills':merged.take(20).toList(),'interests':data['interests'] is List?List<String>.from(data['interests'].whereType<String>()):<String>[],'links':data['links'] is List?List<String>.from(data['links'].whereType<String>()):<String>[],'goals':data['goals'] is List?List<String>.from(data['goals'].whereType<String>()):<String>[],'languages':data['languages'] is List?List<String>.from(data['languages'].whereType<String>()):<String>[],'services':data['services'] is List?List<String>.from(data['services'].whereType<String>()):<String>[],'achievements':data['achievements'] is List?List<String>.from(data['achievements'].whereType<String>()):<String>[],'discoverable':data['discoverable'] != false,'showContact':data['showContact']==true,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
    }
  }

  Future<void> setProgress(String uid, String courseId, int completed) async {
    await CloudFunctions.instanceFor(region: 'us-central1').httpsCallable('completeAurenEducationLesson').call({'courseId': courseId, 'completed': completed});
  }
  Stream<List<AurenLearningProgress>> watchMyLearning(String uid) => db.collection('users').doc(uid).collection('enrollments').snapshots().map((s) => s.docs.map((d) => AurenLearningProgress(courseId: d.id, completedLessons: (d.data()['completedLessons'] as num?)?.toInt() ?? 0, enrolled: true)).toList());
  Future<void> toggleSaved(String uid, String courseId, bool saved) => saved ? db.collection('users').doc(uid).collection('savedCourses').doc(courseId).set({'courseId': courseId, 'createdAt': FieldValue.serverTimestamp()}) : db.collection('users').doc(uid).collection('savedCourses').doc(courseId).delete();
  Stream<List<AurenCourse>> watchSavedCourses(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().asyncMap((s) async { final out=<AurenCourse>[]; for(final d in s.docs){ final c=await db.collection('courses').doc(d.id).get(); if(c.exists && (c.data()?['status']=='published')) out.add(AurenCourse.fromMap(c.id,c.data()!)); } return out; });
}
