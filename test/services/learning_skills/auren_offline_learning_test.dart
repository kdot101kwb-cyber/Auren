import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/learning_skills/auren_offline_learning.dart';

class MemoryStore implements AurenLearningLocalStore {
  final values = <String, String>{};
  @override Future<String?> read(String key) async => values[key];
  @override Future<void> write(String key, String value) async { values[key] = value; }
}

void main() {
  test('persists lesson text, notes and progress across service instances', () async {
    final store = MemoryStore();
    final first = AurenOfflineLearning(store);
    await first.saveLesson(AurenOfflineLesson(id: 'lesson-1', title: 'Dart basics', content: 'Variables and types'));
    await first.saveNote('lesson-1', 'Review types tomorrow');
    await first.setCompleted('lesson-1', true, at: DateTime.utc(2026, 10, 21));
    final reopened = AurenOfflineLearning(store);
    expect((await reopened.lessons()).single.content, 'Variables and types');
    expect(await reopened.noteFor('lesson-1'), 'Review types tomorrow');
    expect((await reopened.progress()).single.completed, isTrue);
  });
  test('enforces bounded content, notes and IDs', () async {
    final offline = AurenOfflineLearning(MemoryStore());
    await expectLater(offline.saveLesson(AurenOfflineLesson(id: 'x', title: '  ', content: 'text')), throwsArgumentError);
    await expectLater(offline.saveLesson(AurenOfflineLesson(id: 'x', title: 'Lesson', content: 'x' * (AurenOfflineLearning.maxContentCharacters + 1))), throwsArgumentError);
    await expectLater(offline.saveNote('x', 'x' * (AurenOfflineLearning.maxNoteCharacters + 1)), throwsArgumentError);
    await expectLater(offline.noteFor(' '), throwsArgumentError);
  });
  test('bounds note count to keep local storage predictable', () async {
    final offline = AurenOfflineLearning(MemoryStore());
    for (var i = 0; i < AurenOfflineLearning.maxNotes; i++) {
      await offline.saveNote('lesson-$i', 'note');
    }
    await expectLater(offline.saveNote('lesson-over-limit', 'note'), throwsStateError);
  });

  test('skips malformed persisted lesson and progress records without losing valid entries', () async {
    final store = MemoryStore();
    store.values['auren_offline_learning_lessons_v1'] =
        '{"good":{"id":"good","title":"Valid","content":"text"},"bad":{"id":"bad","title":12,"content":false}}';
    store.values['auren_offline_learning_progress_v1'] =
        '{"good":{"completed":true,"updatedAt":"2026-10-21T00:00:00Z"},"bad":{"completed":"yes","updatedAt":"not-a-date"}}';
    final offline = AurenOfflineLearning(store);
    expect((await offline.lessons()).map((lesson) => lesson.id), ['good']);
    expect((await offline.progress()).map((item) => item.lessonId), ['good']);
  });

  test('removes cached lesson without deleting notes/progress implicitly', () async {
    final offline = AurenOfflineLearning(MemoryStore());
    await offline.saveLesson(const AurenOfflineLesson(id: 'x', title: 'Lesson', content: 'text'));
    await offline.saveNote('x', 'private note');
    await offline.removeLesson('x');
    expect(await offline.lessons(), isEmpty);
    expect(await offline.noteFor('x'), 'private note');
  });
  test('removing a lesson also removes its notes and progress', () async {
    final store = MemoryStore();
    final offline = AurenOfflineLearning(store);
    await offline.saveLesson(AurenOfflineLesson(id: 'lesson-remove', title: 'Temporary', content: 'Text'));
    await offline.saveNote('lesson-remove', 'Private note');
    await offline.setCompleted('lesson-remove', true);

    await offline.removeLesson('lesson-remove');

    expect(await offline.lessons(), isEmpty);
    expect(await offline.noteFor('lesson-remove'), isEmpty);
    expect(await offline.progress(), isEmpty);
  });

}
