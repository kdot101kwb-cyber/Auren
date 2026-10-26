import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/integration_hub_screen.dart';

void main() {
  testWidgets('toolkit shows app-building categories and searchable tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntegrationHubScreen()));

    expect(find.text('استوديو بناء التطبيقات داخل NOVA'), findsOneWidget);
    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Godot');
    await tester.pumpAndSettle();

    expect(find.text('Godot'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);
  });
}
