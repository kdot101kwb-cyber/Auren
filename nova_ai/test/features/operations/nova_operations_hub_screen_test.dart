import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nova_ai/features/operations/nova_operations_hub_screen.dart';

void main() {
  testWidgets('operations hub exposes the four offline tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaOperationsHubScreen()));
    expect(find.text('مساحة العمل'), findsOneWidget);
    expect(find.text('المخطط اليومي'), findsOneWidget);
    expect(find.text('موافقات المالك'), findsOneWidget);
    expect(find.text('سجل التدقيق'), findsOneWidget);
  });
}
