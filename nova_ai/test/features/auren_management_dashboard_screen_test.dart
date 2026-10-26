import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/auren/auren_management_dashboard_screen.dart';

void main() {
  testWidgets('AUREN management dashboard exposes daily council and agenda',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenManagementDashboardScreen()),
    );

    expect(find.text('إدارة AUREN ومجلس NOVA'), findsOneWidget);
    expect(find.text('مركز إدارة AUREN'), findsOneWidget);
    expect(find.text('جدول اجتماع اليوم'), findsOneWidget);

    for (final label in [
      'الجودة ونجاح الاختبارات',
      'الأمان والخصوصية',
      'ابدأ اجتماع اليوم',
      'سجل اجتماعات المجلس',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.textContaining('سجل الاجتماعات يظهر بعد إعداد Firebase'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('سجل الاجتماعات يظهر بعد إعداد Firebase'), findsOneWidget);
  });

  testWidgets('dashboard keeps the council usable when Firebase is not configured',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenManagementDashboardScreen()),
    );

    expect(find.text('حالة المشروع'), findsOneWidget);
    expect(find.text('مجلس الإدارة'), findsOneWidget);
    expect(find.textContaining('تحتاج تحققاً مباشراً'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
