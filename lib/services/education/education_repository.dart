import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/education.dart';

class EducationRepository {
  /// Converts completed lessons to the canonical 0..100 progress value.
  /// Kept deterministic so UI, repository and tests use the same rule.
  static int progressFor(int completedLessons, int lessonCount) {
    if (lessonCount < 1 || completedLessons < 0 || completedLessons > lessonCount) {
      throw ArgumentError('عدد الدروس غير صالح');
    }
    return ((completedLessons / lessonCount) * 100).round();
  }

  final FirebaseFirestore db;
  EducationRepository({FirebaseFirestore? firestore}) : db = firestore ?? FirebaseFirestore.instance;

  Stream<List<AurenCourse>> watchCourses() => db.collection('courses').where('status', isEqualTo: 'published').limit(100).snapshots().map((s) => s.docs.map((d) => AurenCourse.fromMap(d.id, d.data())).toList());
  Stream<List<AurenLesson>> watchLessons(String courseId) {
    if (courseId.trim().isEmpty) return const Stream<List<AurenLesson>>.empty();
    return db.collection('courses').doc(courseId).collection('lessons')
        .orderBy('order')
        .limit(500)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AurenLesson.fromMap(d.id, d.data()))
            .where((lesson) => lesson.title.trim().isNotEmpty && lesson.order >= 0)
            .toList());
  }

  Stream<Set<String>> watchSavedIds(String uid) => db.collection('users').doc(uid).collection('savedCourses').snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  Future<void> enroll(String uid, String courseId) async {
    if (uid.trim().isEmpty || courseId.trim().isEmpty) {
      throw ArgumentError('بيانات التسجيل غير صالحة');
    }

    final courseRef = db.collection('courses').doc(courseId);
    final enrollmentRef = db.collection('users').doc(uid).collection('enrollments').doc(courseId);

    await db.runTransaction((tx) async {
      final courseSnap = await tx.get(courseRef);
      if (!courseSnap.exists || courseSnap.data()?['status'] != 'published') {
        throw StateError('الدورة غير متاحة');
      }

      final existing = await tx.get(enrollmentRef);
      if (existing.exists) {
        // Idempotent enrollment: never reset an existing learner's progress.
        return;
      }

      tx.set(enrollmentRef, {
        'courseId': courseId,
        'completedLessons': 0,
        'progress': 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> completeLesson(String uid, AurenCourse course, int completed) async {
    if (uid.trim().isEmpty || uid.trim().length > 128 || course.id.trim().isEmpty || course.id.trim().length > 128 || completed < 0) {
      throw ArgumentError('بيانات التقدم غير صالحة');
    }

    // Never trust lesson count/skills supplied by the UI. Re-read the
    // canonical published course before changing learner progress.
    final canonicalSnap = await db.collection('courses').doc(course.id).get();
    if (!canonicalSnap.exists || canonicalSnap.data()?['status'] != 'published') {
      throw StateError('الدورة غير متاحة');
    }
    final canonical = AurenCourse.fromMap(course.id, canonicalSnap.data()!);
    if (canonical.lessonCount < 1 || completed > canonical.lessonCount) {
      throw ArgumentError('عدد الدروس غير صالح');
    }

    final enrollmentRef = db.collection('users').doc(uid).collection('enrollments').doc(canonical.id);
    final profileRef = db.collection('users').doc(uid).collection('profile_modes').doc('professional');

    await db.runTransaction((tx) async {
      final enrollmentSnap = await tx.get(enrollmentRef);
      if (!enrollmentSnap.exists) throw StateError('سجّل في الدورة أولاً');
      final previousCompleted = (enrollmentSnap.data()?['completedLessons'] as num?)?.toInt() ?? 0;
      if (completed < previousCompleted) {
        throw StateError('لا يمكن تقليل تقدمك في الدورة');
      }

      final progress = progressFor(completed, canonical.lessonCount);
      tx.update(enrollmentRef, {
        'completedLessons': completed,
        'progress': progress,
        'status': progress >= 100 ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Keep the learned-skill update in the same transaction so concurrent
      // profile changes cannot be overwritten by a stale read/write cycle.
      if (completed >= canonical.lessonCount && canonical.skills.isNotEmpty) {
        final profileSnap = await tx.get(profileRef);
        final data = profileSnap.data() ?? <String, dynamic>{};
        final current = data['skills'] is List
            ? List<String>.from((data['skills'] as List).whereType<String>())
            : <String>[];
        final merged = <String>{
          ...current,
          ...canonical.skills.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty),
        };

        tx.set(profileRef, {
          'mode': 'professional',
          'headline': data['headline']?.toString() ?? '',
          'bio': data['bio']?.toString() ?? '',
          'skills': merged.take(20).toList(),
          'interests': data['interests'] is List ? List<String>.from((data['interests'] as List).whereType<String>()) : <String>[],
          'links': data['links'] is List ? List<String>.from((data['links'] as List).whereType<String>()) : <String>[],
          'goals': data['goals'] is List ? List<String>.from((data['goals'] as List).whereType<String>()) : <String>[],
          'languages': data['languages'] is List ? List<String>.from((data['languages'] as List).whereType<String>()) : <String>[],
          'services': data['services'] is List ? List<String>.from((data['services'] as List).whereType<String>()) : <String>[],
          'achievements': data['achievements'] is List ? List<String>.from((data['achievements'] as List).whereType<String>()) : <String>[],
          'discoverable': data['discoverable'] != false,
          'showContact': data['showContact'] == true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
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
    final profileRef = db.collection('users').doc(uid).collection('profile_modes').doc('professional');

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

      final progress = progressFor(completed, lessonCount);
      tx.update(enrollmentRef, {
        'completedLessons': completed,
        'progress': progress,
        'status': progress >= 100 ? 'completed' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (completed >= lessonCount) {
        final profileSnap = await tx.get(profileRef);
        final data = profileSnap.data() ?? <String, dynamic>{};
        final current = data['skills'] is List
            ? List<String>.from((data['skills'] as List).whereType<String>())
            : <String>[];
        final rawSkills = courseSnap.data()?['skills'];
        final courseSkills = rawSkills is List
            ? rawSkills.whereType<String>()
                .map((e) => e.trim().toLowerCase())
                .where((e) => e.isNotEmpty)
            : const <String>[];
        final merged = <String>{...current, ...courseSkills};
        tx.set(profileRef, {
          'mode': 'professional',
          'skills': merged.take(20).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Stream<List<AurenLearningProgress>> watchMyLearning(String uid) =>
      db.collection('users').doc(uid).collection('enrollments').snapshots().map(
        (s) => s.docs.map((d) {
          final raw = (d.data()['completedLessons'] as num?)?.toInt() ?? 0;
          return AurenLearningProgress(
            courseId: d.id,
            completedLessons: raw < 0 ? 0 : raw,
            enrolled: true,
          );
        }).toList(),
      );
  Future<void> toggleSaved(String uid, String courseId, bool saved) async {
    if (uid.trim().isEmpty || courseId.trim().isEmpty) {
      throw ArgumentError('بيانات الحفظ غير صالحة');
    }

    if (saved) {
      final courseSnap = await db.collection('courses').doc(courseId).get();
      if (!courseSnap.exists || courseSnap.data()?['status'] != 'published') {
        throw StateError('الدورة غير متاحة');
      }
    }

    final ref = db.collection('users').doc(uid).collection('savedCourses').doc(courseId);
    if (saved) {
      await ref.set({
        'courseId': courseId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }
  Stream<List<AurenCourse>> watchSavedCourses(String uid) =>
      db.collection('users').doc(uid).collection('savedCourses').snapshots().asyncMap(
        (s) async {
          if (s.docs.isEmpty) return <AurenCourse>[];

          final docs = await Future.wait(
            s.docs.map((savedDoc) => db.collection('courses').doc(savedDoc.id).get()),
          );
          final out = <AurenCourse>[];
          for (final courseDoc in docs) {
            final data = courseDoc.data();
            if (courseDoc.exists && data != null && data['status'] == 'published') {
              out.add(AurenCourse.fromMap(courseDoc.id, data));
            }
          }
          out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          return out;
        },
      );
}
