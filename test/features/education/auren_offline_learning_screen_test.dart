import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/features/education/presentation/auren_offline_learning_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('creates a local learning plan without network access', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenOfflineLearningScreen()));
    await tester.pumpAndSettle();
    expect(find.text('مكتبتك المحلية'), findsOneWidget);
    await tester.tap(find.text('أنشئ خطة بدون إنترنت'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Build a useful skill'), findsOneWidget);
    expect(find.text('Review previous learning'), findsOneWidget);
    expect(find.text('Check understanding'), findsOneWidget);
  });

  testWidgets('shows an empty local library and can open the add lesson dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenOfflineLearningScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا توجد دروس محلية بعد'), findsOneWidget);
    await tester.tap(find.byTooltip('حفظ درس'));
    await tester.pumpAndSettle();
    expect(find.text('حفظ درس على الجهاز'), findsOneWidget);
    expect(find.text('حفظ محلياً'), findsOneWidget);
  });
}
