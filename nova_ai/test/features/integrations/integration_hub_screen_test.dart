import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/integration_hub_screen.dart';

void main() {
  testWidgets('toolkit filters app-building tools by search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntegrationHubScreen()));

    expect(find.text('استوديو بناء التطبيقات داخل NOVA'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Godot');
    await tester.pumpAndSettle();

    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
  });
}
