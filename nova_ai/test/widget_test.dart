import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/main.dart';
import 'package:nova_ai/features/creative/creative_tool_library_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NOVA dashboard exposes main sections', (tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.text('NOVA AI'), findsOneWidget);
    expect(find.text('مركز القيادة الذكي'), findsOneWidget);
    expect(find.text('الوكلاء'), findsWidgets);
    expect(find.text('فرص الدخل'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('dashboard task completion survives app restart', (tester) async {
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final taskLabel = find.text('فحص حالة مستودع AUREN');
    await tester.scrollUntilVisible(taskLabel, 250, scrollable: find.byType(Scrollable).first);
    final checkbox = find.ancestor(of: taskLabel, matching: find.byType(CheckboxListTile));
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final restartedTaskLabel = find.text('فحص حالة مستودع AUREN');
    await tester.scrollUntilVisible(restartedTaskLabel, 250, scrollable: find.byType(Scrollable).first);
    final restartedCheckbox = find.ancestor(of: restartedTaskLabel, matching: find.byType(CheckboxListTile));
    await tester.ensureVisible(restartedCheckbox);
    await tester.pumpAndSettle();
    final tile = tester.widget<CheckboxListTile>(restartedCheckbox);
    expect(tile.value, isTrue);
  });

  testWidgets('creative tool library exposes expanded media categories', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CreativeToolLibraryScreen(onOpenAurenWorkspace: () {})),
    ));
    expect(find.textContaining('مكتبة متوسعة للفيديو والصور والألعاب والكرتون'), findsOneWidget);

    final gamesChip = find.widgetWithText(ChoiceChip, 'ألعاب');
    await tester.scrollUntilVisible(gamesChip, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(gamesChip);
    await tester.pumpAndSettle();
    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Shotcut'), findsNothing);

    final characterChip = find.widgetWithText(ChoiceChip, 'كرتون وشخصيات');
    await tester.scrollUntilVisible(characterChip, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(characterChip);
    await tester.pumpAndSettle();
    expect(find.text('OpenToonz'), findsOneWidget);
    expect(find.text('Piper TTS'), findsNothing);

    final audioChip = find.widgetWithText(ChoiceChip, 'صوت وصوت آلي');
    await tester.scrollUntilVisible(audioChip, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(audioChip);
    await tester.pumpAndSettle();
    expect(find.text('Piper TTS'), findsOneWidget);
    expect(find.text('OpenToonz'), findsNothing);
  });
}
