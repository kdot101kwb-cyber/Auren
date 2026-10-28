import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_ai/features/comedy/nova_comedy_studio_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('saves bilingual original content as a local draft', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaComedyStudioScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'لما تقول خمس دقائق وتختفي ساعة');
    await tester.enterText(find.byType(TextField).at(1), 'When you say five minutes and vanish for an hour');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('nova.comedy_studio.queue.v1');
    expect(raw, isNotNull);
    final queue = jsonDecode(raw!) as List<dynamic>;
    expect(queue, hasLength(1));
    expect(queue.first['arabicText'], contains('خمس دقائق'));
    expect(queue.first['englishText'], contains('five minutes'));
    expect(queue.first['status'], 'draft');
    expect(queue.first['publishingState'], 'not_connected');
    expect(find.text('لم يتم نشر أي شيء.', skipOffstage: true), findsNothing);
  });

  testWidgets('does not claim a Facebook page is connected or publish automatically', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaComedyStudioScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('لم يتم إنشاء صفحة فيسبوك'), findsOneWidget);
    await tester.tap(find.text('طلب النشر التلقائي'));
    await tester.pumpAndSettle();
    expect(find.textContaining('النشر التلقائي مقفول'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nova.comedy_studio.queue.v1'), isNull);
  });
}
