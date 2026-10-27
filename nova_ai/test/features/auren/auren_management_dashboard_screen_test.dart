import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/auren/auren_management_dashboard_screen.dart';

void main() {
  testWidgets('AUREN dashboard shows the daily board agenda and safe status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenManagementDashboardScreen()),
    );

    expect(find.text('إدارة AUREN ومجلس NOVA'), findsOneWidget);
    expect(find.text('مركز إدارة AUREN'), findsOneWidget);
    expect(find.text('جدول اجتماع اليوم'), findsOneWidget);
    expect(find.text('الجودة ونجاح الاختبارات'), findsOneWidget);

    for (final label in [
      'الأمان والخصوصية',
      'النمو وجذب المستخدمين',
      'السوق العالمي والمنافسون',
      'الإدارة القانونية والحوكمة',
      'فرص واقتراحات اليوم',
      'ابدأ اجتماع اليوم',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.textContaining('هذا لا يعمل أثناء إغلاق التطبيق'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('هذا لا يعمل أثناء إغلاق التطبيق'), findsOneWidget);
  });
}
