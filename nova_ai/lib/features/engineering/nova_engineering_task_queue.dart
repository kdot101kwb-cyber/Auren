import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nova_engineering_orchestrator.dart';

/// Device-local, reviewable queue. It records plans only; it never executes them.
class NovaEngineeringTaskQueue {
  NovaEngineeringTaskQueue({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'nova_engineering_task_queue_v1';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<NovaEngineeringQueuedTask>> load() async {
    final store = await _store;
    final raw = store.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NovaEngineeringQueuedTask.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<NovaEngineeringQueuedTask> enqueue(
    NovaEngineeringAssignment assignment,
  ) async {
    final store = await _store;
    final existing = await load();
    final task = NovaEngineeringQueuedTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goal: assignment.goal,
      roles: assignment.roles.map((role) => role.name).toList(),
      risk: assignment.risk.name,
      status: NovaEngineeringTaskStatus.planned.name,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      requiresHumanApproval: assignment.requiresHumanApproval,
    );
    final updated = [task, ...existing].take(100).toList(growable: false);
    await store.setString(
      storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    return task;
  }

  Future<bool> updateStatus(String id, NovaEngineeringTaskStatus status) async {
    final store = await _store;
    final tasks = await load();
    var found = false;
    final updated = tasks.map((task) {
      if (task.id != id) return task;
      found = true;
      return task.copyWith(status: status.name);
    }).toList(growable: false);
    if (found) {
      await store.setString(
        storageKey,
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    }
    return found;
  }
}

enum NovaEngineeringTaskStatus { planned, awaitingApproval, approved, completed, blocked }

class NovaEngineeringQueuedTask {
  const NovaEngineeringQueuedTask({
    required this.id,
    required this.goal,
    required this.roles,
    required this.risk,
    required this.status,
    required this.createdAt,
    required this.requiresHumanApproval,
  });

  final String id;
  final String goal;
  final List<String> roles;
  final String risk;
  final String status;
  final String createdAt;
  final bool requiresHumanApproval;

  NovaEngineeringQueuedTask copyWith({String? status}) =>
      NovaEngineeringQueuedTask(
        id: id,
        goal: goal,
        roles: roles,
        risk: risk,
        status: status ?? this.status,
        createdAt: createdAt,
        requiresHumanApproval: requiresHumanApproval,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'roles': roles,
        'risk': risk,
        'status': status,
        'createdAt': createdAt,
        'requiresHumanApproval': requiresHumanApproval,
      };

  factory NovaEngineeringQueuedTask.fromJson(Map<String, dynamic> json) =>
      NovaEngineeringQueuedTask(
        id: json['id'] as String,
        goal: json['goal'] as String,
        roles: (json['roles'] as List<dynamic>).cast<String>(),
        risk: json['risk'] as String,
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        requiresHumanApproval: json['requiresHumanApproval'] as bool,
      );
}
