import 'package:cloud_firestore/cloud_firestore.dart';

class EducationCourse {
  final String id, title, description, level;
  final List<String> skills;
  final int lessons;
  final bool published;
  const EducationCourse({required this.id, required this.title, required this.description, required this.level, required this.skills, required this.lessons, required this.published});
  factory EducationCourse.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return EducationCourse(id: doc.id, title: d['title'] as String? ?? 'دورة AUREN', description: d['description'] as String? ?? '', level: d['level'] as String? ?? 'beginner', skills: List<String>.from(d['skills'] as List? ?? const []), lessons: (d['lessons'] as num?)?.toInt() ?? 0, published: d['published'] == true);
  }
}
class EducationAiService {
  final FirebaseFirestore _db;
  EducationAiService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  Stream<List<EducationCourse>> watchPublishedCourses() => _db.collection('education_courses').where('published', isEqualTo: true).snapshots().map((s) => s.docs.map(EducationCourse.fromDoc).toList());
  Stream<QuerySnapshot<Map<String, dynamic>>> watchEnrollments(String uid) => _db.collection('users').doc(uid).collection('education_enrollments').orderBy('updatedAt', descending: true).snapshots();
  Future<void> enroll({required String uid, required EducationCourse course}) async {
    final now = Timestamp.now();
    await _db.collection('users').doc(uid).collection('education_enrollments').doc(course.id).set({'courseId': course.id, 'title': course.title, 'progress': 0, 'completedLessons': <String>[], 'status': 'active', 'createdAt': now, 'updatedAt': now});
  }
  Future<void> updateProgress({required String uid, required String courseId, required int progress, required List<String> completedLessons}) async {
    final p = progress.clamp(0, 100);
    await _db.collection('users').doc(uid).collection('education_enrollments').doc(courseId).update({'progress': p, 'completedLessons': completedLessons.take(100).toList(), 'status': p >= 100 ? 'completed' : 'active', 'updatedAt': Timestamp.now()});
  }
}