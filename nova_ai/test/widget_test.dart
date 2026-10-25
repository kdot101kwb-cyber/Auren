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

    await tester.pumpAndSettle();
    final checkbox = find.byType(CheckboxListTile).first;
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    final restartedCheckbox = find.byType(CheckboxListTile).first;
    await tester.ensureVisible(restartedCheckbox);
    await tester.pumpAndSettle();
    final tile = tester.widget<CheckboxListTile>(restartedCheckbox);
    expect(tile.value, isTrue);
  });

  testWidgets('creative tool library shows 90 tools and filters by category', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreativeToolLibraryScreen(onOpenAurenWorkspace: () {}),
    ));
    expect(find.textContaining('90 أداة للاستكشاف'), findsOneWidget);

    final gamesChip = find.widgetWithText(ChoiceChip, 'ألعاب');
    await tester.ensureVisible(gamesChip);
    await tester.tap(gamesChip);
    await tester.pumpAndSettle();
    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Shotcut'), findsNothing);
  });
}
