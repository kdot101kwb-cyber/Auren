import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-first planning workspace for music collaborations. It never sends
/// invitations, uploads audio, or spends money; those require later approval.
class AurenOpenVerseProject {
  final String id;
  final String title;
  final String brief;
  final String genre;
  final String roles;
  final int? bpm;
  final DateTime updatedAt;

  const AurenOpenVerseProject({
    required this.id,
    required this.title,
    required this.brief,
    required this.genre,
    required this.roles,
    required this.bpm,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'brief': brief,
        'genre': genre,
        'roles': roles,
        'bpm': bpm,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory AurenOpenVerseProject.fromMap(Map<String, dynamic> map) {
    final rawBpm = map['bpm'];
    return AurenOpenVerseProject(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      brief: (map['brief'] ?? '').toString(),
      genre: (map['genre'] ?? '').toString(),
      roles: (map['roles'] ?? '').toString(),
      bpm: rawBpm is num ? rawBpm.toInt() : null,
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class AurenOpenVerseWorkspace {
  static const storageKey = 'auren_open_verse_projects_v1';
  static const maxProjects = 50;
  static const maxStoredBytes = 256 * 1024;

  final Future<SharedPreferences> Function() _preferences;

  AurenOpenVerseWorkspace({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  Future<List<AurenOpenVerseProject>> listProjects() async {
    final prefs = await _preferences();
    final raw = prefs.getStringList(storageKey) ?? const <String>[];
    final projects = <AurenOpenVerseProject>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) continue;
        final project = AurenOpenVerseProject.fromMap(decoded);
        if (project.id.isEmpty || project.title.isEmpty) continue;
        projects.add(project);
      } catch (_) {
        // A damaged local entry must not block access to other drafts.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(projects);
  }

  Future<AurenOpenVerseProject> saveProject({
    String? id,
    required String title,
    required String brief,
    String genre = '',
    String roles = '',
    int? bpm,
  }) async {
    final cleanId = id?.trim() ?? '';
    final cleanTitle = title.trim();
    final cleanBrief = brief.trim();
    final cleanGenre = genre.trim();
    final cleanRoles = roles.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120) {
      throw ArgumentError('Project title must be 1–120 characters.');
    }
    if (cleanBrief.length > 4000 || cleanGenre.length > 80 || cleanRoles.length > 1000) {
      throw ArgumentError('One or more project fields exceed their limits.');
    }
    if (bpm != null && (bpm < 40 || bpm > 240)) {
      throw ArgumentError('BPM must be between 40 and 240.');
    }

    final prefs = await _preferences();
    final projects = await listProjects();
    final projectId = cleanId.isEmpty
        ? 'ov-${DateTime.now().microsecondsSinceEpoch}'
        : cleanId;
    final next = AurenOpenVerseProject(
      id: projectId,
      title: cleanTitle,
      brief: cleanBrief,
      genre: cleanGenre,
      roles: cleanRoles,
      bpm: bpm,
      updatedAt: DateTime.now().toUtc(),
    );
    final entries = projects.where((p) => p.id != projectId).toList();
    if (entries.length >= maxProjects) {
      throw StateError('The local workspace is full. Remove a draft before adding another.');
    }
    entries.add(next);
    final encoded = entries.map((p) => jsonEncode(p.toMap())).toList();
    if (encoded.fold<int>(0, (sum, value) => sum + utf8.encode(value).length) > maxStoredBytes) {
      throw StateError('The local workspace storage limit has been reached.');
    }
    await prefs.setStringList(storageKey, encoded);
    return next;
  }

  Future<bool> removeProject(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) throw ArgumentError('Project id is required.');
    final prefs = await _preferences();
    final projects = await listProjects();
    final remaining = projects.where((p) => p.id != cleanId).toList();
    if (remaining.length == projects.length) return false;
    await prefs.setStringList(storageKey, remaining.map((p) => jsonEncode(p.toMap())).toList());
    return true;
  }
}
