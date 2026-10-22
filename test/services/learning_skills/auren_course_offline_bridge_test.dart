import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_course_offline_bridge.dart';
import 'package:auren/services/learning_skills/auren_offline_learning.dart';

class _MemoryStore implements AurenLearningLocalStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('published lesson can be reopened from the offline library', () async {
    final store = _MemoryStore();
    final bridge = AurenCourseOfflineBridge(AurenOfflineLearning(store));

    await bridge.savePublishedLesson(
      courseId: 'dart-course',
      lessonId: 'lesson-1',
      title: '  Dart variables  ',
      content: '  Variables store values.  ',
      savedAt: DateTime.utc(2026, 10, 22),
    );

    // Recreate the service, as the app does after leaving and reopening a screen.
    final reopened = AurenOfflineLearning(store);
    final lessons = await reopened.lessons();
    expect(lessons, hasLength(1));
    expect(lessons.single.id, 'course-dart-course-lesson-lesson-1');
    expect(lessons.single.title, 'Dart variables');
    expect(lessons.single.content, 'Variables store values.');
    expect(lessons.single.updatedAt, DateTime.utc(2026, 10, 22));
  });

  test('rejects empty lesson text and invalid identifiers', () async {
    final bridge = AurenCourseOfflineBridge(AurenOfflineLearning(_MemoryStore()));

    await expectLater(
      bridge.savePublishedLesson(
        courseId: 'course',
        lessonId: 'lesson',
        title: ' ',
        content: 'text',
      ),
      throwsArgumentError,
    );
    expect(() => bridge.offlineIdFor('', 'lesson'), throwsArgumentError);
    expect(() => bridge.offlineIdFor('c' * 61, 'lesson'), throwsArgumentError);
  });

  test('re-saving a published lesson updates it rather than duplicating it', () async {
    final store = _MemoryStore();
    final bridge = AurenCourseOfflineBridge(AurenOfflineLearning(store));

    await bridge.savePublishedLesson(
      courseId: 'course',
      lessonId: 'lesson',
      title: 'First title',
      content: 'First text',
    );
    await bridge.savePublishedLesson(
      courseId: 'course',
      lessonId: 'lesson',
      title: 'Updated title',
      content: 'Updated text',
    );

    final lessons = await AurenOfflineLearning(store).lessons();
    expect(lessons, hasLength(1));
    expect(lessons.single.title, 'Updated title');
    expect(lessons.single.content, 'Updated text');
  });
}
