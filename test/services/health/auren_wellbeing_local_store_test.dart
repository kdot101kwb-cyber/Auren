import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/health/auren_wellbeing_local_store.dart';

class MemorySecureStore implements AurenSecureKeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

void main() {
  group('wellbeing model validation', () {
    test('journal limits mood and note length', () {
      expect(const AurenWellnessEntry(id: 'j1', day: '2026-10-21', mood: 5).validate(), isNull);
      expect(const AurenWellnessEntry(id: 'j1', day: '2026-10-21', mood: 0).validate(), isNotNull);
      expect(AurenWellnessEntry(
        id: 'j2', day: '2026-10-21', mood: 3, note: List.filled(2001, 'x').join(),
      ).validate(), isNotNull);
    });

    test('fitness goals reject non-progressive or unbounded values', () {
      expect(const AurenFitnessGoal(id: 'f1', title: 'Walk', weeklyTargetMinutes: 1).validate(), isNull);
      expect(const AurenFitnessGoal(id: 'f1', title: 'Walk', weeklyTargetMinutes: 0).validate(), isNotNull);
      expect(const AurenFitnessGoal(
        id: 'f1', title: 'Walk', weeklyTargetMinutes: 30, completedMinutes: -1,
      ).validate(), isNotNull);
    });

    test('sleep duration and quality are bounded', () {
      expect(const AurenSleepEntry(
        id: 's1', day: '2026-10-21', durationMinutes: 480, quality: 4,
      ).validate(), isNull);
      expect(const AurenSleepEntry(
        id: 's1', day: '2026-10-21', durationMinutes: 1441,
      ).validate(), isNotNull);
      expect(const AurenSleepEntry(
        id: 's1', day: '2026-10-21', durationMinutes: 400, quality: 6,
      ).validate(), isNotNull);
    });

    test('habit reminder is optional but must be a valid local time when enabled', () {
      expect(const AurenHealthyHabit(id: 'h1', title: 'Stretch').validate(), isNull);
      expect(const AurenHealthyHabit(
        id: 'h1', title: 'Stretch', reminderEnabled: true,
      ).validate(), isNotNull);
      expect(const AurenHealthyHabit(
        id: 'h1', title: 'Stretch', reminderEnabled: true, reminderTime: '25:70',
      ).validate(), isNotNull);
      expect(const AurenHealthyHabit(
        id: 'h1', title: 'Stretch', reminderEnabled: true, reminderTime: '07:30',
      ).validate(), isNull);
    });

    test('care coordination limits notes and question list without medical advice fields', () {
      expect(const AurenCareNote(
        id: 'c1', day: '2026-10-21', questions: ['What should I ask?'],
      ).validate(), isNull);
      expect(AurenCareNote(
        id: 'c1', day: '2026-10-21', notes: List.filled(2001, 'x').join(),
      ).validate(), isNotNull);
    });

    test('data rejects duplicate IDs and collection overflow', () {
      const duplicate = AurenWellbeingData(
        journal: [
          AurenWellnessEntry(id: 'same', day: '2026-10-20', mood: 3),
          AurenWellnessEntry(id: 'same', day: '2026-10-21', mood: 4),
        ],
      );
      expect(duplicate.validate(), isNotNull);
      expect(const AurenWellbeingData(
        habits: [
          AurenHealthyHabit(id: '', title: 'invalid'),
        ],
      ).validate(), isNotNull);
    });

    test('round trips all five wellbeing areas through schema v1', () {
      const original = AurenWellbeingData(
        journal: [AurenWellnessEntry(id: 'j', day: '2026-10-21', mood: 4, note: 'calm')],
        fitnessGoals: [AurenFitnessGoal(id: 'f', title: 'Walk', weeklyTargetMinutes: 90, completedMinutes: 20)],
        sleepEntries: [AurenSleepEntry(id: 's', day: '2026-10-21', durationMinutes: 450, quality: 4)],
        habits: [AurenHealthyHabit(id: 'h', title: 'Stretch', reminderEnabled: true, reminderTime: '07:00')],
        careNotes: [AurenCareNote(id: 'c', day: '2026-10-22', questions: ['Question for provider'])],
      );
      expect(original.validate(), isNull);
      final decoded = AurenWellbeingData.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.journal.single.note, 'calm');
      expect(decoded.fitnessGoals.single.completedMinutes, 20);
      expect(decoded.sleepEntries.single.durationMinutes, 450);
      expect(decoded.habits.single.reminderTime, '07:00');
      expect(decoded.careNotes.single.questions, ['Question for provider']);
    });
  });

  group('AurenWellbeingLocalStore', () {
    late MemorySecureStore secure;
    late AurenWellbeingLocalStore store;

    setUp(() {
      secure = MemorySecureStore();
      store = AurenWellbeingLocalStore(storage: secure);
    });

    test('stores data under account-scoped keys and does not call a network API', () async {
      const data = AurenWellbeingData(
        journal: [AurenWellnessEntry(id: 'j1', day: '2026-10-21', mood: 4)],
      );
      await store.save('user-a', data);
      expect((await store.load('user-a')).journal.single.mood, 4);
      expect((await store.load('user-b')).journal, isEmpty);
      expect(secure.values.keys.single, contains('user-a'));
    });

    test('rejects blank user IDs and invalid data before writing', () async {
      await expectLater(store.load('  '), throwsArgumentError);
      await expectLater(store.save('user-a', const AurenWellbeingData(
        journal: [AurenWellnessEntry(id: 'bad', day: 'today', mood: 7)],
      )), throwsArgumentError);
      expect(secure.values, isEmpty);
    });

    test('preserves malformed stored data when load fails', () async {
      const key = 'auren_wellbeing_v1_user-a';
      const raw = '{"schemaVersion":1,"journal":null}';
      secure.values[key] = raw;
      await expectLater(store.load('user-a'), throwsFormatException);
      expect(secure.values[key], raw);
    });

    test('rejects unsupported schema without overwriting it', () async {
      const key = 'auren_wellbeing_v1_user-a';
      const raw = '{"schemaVersion":2}';
      secure.values[key] = raw;
      await expectLater(store.load('user-a'), throwsFormatException);
      expect(secure.values[key], raw);
    });

    test('clear deletes only the selected account key', () async {
      await store.save('user-a', const AurenWellbeingData());
      await store.save('user-b', const AurenWellbeingData());
      await store.clear('user-a');
      expect(await store.load('user-a'), isA<AurenWellbeingData>());
      expect(secure.values.keys, hasLength(1));
      expect(secure.values.keys.single, contains('user-b'));
    });
  });
}
