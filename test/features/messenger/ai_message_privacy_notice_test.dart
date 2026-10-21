import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/messenger/presentation/ai_message_privacy_notice.dart';

void main() {
  testWidgets('discloses remote storage and AI processing in Arabic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [AiMessagePrivacyNotice()],
          ),
        ),
      ),
    );

    expect(find.textContaining('تُحفظ رسائلك في محادثات AUREN'), findsOneWidget);
    expect(find.textContaining('خدمة الذكاء الاصطناعي'), findsOneWidget);
    expect(find.textContaining('معلومات طبية أو شخصية حساسة'), findsOneWidget);
    expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
  });

  testWidgets('notice remains readable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [AiMessagePrivacyNotice()],
          ),
        ),
      ),
    );

    expect(find.textContaining('تنبيه الخصوصية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
