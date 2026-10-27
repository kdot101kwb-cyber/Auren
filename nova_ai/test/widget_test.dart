import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/main.dart';
import 'package:nova_ai/features/creative/creative_tool_library_screen.dart';
import 'package:nova_ai/features/secretary/secretary_center_screen.dart';

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

  testWidgets('dashboard opens NOVA foreground voice assistant', (tester) async {
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    final voiceButton = find.byKey(const ValueKey('nova-dashboard-voice'));
    await tester.ensureVisible(voiceButton);
    await tester.tap(voiceButton);
    await tester.pumpAndSettle();

    expect(find.text('NOVA Voice'), findsOneWidget);
    expect(find.text('أنا NOVA'), findsOneWidget);
    expect(find.text('أو اكتب أمرك'), findsOneWidget);
  });

  testWidgets('creative tool library shows 90 tools and filters by category', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CreativeToolLibraryScreen(onOpenAurenWorkspace: () {})),
    ));
    expect(find.textContaining('90 أداة للاستكشاف'), findsOneWidget);

    final gamesChip = find.widgetWithText(ChoiceChip, 'ألعاب');
    await tester.scrollUntilVisible(gamesChip, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(gamesChip);
    await tester.pumpAndSettle();
    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Shotcut'), findsNothing);
  });

  test('secretary risk classifier escalates sensitive topics', () {
    expect(classifySecretaryRisk('Can you send the payment confirmation?'), SecretaryRisk.reviewRequired);
    expect(classifySecretaryRisk('Please confirm our meeting tomorrow'), SecretaryRisk.low);
    expect(classifySecretaryRisk('هذه شكوى عن استرداد المبلغ'), SecretaryRisk.reviewRequired);
  });

  testWidgets('secretary center saves local drafts without sending', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SecretaryCenterScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('secretary-source')), 'بريد');
    await tester.enterText(find.byKey(const ValueKey('secretary-subject')), 'متابعة الاجتماع');
    await tester.enterText(find.byKey(const ValueKey('secretary-body')), 'شكراً على وقتك، سأرسل الملخص قريباً.');
    await tester.tap(find.text('حفظ مسودة على هذا الجهاز'));
    await tester.pumpAndSettle();

    expect(find.text('متابعة الاجتماع'), findsWidgets);
    expect(find.text('محلية فقط'), findsOneWidget);
    expect(find.textContaining('لم تُرسل لأي شخص'), findsOneWidget);
  });
}
