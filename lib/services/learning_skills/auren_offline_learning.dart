import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AurenOfflineLesson {
  const AurenOfflineLesson({required this.id, required this.title, required this.content, this.updatedAt});
  final String id;
  final String title;
  final String content;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'content': content, 'updatedAt': updatedAt?.toUtc().toIso8601String()};
  factory AurenOfflineLesson.fromJson(Map<String, dynamic> json) => AurenOfflineLesson(
    id: json['id'] as String, title: json['title'] as String, content: json['content'] as String,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

class AurenOfflineProgress {
  const AurenOfflineProgress({required this.lessonId, required this.completed, required this.updatedAt});
  final String lessonId;
  final bool completed;
  final DateTime updatedAt;
}

abstract interface class AurenLearningLocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class AurenSharedPreferencesLearningStore implements AurenLearningLocalStore {
  const AurenSharedPreferencesLearningStore();
  @override Future<String?> read(String key) async => (await SharedPreferences.getInstance()).getString(key);
  @override Future<void> write(String key, String value) async { await (await SharedPreferences.getInstance()).setString(key, value); }
}

/// Small text-only lesson cache and notes/progress store. Never downloads media.
class AurenOfflineLearning {
  AurenOfflineLearning(this.store);
  final AurenLearningLocalStore store;
  static const _lessonsKey = 'auren_offline_learning_lessons_v1';
  static const _notesKey = 'auren_offline_learning_notes_v1';
  static const _progressKey = 'auren_offline_learning_progress_v1';
  static const maxLessons = 100;
  static const maxNotes = 100;
  static const maxProgressEntries = 200;
  static const maxContentCharacters = 20000;
  static const maxNoteCharacters = 4000;
  static const maxCacheBytes = 512 * 1024;
  static const maxNotesCacheBytes = 512 * 1024;
  static const maxProgressCacheBytes = 128 * 1024;

  Future<void> saveLesson(AurenOfflineLesson lesson) async {
    _validateId(lesson.id);
    if (lesson.title.trim().isEmpty || lesson.title.length > 160 || lesson.content.length > maxContentCharacters) {
      throw ArgumentError('Lesson title/content exceeds offline limits');
    }
    final map = await _readMap(_lessonsKey);
    map[lesson.id] = lesson.toJson();
    if (map.length > maxLessons) throw StateError('Offline lesson limit reached; remove a lesson first');
    final encoded = jsonEncode(map);
    if (utf8.encode(encoded).length > maxCacheBytes) throw StateError('Offline learning cache size limit reached');
    await store.write(_lessonsKey, encoded);
  }

  Future<List<AurenOfflineLesson>> lessons() async {
    final map = await _readMap(_lessonsKey);
    final result = <AurenOfflineLesson>[];
    for (final value in map.values) {
      try {
        final lesson = AurenOfflineLesson.fromJson(value);
        if (lesson.id.trim().isEmpty || lesson.title.trim().isEmpty || lesson.title.length > 160 || lesson.content.length > maxContentCharacters) continue;
        result.add(lesson);
      } on TypeError {
        // Ignore a corrupt record instead of making the entire offline library unusable.
      }
    }
    return List.unmodifiable(result);
  }

  Future<void> removeLesson(String id) async {
    _validateId(id);
    final map = await _readMap(_lessonsKey)..remove(id);
    await store.write(_lessonsKey, jsonEncode(map));
  }

  Future<void> saveNote(String lessonId, String note) async {
    _validateId(lessonId);
    if (note.length > maxNoteCharacters) throw ArgumentError('Note exceeds $maxNoteCharacters characters');
    final notes = await _readStringMap(_notesKey);
    notes[lessonId] = note;
    if (notes.length > maxNotes) throw StateError('Offline note limit reached; remove a note first');
    final encoded = jsonEncode(notes);
    if (utf8.encode(encoded).length > maxNotesCacheBytes) throw StateError('Offline notes cache size limit reached');
    await store.write(_notesKey, encoded);
  }

  Future<String> noteFor(String lessonId) async {
    _validateId(lessonId);
    return (await _readStringMap(_notesKey))[lessonId] ?? '';
  }

  Future<void> setCompleted(String lessonId, bool completed, {DateTime? at}) async {
    _validateId(lessonId);
    final progress = await _readMap(_progressKey);
    progress[lessonId] = {'completed': completed, 'updatedAt': (at ?? DateTime.now()).toUtc().toIso8601String()};
    if (progress.length > maxProgressEntries) throw StateError('Offline progress limit reached');
    final encoded = jsonEncode(progress);
    if (utf8.encode(encoded).length > maxProgressCacheBytes) throw StateError('Offline progress cache size limit reached');
    await store.write(_progressKey, encoded);
  }

  Future<List<AurenOfflineProgress>> progress() async {
    final map = await _readMap(_progressKey);
    final result = <AurenOfflineProgress>[];
    for (final entry in map.entries) {
      if (entry.key.trim().isEmpty || entry.value['completed'] is! bool) continue;
      final rawDate = entry.value['updatedAt'];
      final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
      result.add(AurenOfflineProgress(
        lessonId: entry.key, completed: entry.value['completed'] as bool,
        updatedAt: date ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ));
    }
    return List.unmodifiable(result);
  }

  Future<Map<String, dynamic>> _readMap(String key) async {
    final raw = await store.read(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)));
    } on FormatException { return {}; } on TypeError { return {}; }
  }

  Future<Map<String, String>> _readStringMap(String key) async {
    final raw = await store.read(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
    } on FormatException { return {}; }
  }

  void _validateId(String id) {
    if (id.trim().isEmpty || id.length > 128) throw ArgumentError.value(id, 'id', 'must be 1–128 characters');
  }
}
