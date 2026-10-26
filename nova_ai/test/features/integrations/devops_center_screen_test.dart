import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/integrations/devops_center_screen.dart';

void main() {
  testWidgets('DevOps center clearly distinguishes connected and unconnected providers',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaDevOpsCenterScreen()));
    await tester.pump();

    expect(find.text('NOVA DevOps Center'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('CircleCI'), findsOneWidget);
    expect(find.text('GitLab CI/CD'), findsOneWidget);
    expect(find.text('قراءة عامة'), findsOneWidget);
    expect(find.text('غير مربوط'), findsNWidgets(2));
    expect(find.textContaining('لا توجد هنا صلاحية'), findsOneWidget);
  });
}
