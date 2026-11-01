import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Offline task data only; never store credentials or payment secrets here.
class NovaWorkspaceTask {
  const NovaWorkspaceTask({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.details = '',
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String details;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  NovaWorkspaceTask copyWith({
    String? title,
    String? details,
    DateTime? updatedAt,
    bool? isCompleted,
  }) => NovaWorkspaceTask(
        id: id,
        title: title ?? this.title,
        details: details ?? this.details,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'details': details,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'isCompleted': isCompleted,
      };

  static NovaWorkspaceTask? fromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final map = Map<String, Object?>.from(value);
      final id = map['id'];
      final title = map['title'];
      final createdAt = DateTime.tryParse('${map['createdAt'] ?? ''}');
      final updatedAt = DateTime.tryParse('${map['updatedAt'] ?? ''}');
      if (id is! String || id.trim().isEmpty ||
          title is! String || title.trim().isEmpty ||
          createdAt == null || updatedAt == null) {
        return null;
      }
      return NovaWorkspaceTask(
        id: id,
        title: title.trim(),
        details: map['details'] is String ? map['details']! as String : '',
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
        isCompleted: map['isCompleted'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Device-local persistence. This is not cloud sync.
class NovaLocalWorkspaceStore {
  NovaLocalWorkspaceStore({
    SharedPreferences? preferences,
    this.storageKey = 'nova.workspace.tasks.v1',
    this.maxTasks = 500,
  })  : assert(maxTasks > 0),
        _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;
  final String storageKey;
  final int maxTasks;

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  Future<List<NovaWorkspaceTask>> loadTasks() async {
    final preferences = await _preferences;
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <NovaWorkspaceTask>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <NovaWorkspaceTask>[];
      final tasks = decoded.map(NovaWorkspaceTask.fromJson)
          .whereType<NovaWorkspaceTask>().toList()
        ..sort((a, b) {
        final byUpdated = b.updatedAt.compareTo(a.updatedAt);
        return byUpdated != 0 ? byUpdated : a.id.compareTo(b.id);
      });
      return tasks.take(maxTasks).toList(growable: false);
    } catch (_) {
      return <NovaWorkspaceTask>[];
    }
  }

  Future<bool> saveTask(NovaWorkspaceTask task) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    tasks.sort((a, b) {
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      return byUpdated != 0 ? byUpdated : a.id.compareTo(b.id);
    });
    final preferences = await _preferences;
    return preferences.setString(
      storageKey,
      jsonEncode(tasks.take(maxTasks).map((item) => item.toJson()).toList()),
    );
  }

  Future<bool> setCompleted(String id, bool completed) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    tasks[index] = tasks[index].copyWith(
      isCompleted: completed,
      updatedAt: DateTime.now().toUtc(),
    );
    final preferences = await _preferences;
    return preferences.setString(
      storageKey,
      jsonEncode(tasks.map((item) => item.toJson()).toList()),
    );
  }

  Future<bool> deleteTask(String id) async {
    final tasks = await loadTasks();
    final remaining = tasks.where((item) => item.id != id).toList();
    if (remaining.length == tasks.length) return false;
    final preferences = await _preferences;
    return preferences.setString(
      storageKey,
      jsonEncode(remaining.map((item) => item.toJson()).toList()),
    );
  }

  Future<bool> clear() async {
    final preferences = await _preferences;
    // Persist an explicit empty collection so the cleared state is observable
    // consistently across SharedPreferences implementations and test stores.
    return preferences.setString(storageKey, jsonEncode(<Object>[]));
  }
}
