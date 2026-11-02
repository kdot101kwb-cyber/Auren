import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/games/nova_agent_games_screen.dart';

void main() {
  testWidgets('shows the AI game agent setup and honest reward status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NovaAgentGamesScreen())),
    );

    expect(find.text('NOVA — وكيل الألعاب الذكي'), findsOneWidget);
    expect(find.text('HaloArena'), findsOneWidget);
    expect(find.text('الأرباح: غير مثبتة'), findsOneWidget);
    expect(find.text('تشغيل الوكيل: غير مفعّل بعد'), findsOneWidget);
    expect(find.text('نسخ تعليمات الوكيل'), findsOneWidget);
  });
}
