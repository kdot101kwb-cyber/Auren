import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/offline/nova_local_workspace_store.dart';

void main() {
  late SharedPreferences preferences;
  late NovaLocalWorkspaceStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = NovaLocalWorkspaceStore(preferences: preferences);
  });

  NovaWorkspaceTask task(String id, {String title = 'Task'}) {
    final now = DateTime.utc(2026, 11, 1);
    return NovaWorkspaceTask(
      id: id,
      title: title,
      details: 'local note',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('saves, reloads, and updates a task without duplicating its id', () async {
    expect(await store.saveTask(task('one')), isTrue);
    expect(await store.saveTask(task('one', title: 'Updated')), isTrue);
    final result = await store.loadTasks();
    expect(result, hasLength(1));
    expect(result.single.title, 'Updated');
  });

  test('completion state survives a fresh store instance', () async {
    await store.saveTask(task('one'));
    expect(await store.setCompleted('one', true), isTrue);
    final reloaded = NovaLocalWorkspaceStore(preferences: preferences);
    expect((await reloaded.loadTasks()).single.isCompleted, isTrue);
  });

  test('unknown ids cannot be changed or deleted', () async {
    expect(await store.setCompleted('missing', true), isFalse);
    expect(await store.deleteTask('missing'), isFalse);
  });

  test('deletes an existing task and clears local workspace data', () async {
    await store.saveTask(task('one'));
    expect(await store.deleteTask('one'), isTrue);
    expect(await store.loadTasks(), isEmpty);
    await store.saveTask(task('two'));
    expect(await store.clear(), isTrue);
    expect(await store.loadTasks(), isEmpty);
  });

  test('corrupt stored JSON is treated as an empty workspace', () async {
    await preferences.setString('nova.workspace.tasks.v1', '{not-json');
    expect(await store.loadTasks(), isEmpty);
  });

  test('invalid records are ignored while valid records remain readable', () async {
    await preferences.setString(
      'nova.workspace.tasks.v1',
      '[{"id":"bad"},{"id":"ok","title":"Keep","createdAt":"2026-11-01T00:00:00Z","updatedAt":"2026-11-01T00:00:00Z"}]',
    );
    final result = await store.loadTasks();
    expect(result, hasLength(1));
    expect(result.single.id, 'ok');
  });

  test('store enforces a bounded task history', () async {
    final bounded = NovaLocalWorkspaceStore(
      preferences: preferences,
      maxTasks: 2,
    );
    await bounded.saveTask(task('one'));
    await bounded.saveTask(task('two'));
    await bounded.saveTask(task('three'));
    expect(await bounded.loadTasks(), hasLength(2));
  });
}
