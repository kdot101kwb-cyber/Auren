import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/health/presentation/health_wellbeing_screen.dart';
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
  Future<void> delete({required String key}) async { values.remove(key); }
}

void main() {
  testWidgets('shows all five wellbeing areas and local privacy disclosure', (tester) async {
    final secure = MemorySecureStore();
    await tester.pumpWidget(MaterialApp(
      home: AurenHealthWellbeingScreen(
        userId: 'test-user',
        store: AurenWellbeingLocalStore(storage: secure),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Wellness Journal'), findsOneWidget);
    expect(find.text('Fitness & Movement'), findsOneWidget);
    expect(find.text('Sleep Routine'), findsOneWidget);
    expect(find.text('Healthy Habits Coach'), findsOneWidget);
    expect(find.text('Care Coordination'), findsOneWidget);
    expect(find.textContaining('لا تُرسل إلى خدمات خارجية'), findsOneWidget);
    expect(secure.values, isEmpty);
  });

  testWidgets('does not open private records without an account scope', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AurenHealthWellbeingScreen(userId: ''),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('يلزم تسجيل الدخول'), findsOneWidget);
    expect(find.text('Wellness Journal'), findsNothing);
  });

  testWidgets('loads account-scoped local records without a network repository', (tester) async {
    final secure = MemorySecureStore();
    final store = AurenWellbeingLocalStore(storage: secure);
    await store.save('test-user', const AurenWellbeingData(
      journal: [AurenWellnessEntry(id: 'j1', day: '2026-10-21', mood: 4, note: 'Good day')],
      fitnessGoals: [AurenFitnessGoal(id: 'f1', title: 'Walk', weeklyTargetMinutes: 90, completedMinutes: 20)],
      sleepEntries: [AurenSleepEntry(id: 's1', day: '2026-10-21', durationMinutes: 420, quality: 4)],
      habits: [AurenHealthyHabit(id: 'h1', title: 'Stretch')],
      careNotes: [AurenCareNote(id: 'c1', day: '2026-10-22', questions: ['Ask provider'])],
    ));

    await tester.pumpWidget(MaterialApp(
      home: AurenHealthWellbeingScreen(userId: 'test-user', store: store),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Good day'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.textContaining('7.0 ساعة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Stretch'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Stretch'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Ask provider'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Ask provider'), findsOneWidget);
  });
}
