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
    expect(find.text('Build a useful skill • 30 دقيقة'), findsOneWidget);
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

  testWidgets('saves, opens, completes and removes a lesson from local storage', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenOfflineLearningScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('حفظ درس'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'عنوان الدرس'), 'Offline basics');
    await tester.enterText(find.widgetWithText(TextField, 'النص (بدون فيديو أو ملفات كبيرة)'), 'Saved text for airplane mode');
    await tester.tap(find.text('حفظ محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('Offline basics'), findsOneWidget);
    await tester.tap(find.text('Offline basics'));
    await tester.pumpAndSettle();
    expect(find.text('Saved text for airplane mode'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إكمال الدرس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إكمال الدرس'));
    await tester.pumpAndSettle();
    expect(find.text('مكتمل'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('حذف الدرس المحلي'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('حذف الدرس المحلي'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد دروس محلية بعد. استخدم زر إضافة درس لحفظ نص صغير يعمل دون اتصال.'), findsOneWidget);
  });
}
