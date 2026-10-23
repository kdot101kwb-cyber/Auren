import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A private, device-local emergency preparation checklist.
/// This is a planning aid, not a source of verified emergency advice.
class AurenEmergencyPreparednessService {
  AurenEmergencyPreparednessService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _prefix = 'auren.emergency_preparedness.v1.';
  static const _maxAreaLength = 120;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  static const List<AurenPreparednessTask> defaults = [
    AurenPreparednessTask(
      id: 'trusted_contact',
      title: 'Choose a trusted person to contact',
    ),
    AurenPreparednessTask(
      id: 'emergency_numbers',
      title: 'Save verified local emergency numbers',
    ),
    AurenPreparednessTask(
      id: 'essentials',
      title: 'Prepare essential documents and supplies',
    ),
    AurenPreparednessTask(
      id: 'meeting_point',
      title: 'Agree on a safe meeting point',
    ),
  ];

  String _key(String area) {
    final normalized = area.trim().toLowerCase();
    if (normalized.isEmpty || normalized.length > _maxAreaLength) {
      throw ArgumentError('A valid area label is required.');
    }
    return '$_prefix${Uri.encodeComponent(normalized)}';
  }

  Future<List<AurenPreparednessTask>> tasksFor(String area) async {
    final raw = (await _store).getString(_key(area));
    if (raw == null) return List.of(defaults);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return List.of(defaults);
      final tasks = decoded
          .whereType<Map>()
          .map((row) => AurenPreparednessTask.fromMap(
              Map<String, dynamic>.from(row)))
          .where((task) =>
              task.id.isNotEmpty &&
              task.title.isNotEmpty &&
              defaults.any((item) => item.id == task.id))
          .toList();
      if (tasks.isEmpty) return List.of(defaults);
      return tasks;
    } on FormatException {
      return List.of(defaults);
    } on TypeError {
      return List.of(defaults);
    }
  }

  Future<void> setCompleted({
    required String area,
    required String taskId,
    required bool completed,
  }) async {
    final id = taskId.trim();
    if (!defaults.any((task) => task.id == id)) {
      throw ArgumentError('Unknown preparedness task.');
    }
    final tasks = await tasksFor(area);
    final index = tasks.indexWhere((task) => task.id == id);
    if (index < 0) throw StateError('Preparedness task is unavailable.');
    tasks[index] = tasks[index].copyWith(completed: completed);
    await (await _store).setString(
      _key(area),
      jsonEncode(tasks.map((task) => task.toMap()).toList()),
    );
  }
}

class AurenPreparednessTask {
  final String id;
  final String title;
  final bool completed;

  const AurenPreparednessTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  AurenPreparednessTask copyWith({bool? completed}) =>
      AurenPreparednessTask(
        id: id,
        title: title,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory AurenPreparednessTask.fromMap(Map<String, dynamic> map) =>
      AurenPreparednessTask(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        completed: map['completed'] == true,
      );
}
