import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/core/offline/nova_local_workspace_backup_service.dart';
import 'package:nova_ai/core/offline/nova_local_workspace_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports and restores a validated local workspace snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = NovaLocalWorkspaceStore(preferences: prefs);
    final now = DateTime.utc(2026, 11, 1);
    await store.saveTask(NovaWorkspaceTask(
      id: 'task-1',
      title: 'Backup this task',
      createdAt: now,
      updatedAt: now,
    ));
    final backup = NovaLocalWorkspaceBackupService(preferences: prefs);
    final json = await backup.exportJson();

    await store.clear();
    expect(await store.loadTasks(), isEmpty);
    expect(await backup.restoreJson(json), isTrue);
    expect((await store.loadTasks()).single.title, 'Backup this task');
  });

  test('rejects invalid or duplicate snapshots without overwriting data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = NovaLocalWorkspaceStore(preferences: prefs);
    final now = DateTime.utc(2026, 11, 1);
    await store.saveTask(NovaWorkspaceTask(
      id: 'keep',
      title: 'Keep existing',
      createdAt: now,
      updatedAt: now,
    ));
    final backup = NovaLocalWorkspaceBackupService(preferences: prefs);
    expect(await backup.restoreJson('{"schemaVersion":99,"tasks":[]}'), isFalse);
    expect((await store.loadTasks()).single.id, 'keep');
  });
}
