import 'package:cloud_firestore/cloud_firestore.dart';

class AurenLesson {
  final String id;
  final String title;
  final String content;
  final int order;
  final int durationMinutes;
  final String videoUrl;

  const AurenLesson({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.durationMinutes,
    required this.videoUrl,
  });

  factory AurenLesson.fromMap(String id, Map<String, dynamic> d) => AurenLesson(
        id: id,
        title: d['title']?.toString() ?? '',
        content: d['content']?.toString() ?? '',
        order: (d['order'] as num?)?.toInt() ?? 0,
        durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 0,
        videoUrl: d['videoUrl']?.toString() ?? '',
      );
}

class AurenCourse {
  final String id,title,description,category,teacherId;
  final List<String> skills;
  final int lessonCount;
  final DateTime? createdAt;
  const AurenCourse({required this.id,required this.title,required this.description,required this.category,required this.teacherId,required this.skills,required this.lessonCount,this.createdAt});
  factory AurenCourse.fromMap(String id,Map<String,dynamic> d)=>AurenCourse(
    id:id,
    title:d['title']?.toString() ?? '',
    description:d['description']?.toString() ?? '',
    category:d['category']?.toString() ?? 'General',
    teacherId:d['teacherId']?.toString() ?? '',
    skills:d['skills'] is List ? (d['skills'] as List).whereType<String>().take(20).toList() : const [],
    lessonCount:(d['lessonCount'] as num?)?.toInt() ?? 0,
    createdAt:(d['createdAt'] as Timestamp?)?.toDate(),
  );
}

class AurenLearningProgress {
  final String courseId;
  final int completedLessons;
  final bool enrolled;
  const AurenLearningProgress({required this.courseId,required this.completedLessons,required this.enrolled});
}