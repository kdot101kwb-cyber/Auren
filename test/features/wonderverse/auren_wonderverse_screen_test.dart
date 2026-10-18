import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/wonderverse/presentation/auren_wonderverse_screen.dart';

void main() {
  testWidgets('Wonderverse renders six experience portals', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenWonderverseScreen()));
    expect(find.text('WONDERVERSE'), findsOneWidget);
    expect(find.text('عوالم أُورِن'), findsOneWidget);
    expect(find.text('بوابات العوالم'), findsOneWidget);
    for (final title in ['حضارة في دقيقة', 'اللغز الذي لا يملكه أحد', 'تأثير الفراشة', 'مختبر المخلوقات', 'مصنع الخيال', 'العوالم المتوازية']) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('portal opens a detail page and returns to the portal list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AurenWonderverseScreen()));
    await tester.tap(find.text('اللغز الذي لا يملكه أحد'));
    await tester.pumpAndSettle();
    expect(find.text('المرحلة التأسيسية'), findsOneWidget);
    expect(find.text('المجتمع كله يجمع خيوط اللغز.'), findsOneWidget);
    await tester.tap(find.text('العودة إلى العوالم'));
    await tester.pumpAndSettle();
    expect(find.text('بوابات العوالم'), findsOneWidget);
  });
}
