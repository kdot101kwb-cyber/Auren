import 'package:auren/features/entertainment/presentation/auren_interactive_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('restores the last selected story node', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenInteractiveStoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('البوابة التي لا تظهر مرتين'), findsOneWidget);
    await tester.tap(find.text('أبني شيئًا لم يوجد'));
    await tester.pumpAndSettle();

    expect(find.text('ورشة الاحتمالات'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(home: AurenInteractiveStoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('ورشة الاحتمالات'), findsWidgets);
  });

  testWidgets('restart clears saved progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenInteractiveStoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('أستكشف المجهول'));
    await tester.pumpAndSettle();
    expect(find.text('حديقة الاحتمالات'), findsWidgets);

    await tester.tap(find.byTooltip('إعادة القصة'));
    await tester.pumpAndSettle();

    expect(find.text('البوابة التي لا تظهر مرتين'), findsOneWidget);
  });
  testWidgets('shows the route trail as choices are made', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenInteractiveStoryScreen()),
    );
    await tester.pumpAndSettle();

    final companionsChoice = find.text('أبحث عن رفاق');
    await tester.ensureVisible(companionsChoice);
    await tester.tap(companionsChoice);
    await tester.pumpAndSettle();

    expect(find.text('ساحة الغرباء'), findsWidgets);
    expect(find.text('أثر اختياراتك'), findsOneWidget);
    expect(find.text('البوابة التي لا تظهر مرتين'), findsOneWidget);
    expect(find.text('الفصل 2 من 4'), findsOneWidget);
  });

}
