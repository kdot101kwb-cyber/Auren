import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Personal wellbeing notes stored only on this device in secure storage.
/// This model is for journaling and planning, not diagnosis or treatment.
class AurenWellnessEntry {
  const AurenWellnessEntry({
    required this.id,
    required this.day,
    required this.mood,
    this.habits = const <String>[],
    this.note = '',
  });

  final String id;
  final String day;
  final int mood;
  final List<String> habits;
  final String note;

  String? validate() {
    if (id.trim().isEmpty || day.trim().isEmpty) return 'Entry id and day are required.';
    if (mood < 1 || mood > 5) return 'Mood must be between 1 and 5.';
    if (note.length > 2000 || habits.length > 30 ||
        habits.any((value) => value.trim().isEmpty || value.length > 80)) {
      return 'Wellness entry exceeds allowed limits.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'day': day, 'mood': mood, 'habits': habits, 'note': note,
  };

  factory AurenWellnessEntry.fromJson(Map<String, dynamic> json) =>
      AurenWellnessEntry(
        id: json['id'] as String? ?? '',
        day: json['day'] as String? ?? '',
        mood: json['mood'] as int? ?? 0,
        habits: List<String>.from(json['habits'] as List? ?? const <String>[]),
        note: json['note'] as String? ?? '',
      );
}

class AurenFitnessGoal {
  const AurenFitnessGoal({
    required this.id,
    required this.title,
    required this.weeklyTargetMinutes,
    this.completedMinutes = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final int weeklyTargetMinutes;
  final int completedMinutes;
  final bool active;

  String? validate() {
    if (id.trim().isEmpty || title.trim().isEmpty || title.length > 100) {
      return 'Fitness goal requires an id and a short title.';
    }
    if (weeklyTargetMinutes < 1 || weeklyTargetMinutes > 10080 ||
        completedMinutes < 0 || completedMinutes > 10080) {
      return 'Fitness minutes are outside the allowed range.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'weeklyTargetMinutes': weeklyTargetMinutes,
    'completedMinutes': completedMinutes, 'active': active,
  };

  factory AurenFitnessGoal.fromJson(Map<String, dynamic> json) =>
      AurenFitnessGoal(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        weeklyTargetMinutes: json['weeklyTargetMinutes'] as int? ?? 0,
        completedMinutes: json['completedMinutes'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
      );
}

class AurenSleepEntry {
  const AurenSleepEntry({
    required this.id,
    required this.day,
    required this.durationMinutes,
    this.quality = 3,
    this.note = '',
  });

  final String id;
  final String day;
  final int durationMinutes;
  final int quality;
  final String note;

  String? validate() {
    if (id.trim().isEmpty || day.trim().isEmpty) return 'Sleep entry id and day are required.';
    if (durationMinutes < 0 || durationMinutes > 1440) return 'Sleep duration must be between 0 and 1440 minutes.';
    if (quality < 1 || quality > 5) return 'Sleep quality must be between 1 and 5.';
    if (note.length > 1000) return 'Sleep note is too long.';
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'day': day, 'durationMinutes': durationMinutes,
    'quality': quality, 'note': note,
  };

  factory AurenSleepEntry.fromJson(Map<String, dynamic> json) => AurenSleepEntry(
    id: json['id'] as String? ?? '',
    day: json['day'] as String? ?? '',
    durationMinutes: json['durationMinutes'] as int? ?? 0,
    quality: json['quality'] as int? ?? 3,
    note: json['note'] as String? ?? '',
  );
}

class AurenHealthyHabit {
  const AurenHealthyHabit({
    required this.id,
    required this.title,
    this.active = true,
    this.reminderEnabled = false,
    this.reminderTime,
    this.completedDays = const <String>[],
  });

  final String id;
  final String title;
  final bool active;
  final bool reminderEnabled;
  final String? reminderTime;
  final List<String> completedDays;

  String? validate() {
    if (id.trim().isEmpty || title.trim().isEmpty || title.length > 100) {
      return 'Habit requires an id and a short title.';
    }
    if (completedDays.length > 366 ||
        completedDays.toSet().length != completedDays.length) {
      return 'Habit completion history is invalid or too large.';
    }
    if (reminderEnabled &&
        (reminderTime == null ||
         !RegExp(r'^([01]\\d|2[0-3]):[0-5]\\d$').hasMatch(reminderTime!))) {
      return 'Enabled reminder needs a valid local time (HH:mm).';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'active': active,
    'reminderEnabled': reminderEnabled, 'reminderTime': reminderTime,
    'completedDays': completedDays,
  };

  factory AurenHealthyHabit.fromJson(Map<String, dynamic> json) => AurenHealthyHabit(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    active: json['active'] as bool? ?? true,
    reminderEnabled: json['reminderEnabled'] as bool? ?? false,
    reminderTime: json['reminderTime'] as String?,
    completedDays: List<String>.from(json['completedDays'] as List? ?? const <String>[]),
  );
}

class AurenCareNote {
  const AurenCareNote({
    required this.id,
    required this.day,
    this.providerLabel = '',
    this.questions = const <String>[],
    this.notes = '',
  });

  final String id;
  final String day;
  final String providerLabel;
  final List<String> questions;
  final String notes;

  String? validate() {
    if (id.trim().isEmpty || day.trim().isEmpty) return 'Care note id and day are required.';
    if (providerLabel.length > 100 || notes.length > 2000 || questions.length > 20 ||
        questions.any((q) => q.trim().isEmpty || q.length > 240)) {
      return 'Care note exceeds allowed limits.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'day': day, 'providerLabel': providerLabel,
    'questions': questions, 'notes': notes,
  };

  factory AurenCareNote.fromJson(Map<String, dynamic> json) => AurenCareNote(
    id: json['id'] as String? ?? '',
    day: json['day'] as String? ?? '',
    providerLabel: json['providerLabel'] as String? ?? '',
    questions: List<String>.from(json['questions'] as List? ?? const <String>[]),
    notes: json['notes'] as String? ?? '',
  );
}

class AurenWellbeingData {
  const AurenWellbeingData({
    this.journal = const <AurenWellnessEntry>[],
    this.fitnessGoals = const <AurenFitnessGoal>[],
    this.sleepEntries = const <AurenSleepEntry>[],
    this.habits = const <AurenHealthyHabit>[],
    this.careNotes = const <AurenCareNote>[],
  });

  final List<AurenWellnessEntry> journal;
  final List<AurenFitnessGoal> fitnessGoals;
  final List<AurenSleepEntry> sleepEntries;
  final List<AurenHealthyHabit> habits;
  final List<AurenCareNote> careNotes;

  String? validate() {
    if (journal.length > 365 || fitnessGoals.length > 100 ||
        sleepEntries.length > 365 || habits.length > 100 || careNotes.length > 100) {
      return 'Wellbeing data exceeds local storage limits.';
    }
    final groups = <List<dynamic>>[journal, fitnessGoals, sleepEntries, habits, careNotes];
    for (final group in groups) {
      final ids = <String>{};
      for (final item in group) {
        final issue = (item as dynamic).validate() as String?;
        if (issue != null) return issue;
        if (!ids.add((item as dynamic).id as String)) return 'Duplicate record id.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'journal': journal.map((e) => e.toJson()).toList(),
    'fitnessGoals': fitnessGoals.map((e) => e.toJson()).toList(),
    'sleepEntries': sleepEntries.map((e) => e.toJson()).toList(),
    'habits': habits.map((e) => e.toJson()).toList(),
    'careNotes': careNotes.map((e) => e.toJson()).toList(),
  };

  factory AurenWellbeingData.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported wellbeing data version.');
    }
    List<Map<String, dynamic>> records(String key) {
      final raw = json[key];
      if (raw is! List) throw FormatException('Invalid wellbeing collection: $key.');
      return raw.map((value) {
        if (value is! Map) throw FormatException('Invalid wellbeing record: $key.');
        return Map<String, dynamic>.from(value);
      }).toList();
    }
    final data = AurenWellbeingData(
      journal: records('journal').map(AurenWellnessEntry.fromJson).toList(),
      fitnessGoals: records('fitnessGoals').map(AurenFitnessGoal.fromJson).toList(),
      sleepEntries: records('sleepEntries').map(AurenSleepEntry.fromJson).toList(),
      habits: records('habits').map(AurenHealthyHabit.fromJson).toList(),
      careNotes: records('careNotes').map(AurenCareNote.fromJson).toList(),
    );
    final issue = data.validate();
    if (issue != null) throw FormatException(issue);
    return data;
  }
}

/// Small injectable interface allows deterministic tests without native plugins.
abstract interface class AurenSecureKeyValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements AurenSecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class AurenWellbeingLocalStore {
  AurenWellbeingLocalStore({AurenSecureKeyValueStore? storage})
      : _storage = storage ?? FlutterSecureKeyValueStore();

  final AurenSecureKeyValueStore _storage;

  String _key(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError('Authenticated user id is required.');
    return 'auren_wellbeing_v1_${Uri.encodeComponent(uid)}';
  }

  Future<AurenWellbeingData> load(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null || raw.isEmpty) return const AurenWellbeingData();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid wellbeing document.');
      }
      return AurenWellbeingData.fromJson(decoded);
    } on FormatException {
      // Never silently replace malformed private data with an empty document.
      rethrow;
    } on TypeError {
      throw const FormatException('Wellbeing document contains invalid field types.');
    }
  }

  Future<void> save(String uid, AurenWellbeingData data) async {
    final issue = data.validate();
    if (issue != null) throw ArgumentError(issue);
    await _storage.write(key: _key(uid), value: jsonEncode(data.toJson()));
  }

  Future<void> clear(String uid) => _storage.delete(key: _key(uid));
}
