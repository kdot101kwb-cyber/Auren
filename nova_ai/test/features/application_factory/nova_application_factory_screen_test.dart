import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/application_factory/nova_application_factory_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows idea intake, market scout and honest integration states', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaApplicationFactoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('مصنع التطبيقات الذكي'), findsOneWidget);
    expect(find.text('فكرة جديدة'), findsOneWidget);
    expect(find.text('App Market Scout'), findsOneWidget);
    expect(find.textContaining('مصادر السوق الحية غير موصولة بعد'), findsOneWidget);
    expect(find.text('DevOps Command Center'), findsOneWidget);
    expect(find.textContaining('عامل بناء معزول'), findsOneWidget);
  });

  testWidgets('switches to existing app intake', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaApplicationFactoryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق موجود'));
    await tester.pumpAndSettle();

    expect(find.text('رابط GitHub أو المشروع'), findsOneWidget);
    expect(find.text('ما الذي تريد فحصه أو تحديثه؟'), findsOneWidget);
  });
}
