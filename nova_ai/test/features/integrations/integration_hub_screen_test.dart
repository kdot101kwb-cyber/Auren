import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/integration_hub_screen.dart';

void main() {
  testWidgets('tool catalog displays app-building categories and search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntegrationHubScreen()));

    expect(find.text('مركز بناء التطبيقات في NOVA'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Godot');
    await tester.pumpAndSettle();

    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);
    expect(find.textContaining('أداة ظاهرة'), findsOneWidget);

    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Flutter'), 250, scrollable: find.byType(Scrollable).first);
    expect(find.text('Flutter'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('التصميم وتجربة المستخدم'), 250, scrollable: find.byType(Scrollable).first);
    expect(find.text('التصميم وتجربة المستخدم'), findsOneWidget);
  });

  testWidgets('tool catalog shows empty state for unmatched search and can clear it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntegrationHubScreen()));

    await tester.enterText(find.byType(TextField), 'tool-that-does-not-exist-xyz');
    await tester.pumpAndSettle();
    expect(find.textContaining('ما لقيت أداة مطابقة'), findsOneWidget);

    await tester.tap(find.byTooltip('مسح البحث'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Flutter'), 250, scrollable: find.byType(Scrollable).first);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.textContaining('ما لقيت أداة مطابقة'), findsNothing);
  });
}
