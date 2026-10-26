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
    expect(find.text('الأمان والخصوصية'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('فرص واقتراحات اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('فرص واقتراحات اليوم'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ابدأ اجتماع اليوم'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ابدأ اجتماع اليوم'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('هذا لا يعمل أثناء إغلاق التطبيق'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('هذا لا يعمل أثناء إغلاق التطبيق'), findsOneWidget);
  });
}
