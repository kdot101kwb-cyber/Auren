import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../nova_ai/lib/features/debate/nova_debate_screen.dart';

void main() {
  testWidgets('NOVA debate screen presents Arabic-first review form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NovaDebateScreen()),
    );

    expect(find.text('مجلس النقاش الاستراتيجي'), findsOneWidget);
    expect(find.text('فكّر بوضوح. قرّر بثقة.'), findsOneWidget);
    expect(find.byKey(const Key('nova-debate-prompt')), findsOneWidget);
    expect(find.byKey(const Key('nova-debate-context')), findsOneWidget);
    expect(find.text('لن ينفّذ NOVA أي إجراء خارجي من هذه الشاشة.'), findsOneWidget);
  });

  testWidgets('review action becomes available when a plan is entered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NovaDebateScreen()),
    );

    final reviewButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'راجع الخطة واعترض عليها'),
    );
    expect(reviewButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('nova-debate-prompt')),
      'اختبر خطة لبناء مصدر دخل.',
    );
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'راجع الخطة واعترض عليها'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
