import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/debate/nova_debate_screen.dart';

void main() {
  testWidgets('strategic debate screen explains policy and exposes review controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaDebateScreen()));

    expect(find.text('مجلس النقاش الاستراتيجي'), findsOneWidget);
    expect(find.text('NOVA لا يوافق تلقائياً'), findsOneWidget);
    expect(find.text('الخطة أو القرار'), findsOneWidget);
    expect(find.text('السياق والأدلة (اختياري)'), findsOneWidget);
    expect(find.text('ناقش الخطة واعترض عليها'), findsOneWidget);
    expect(find.textContaining('ليست أربعة نماذج مستقلة'), findsOneWidget);
  });
}
