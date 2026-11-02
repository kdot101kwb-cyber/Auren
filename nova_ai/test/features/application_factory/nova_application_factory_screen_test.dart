import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/application_factory/nova_application_factory_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFactory(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NovaApplicationFactoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows idea intake, market scout and honest integration states',
      (tester) async {
    await pumpFactory(tester);

    expect(find.text('مصنع التطبيقات الذكي'), findsOneWidget);
    expect(find.text('فكرة جديدة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('App Market Scout'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('App Market Scout'), findsOneWidget);
    expect(find.textContaining('مصادر السوق الحية غير موصولة بعد'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('DevOps Command Center'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DevOps Command Center'), findsOneWidget);
  });

  testWidgets('switches to existing app intake', (tester) async {
    await pumpFactory(tester);
    await tester.tap(find.text('تطبيق موجود'));
    await tester.pumpAndSettle();

    expect(find.text('رابط GitHub أو المشروع'), findsOneWidget);
    expect(find.text('ما الذي تريد فحصه أو تحديثه؟'), findsOneWidget);
  });
}
