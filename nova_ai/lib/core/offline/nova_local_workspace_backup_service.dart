import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nova_local_workspace_store.dart';

/// Validated JSON export/import for the task workspace only.
/// This never includes authentication, payment, wallet, or device secrets.
class NovaLocalWorkspaceBackupService {
  NovaLocalWorkspaceBackupService({
    required SharedPreferences preferences,
    this.storageKey = 'nova.workspace.tasks.v1',
    this.maxTasks = 500,
  }) : _preferences = preferences;

  final SharedPreferences _preferences;
  final String storageKey;
  final int maxTasks;

  Future<String> exportJson() async {
    final store = NovaLocalWorkspaceStore(
      preferences: _preferences,
      storageKey: storageKey,
      maxTasks: maxTasks,
    );
    final tasks = await store.loadTasks();
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
    });
  }

  /// Returns false without changing storage if any validation fails.
  Future<bool> restoreJson(String source) async {
    if (source.isEmpty || source.length > 1024 * 1024) return false;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map || decoded['schemaVersion'] != 1) return false;
      final rawTasks = decoded['tasks'];
      if (rawTasks is! List || rawTasks.length > maxTasks) return false;
      final tasks = rawTasks.map(NovaWorkspaceTask.fromJson).toList();
      if (tasks.any((task) => task == null)) return false;
      final validTasks = tasks.cast<NovaWorkspaceTask>();
      final ids = validTasks.map((task) => task.id).toSet();
      if (ids.length != validTasks.length) return false;
      return _preferences.setString(
        storageKey,
        jsonEncode(validTasks.map((task) => task.toJson()).toList()),
      );
    } catch (_) {
      return false;
    }
  }
}
