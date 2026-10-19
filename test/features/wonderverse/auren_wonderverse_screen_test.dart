import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/wonderverse/presentation/auren_wonderverse_screen.dart';

void main() {
  Future<void> openPortal(WidgetTester tester, String title) async {
    await tester.pumpWidget(const MaterialApp(home: AurenWonderverseScreen()));
    final portal = find.text(title);
    await tester.scrollUntilVisible(
      portal,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final tile = find.ancestor(of: portal, matching: find.byType(InkWell)).first;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('Wonderverse renders six experience portals', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenWonderverseScreen()));
    expect(find.text('WONDERVERSE'), findsOneWidget);
    expect(find.text('عوالم أُورِن'), findsOneWidget);
    expect(find.text('بوابات العوالم'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final title in [
      'حضارة في دقيقة',
      'اللغز الذي لا يملكه أحد',
      'تأثير الفراشة',
      'مختبر المخلوقات',
      'مصنع الخيال',
      'العوالم المتوازية',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        250,
        scrollable: scrollable,
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('butterfly experience changes the story based on a choice', (tester) async {
    await openPortal(tester, 'تأثير الفراشة');

    expect(find.text('الفصل الأول: دقيقة واحدة'), findsOneWidget);
    expect(find.text('أثر اختيارك'), findsNothing);
    await tester.ensureVisible(find.text('تساعد شخصاً يحتاجك'));
    await tester.tap(find.text('تساعد شخصاً يحتاجك'));
    await tester.pumpAndSettle();

    expect(find.text('أثر اختيارك'), findsOneWidget);
    expect(find.textContaining('مخترعة غيّرت مستقبل المدينة.'), findsOneWidget);
    await tester.ensureVisible(find.text('جرّب اختياراً آخر'));
    await tester.tap(find.text('جرّب اختياراً آخر'));
    await tester.pumpAndSettle();
    expect(find.text('أثر اختيارك'), findsNothing);
  });

  testWidgets('portal opens a detail page and returns to the portal list', (tester) async {
    await openPortal(tester, 'اللغز الذي لا يملكه أحد');

    expect(find.text('المرحلة التأسيسية'), findsOneWidget);
    expect(
      find.text(
        'اكتشفوا الأدلة على مراحل، شاركوا النظريات، وصوّتوا على التفسير قبل كشف النتيجة.',
      ),
      findsOneWidget,
    );
    final backButton = find.text('العودة إلى العوالم');
    // The detail page uses a lazy ListView, so the button may not exist in
    // the widget tree until the detail route is scrolled far enough.
    await tester.scrollUntilVisible(
      backButton,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // The list restores its previous scroll offset; the app bar is a stable
    // assertion that navigation returned to the portal screen.
    expect(find.text('WONDERVERSE'), findsOneWidget);
    expect(find.text('العودة إلى العوالم'), findsNothing);
  });
}
