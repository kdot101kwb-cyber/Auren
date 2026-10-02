import 'package:cloud_firestore/cloud_firestore.dart';

/// Compatibility facade for older callers.
/// The canonical Education implementation is EducationRepository.
@Deprecated('Use EducationRepository from education_repository.dart.')
class AurenEducationService {
  final FirebaseFirestore db;
  AurenEducationService({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  /// Legacy collection access is intentionally disabled.
  /// Use the canonical `courses` / `enrollments` schema instead.
  Never watchCourses({String category = 'All'}) =>
      throw StateError('استخدم EducationRepository ونظام courses الجديد.');

  Never watchEnrollment(String uid, String courseId) =>
      throw StateError('استخدم EducationRepository ونظام enrollments الجديد.');

  Never enroll({required String uid, required Object course}) =>
      throw StateError('استخدم EducationRepository ونظام enrollments الجديد.');

  Never completeLesson({
    required String uid,
    required Object course,
    required int lessonIndex,
  }) =>
      throw StateError('استخدم EducationRepository ونظام الدروس الجديد.');

  Never watchMyLearning(String uid) =>
      throw StateError('استخدم EducationRepository ونظام enrollments الجديد.');
}
