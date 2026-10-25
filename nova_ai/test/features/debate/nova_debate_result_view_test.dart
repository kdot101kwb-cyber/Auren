import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/debate/nova_debate_result_view.dart';

void main() {
  testWidgets('renders strategic objections, plan verification and execution disclaimer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NovaDebateResultView(result: {
          'summary': 'ابدأ بإصلاح صغير قابل للقياس',
          'recommendation': 'revise',
          'confidence': 0.8,
          'decisionRationale': 'الاختبارات أولاً تقلل المخاطر',
          'objections': [
            {
              'role': 'quality',
              'title': 'اختبار مفقود',
              'reason': 'لا يوجد دليل على نجاح الحالة',
              'severity': 'high',
              'mitigation': 'أضف اختباراً',
            },
          ],
          'alternatives': [
            {'name': 'إصلاح محدود', 'benefit': 'أسرع', 'cost': 'منخفض', 'risk': 'محدود'},
          ],
          'plan': [
            {'step': 'أضف الاختبار', 'reason': 'كشف الانحدار', 'verification': 'flutter test ينجح', 'estimatedEffort': '30 دقيقة'},
          ],
          'risks': [
            {'risk': 'انحدار', 'likelihood': 'متوسط', 'impact': 'عالٍ', 'mitigation': 'CI'},
          ],
          'missingEvidence': ['نتيجة CI النهائية'],
        }),
      ),
    ));

    expect(find.text('اعتراضات المجلس'), findsOneWidget);
    expect(find.text('اختبار مفقود'), findsOneWidget);
    expect(find.text('خطة العمل ومعايير التحقق'), findsOneWidget);
    expect(find.textContaining('flutter test ينجح'), findsOneWidget);
    final missingEvidenceTitle = find.text('الأدلة الناقصة');
    await tester.ensureVisible(missingEvidenceTitle);
    expect(missingEvidenceTitle, findsOneWidget);
    expect(find.textContaining('لم يُنفّذ أي تغيير'), findsOneWidget);
  });

  testWidgets('handles sparse model output without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NovaDebateResultView(result: {})),
    ));
    expect(find.textContaining('غير مذكور'), findsWidgets);
    expect(find.textContaining('لم يُنفّذ أي تغيير'), findsOneWidget);
  });
}
