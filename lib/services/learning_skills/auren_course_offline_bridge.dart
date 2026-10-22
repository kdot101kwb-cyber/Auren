import 'auren_offline_learning.dart';

/// Connects published education lessons to the bounded, text-only offline library.
class AurenCourseOfflineBridge {
  const AurenCourseOfflineBridge(this.offline);

  final AurenOfflineLearning offline;

  String offlineIdFor(String courseId, String lessonId) {
    final id = 'course-${courseId.trim()}-lesson-${lessonId.trim()}';
    if (courseId.trim().isEmpty ||
        lessonId.trim().isEmpty ||
        courseId.length > 60 ||
        lessonId.length > 60 ||
        id.length > 128) {
      throw ArgumentError('Invalid course or lesson identifier');
    }
    return id;
  }

  Future<void> savePublishedLesson({
    required String courseId,
    required String lessonId,
    required String title,
    required String content,
    DateTime? savedAt,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty || cleanContent.isEmpty) {
      throw ArgumentError('Published lesson needs a title and text content');
    }
    await offline.saveLesson(AurenOfflineLesson(
      id: offlineIdFor(courseId, lessonId),
      title: cleanTitle,
      content: cleanContent,
      updatedAt: (savedAt ?? DateTime.now()).toUtc(),
    ));
  }
}
