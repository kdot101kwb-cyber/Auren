import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Four local-first community member tools. Data stays on this device.
class AurenCommunityMemberToolsService {
  AurenCommunityMemberToolsService({SharedPreferences? preferences})
      : _preferences = preferences;
  static const _prefix = 'auren.community_member_tools.v1.';
  static const _maxResources = 100;
  static const _maxActivity = 500;
  SharedPreferences? _preferences;
  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  String _key(String communityId, String suffix) {
    final id = communityId.trim();
    if (id.isEmpty || id.length > 160) {
      throw ArgumentError('A valid community ID is required.');
    }
    return _prefix + id + '.' + suffix;
  }

  Future<List<AurenOnboardingTask>> onboardingTasks(String communityId) async {
    final raw = (await _store).getString(_key(communityId, 'onboarding'));
    if (raw == null) return List<AurenOnboardingTask>.of(AurenOnboardingTask.defaults);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return List<AurenOnboardingTask>.of(AurenOnboardingTask.defaults);
      return decoded.whereType<Map>().map((item) =>
        AurenOnboardingTask.fromMap(Map<String, dynamic>.from(item)))
        .where((task) => task.id.isNotEmpty && task.title.isNotEmpty)
        .take(30).toList();
    } on FormatException {
      return List<AurenOnboardingTask>.of(AurenOnboardingTask.defaults);
    } on TypeError {
      return AurenOnboardingTask.defaults;
    }
  }

  Future<void> setOnboardingTask({required String communityId,
    required String taskId, required bool completed}) async {
    final id = taskId.trim();
    if (id.isEmpty || id.length > 80) throw ArgumentError('Invalid task ID.');
    final tasks = await onboardingTasks(communityId);
    final index = tasks.indexWhere((task) => task.id == id);
    if (index < 0) throw StateError('Onboarding task not found.');
    tasks[index] = tasks[index].copyWith(completed: completed);
    await (await _store).setString(_key(communityId, 'onboarding'),
      jsonEncode(tasks.map((task) => task.toMap()).toList()));
    await _recordActivity(communityId, completed ? 'task_completed' : 'task_reopened');
  }

  Future<List<AurenCommunityResource>> resources(String communityId) async {
    final raw = (await _store).getString(_key(communityId, 'resources'));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((item) =>
        AurenCommunityResource.fromMap(Map<String, dynamic>.from(item)))
        .where((resource) => resource.id.isNotEmpty && resource.title.isNotEmpty)
        .take(_maxResources).toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<String> addResource({required String communityId,
    required String title, required String link, String description = ''}) async {
    final cleanTitle = title.trim(), cleanLink = link.trim();
    final cleanDescription = description.trim();
    final uri = Uri.tryParse(cleanLink);
    if (cleanTitle.isEmpty || cleanTitle.length > 120 ||
        cleanDescription.length > 500 || cleanLink.length > 2048 ||
        uri == null || !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      throw ArgumentError('Resource title, description, or HTTP(S) link is invalid.');
    }
    final current = await resources(communityId);
    if (current.length >= _maxResources) throw StateError('Resource limit reached.');
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    current.insert(0, AurenCommunityResource(id: id, title: cleanTitle,
      link: uri.toString(), description: cleanDescription,
      savedAt: DateTime.now().toUtc()));
    await (await _store).setString(_key(communityId, 'resources'),
      jsonEncode(current.map((item) => item.toMap()).toList()));
    await _recordActivity(communityId, 'resource_saved');
    return id;
  }

  Future<void> removeResource({required String communityId,
    required String resourceId}) async {
    final current = await resources(communityId);
    current.removeWhere((resource) => resource.id == resourceId);
    await (await _store).setString(_key(communityId, 'resources'),
      jsonEncode(current.map((item) => item.toMap()).toList()));
    await _recordActivity(communityId, 'resource_removed');
  }

  Future<AurenCommunityDigestPreferences> digestPreferences() async {
    final raw = (await _store).getString(_prefix + 'digest');
    if (raw == null) return const AurenCommunityDigestPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const AurenCommunityDigestPreferences();
      return AurenCommunityDigestPreferences.fromMap(
        Map<String, dynamic>.from(decoded));
    } on FormatException {
      return const AurenCommunityDigestPreferences();
    } on TypeError {
      return const AurenCommunityDigestPreferences();
    }
  }

  Future<void> saveDigestPreferences(AurenCommunityDigestPreferences value) async {
    await (await _store).setString(_prefix + 'digest', jsonEncode(value.toMap()));
  }

  Future<AurenCommunityActivitySummary> activitySummary(String communityId) async {
    final completedCount = (await onboardingTasks(communityId))
        .where((task) => task.completed).length;
    final raw = (await _store).getString(_key(communityId, 'activity'));
    if (raw == null) {
      return AurenCommunityActivitySummary(
        onboardingTasksCompleted: completedCount);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return AurenCommunityActivitySummary(
          onboardingTasksCompleted: completedCount);
      }
      final validEvents = decoded.whereType<Map>().toList();
      var saved = 0, removed = 0;
      for (final item in validEvents) {
        switch (item['type']) {
          case 'resource_saved':
            saved++;
            break;
          case 'resource_removed':
            removed++;
            break;
        }
      }
      return AurenCommunityActivitySummary(
        onboardingTasksCompleted: completedCount,
        resourcesSaved: saved,
        resourcesRemoved: removed,
        recordedActions: validEvents.length,
      );
    } on FormatException {
      return AurenCommunityActivitySummary(
        onboardingTasksCompleted: completedCount);
    } on TypeError {
      return AurenCommunityActivitySummary(
        onboardingTasksCompleted: completedCount);
    }
  }

  Future<void> _recordActivity(String communityId, String type) async {
    final store = await _store, key = _key(communityId, 'activity');
    List<dynamic> events;
    try {
      final decoded = jsonDecode(store.getString(key) ?? '[]');
      events = decoded is List ? decoded : <dynamic>[];
    } on FormatException {
      events = <dynamic>[];
    } on TypeError {
      events = <dynamic>[];
    }
    events.add({'type': type, 'at': DateTime.now().toUtc().toIso8601String()});
    final start = events.length > _maxActivity ? events.length - _maxActivity : 0;
    await store.setString(key, jsonEncode(events.skip(start).toList()));
  }
}

class AurenOnboardingTask {
  final String id, title;
  final bool completed;
  const AurenOnboardingTask({required this.id, required this.title, this.completed = false});
  static const defaults = <AurenOnboardingTask>[
    AurenOnboardingTask(id: 'read_guidelines', title: 'Read community guidelines'),
    AurenOnboardingTask(id: 'introduce_yourself', title: 'Introduce yourself'),
    AurenOnboardingTask(id: 'find_interests', title: 'Explore community topics'),
    AurenOnboardingTask(id: 'save_resource', title: 'Save a useful community resource'),
  ];
  AurenOnboardingTask copyWith({bool? completed}) =>
      AurenOnboardingTask(id: id, title: title, completed: completed ?? this.completed);
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'completed': completed};
  factory AurenOnboardingTask.fromMap(Map<String, dynamic> map) =>
      AurenOnboardingTask(id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '', completed: map['completed'] == true);
}

class AurenCommunityResource {
  final String id, title, link, description;
  final DateTime savedAt;
  const AurenCommunityResource({required this.id, required this.title,
    required this.link, required this.description, required this.savedAt});
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'link': link,
    'description': description, 'savedAt': savedAt.toIso8601String()};
  factory AurenCommunityResource.fromMap(Map<String, dynamic> map) =>
      AurenCommunityResource(id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '', link: map['link'] as String? ?? '',
        description: map['description'] as String? ?? '',
        savedAt: DateTime.tryParse(map['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
}

class AurenCommunityDigestPreferences {
  final bool enabled, includeMemory, includeResources;
  final String frequency;
  const AurenCommunityDigestPreferences({this.enabled = false,
    this.includeMemory = true, this.includeResources = true, this.frequency = 'weekly'});
  AurenCommunityDigestPreferences copyWith({bool? enabled, bool? includeMemory,
    bool? includeResources, String? frequency}) => AurenCommunityDigestPreferences(
      enabled: enabled ?? this.enabled, includeMemory: includeMemory ?? this.includeMemory,
      includeResources: includeResources ?? this.includeResources,
      frequency: frequency ?? this.frequency);
  Map<String, dynamic> toMap() => {'enabled': enabled, 'includeMemory': includeMemory,
    'includeResources': includeResources, 'frequency': frequency};
  factory AurenCommunityDigestPreferences.fromMap(Map<String, dynamic> map) {
    final frequency = map['frequency'] as String? ?? 'weekly';
    return AurenCommunityDigestPreferences(enabled: map['enabled'] == true,
      includeMemory: map['includeMemory'] != false,
      includeResources: map['includeResources'] != false,
      frequency: const {'daily', 'weekly'}.contains(frequency) ? frequency : 'weekly');
  }
}

class AurenCommunityActivitySummary {
  final int onboardingTasksCompleted, resourcesSaved, resourcesRemoved, recordedActions;
  const AurenCommunityActivitySummary({this.onboardingTasksCompleted = 0,
    this.resourcesSaved = 0, this.resourcesRemoved = 0, this.recordedActions = 0});
}
