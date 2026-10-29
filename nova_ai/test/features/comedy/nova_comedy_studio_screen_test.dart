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
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
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
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
    await tester.pumpAndSettle();

    expect(find.textContaining('لم يتم إنشاء صفحة فيسبوك'), findsOneWidget);
    await tester.tap(find.text('طلب النشر التلقائي'));
    await tester.pumpAndSettle();
    expect(find.textContaining('النشر التلقائي مقفول'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nova.comedy_studio.queue.v1'), isNull);
  });
  testWidgets('selects and persists the chosen brand ID', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('AI After Dark').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('AI After Dark').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'A real AI tip');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final queue = jsonDecode(prefs.getString('nova.comedy_studio.queue.v1')!) as List<dynamic>;
    expect(queue.single['brand'], 'ai_after_dark');
  });
  testWidgets('records and persists observed content results', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Original AI tip');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل النتائج الفعلية'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'YouTube Shorts');
    await tester.enterText(find.byType(TextFormField).at(1), '1250');
    await tester.enterText(find.byType(TextFormField).at(2), '84');
    await tester.enterText(find.byType(TextFormField).at(3), '47.5');
    await tester.enterText(find.byType(TextFormField).at(4), '2.25');
    await tester.tap(find.text('حفظ النتائج'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final queue = jsonDecode(prefs.getString('nova.comedy_studio.queue.v1')!) as List<dynamic>;
    expect(queue.single['platform'], 'YouTube Shorts');
    expect(queue.single['views'], 1250);
    expect(queue.single['engagements'], 84);
    expect(queue.single['retentionPercent'], 47.5);
    expect(queue.single['revenueUsd'], 2.25);
  });

  testWidgets('rejects retention percentages outside zero to one hundred', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Draft');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل النتائج الفعلية'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(3), '140');
    await tester.tap(find.text('حفظ النتائج'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل نسبة بين 0 و100'), findsOneWidget);
  });


  testWidgets('filters the queue to the selected brand without losing other drafts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NovaComedyStudioScreen())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'LOL only phrase');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('AI After Dark').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'AI only phrase');
    await tester.tap(find.text('حفظ المسودة محلياً'));
    await tester.pumpAndSettle();

    expect(find.text('LOL only phrase'), findsOneWidget);
    expect(find.text('AI only phrase'), findsOneWidget);

    await tester.tap(find.text('تصفية حسب العلامة'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('AI After Dark').last);
    await tester.pumpAndSettle();

    expect(find.text('AI only phrase'), findsOneWidget);
    expect(find.text('LOL only phrase'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final queue = jsonDecode(prefs.getString('nova.comedy_studio.queue.v1')!) as List<dynamic>;
    expect(queue, hasLength(2));
  });

}
