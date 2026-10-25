import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/auren/auren_build_workspace_screen.dart';

void main() {
  testWidgets('shows the dedicated AUREN build workspace and key controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AurenBuildWorkspaceScreen(),
        ),
      ),
    );

    expect(find.text('NOVA Builder · مساحة AUREN'), findsOneWidget);
    expect(find.text('تطوير AUREN'), findsOneWidget);
    expect(find.text('اختبارات الجودة'), findsOneWidget);
    expect(find.text('المراقبة في الخلفية'), findsOneWidget);
    final ideasTitle = find.text('أفكار وأنظمة جديدة');
    await tester.ensureVisible(ideasTitle);
    expect(ideasTitle, findsOneWidget);
    expect(find.text('فتح كود AUREN'), findsOneWidget);
    expect(find.text('فحص التشغيل والاختبارات في GitHub Actions'), findsOneWidget);
    expect(find.text('مراجعة التغييرات وطلبات الدمج'), findsOneWidget);
  });
}
