import 'package:shared_preferences/shared_preferences.dart';
import 'household_maintenance_service.dart';
import 'uid_scoped_json_list_store.dart';

class AurenHouseholdMaintenanceStore {
  AurenHouseholdMaintenanceStore({SharedPreferences? preferences})
      : _store = AurenUidScopedJsonListStore<AurenMaintenanceTask>(
          keyPrefix: 'auren_household_maintenance_v1_', preferences: preferences);

  final AurenUidScopedJsonListStore<AurenMaintenanceTask> _store;

  Future<List<AurenMaintenanceTask>> loadTasks(String uid) async {
    final tasks = (await _store.load(uid, decode: _fromJson, validate: (v) => v.validate())).toList();
    final ids = <String>{};
    for (final task in tasks) {
      if (!ids.add(task.id)) {
        throw const FormatException('Duplicate maintenance task id.');
      }
    }
    tasks.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      final byDate = a.dueAt!.compareTo(b.dueAt!);
      return byDate != 0 ? byDate : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return List.unmodifiable(tasks);
  }

  Future<void> saveTask(String uid, AurenMaintenanceTask task) async {
    final issue = task.validate();
    if (issue != null) throw ArgumentError(issue);
    final tasks = (await loadTasks(uid)).toList();
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index < 0) {
      if (task.status != AurenMaintenanceStatus.planned) {
        throw ArgumentError('A new maintenance task must start as planned.');
      }
      tasks.add(task);
    } else {
      if (!AurenMaintenanceLifecycle.canTransition(tasks[index].status, task.status)) {
        throw StateError('Invalid maintenance status transition.');
      }
      tasks[index] = task;
    }
    await _store.saveAll(uid, tasks, encode: _toJson, validate: (v) => v.validate());
  }

  Future<AurenMaintenanceTask> transitionTask(String uid, String taskId, AurenMaintenanceStatus next) async {
    final tasks = await loadTasks(uid);
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) throw ArgumentError('Maintenance task was not found.');
    final updated = AurenMaintenanceLifecycle.transition(tasks[index], next);
    await saveTask(uid, updated);
    return updated;
  }

  static Map<String, dynamic> _toJson(AurenMaintenanceTask task) => {
    'id': task.id, 'title': task.title, 'area': task.area, 'description': task.description,
    'dueAt': task.dueAt?.toUtc().toIso8601String(),
    'estimatedCostMinor': task.estimatedCostMinor, 'actualCostMinor': task.actualCostMinor,
    'status': task.status.name,
  };

  static AurenMaintenanceTask _fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'planned';
    final status = switch (statusName) {
      'planned' => AurenMaintenanceStatus.planned,
      'inProgress' => AurenMaintenanceStatus.inProgress,
      'completed' => AurenMaintenanceStatus.completed,
      'cancelled' => AurenMaintenanceStatus.cancelled,
      _ => throw const FormatException('Unknown maintenance status.'),
    };
    return AurenMaintenanceTask(
      id: json['id'] as String, title: json['title'] as String, area: json['area'] as String,
      description: json['description'] as String? ?? '',
      dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
      estimatedCostMinor: (json['estimatedCostMinor'] as num?)?.toInt(),
      actualCostMinor: (json['actualCostMinor'] as num?)?.toInt(), status: status,
    );
  }
}