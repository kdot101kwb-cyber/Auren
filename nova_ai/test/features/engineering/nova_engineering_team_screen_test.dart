import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/features/engineering/nova_engineering_team_screen.dart';

void main() {
  testWidgets('engineering team screen lists departments', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaEngineeringTeamScreen()));

    expect(find.text('NOVA Engineering Core'), findsOneWidget);
    expect(find.text('مهندس Flutter والواجهة'), findsOneWidget);
    expect(find.text('مهندس الاختبارات والجودة'), findsOneWidget);
    expect(find.text('مراجع الكود'), findsOneWidget);
  });

  testWidgets('task planning displays assigned roles and approval gate', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaEngineeringTeamScreen()));

    await tester.enterText(
      find.byType(TextField),
      'Fix Flutter screen and Android APK build',
    );
    await tester.tap(find.text('وزّع المهمة على المهندسين'));
    await tester.pumpAndSettle();

    expect(find.text('خطة الفريق'), findsOneWidget);
    expect(find.text('مهندس Flutter والواجهة'), findsWidgets);
    expect(find.text('مهندس البناء والإصدار'), findsWidgets);
    expect(find.text('بوابة موافقة المالك'), findsOneWidget);
  });

  testWidgets('empty goal shows validation message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NovaEngineeringTeamScreen()));

    await tester.tap(find.text('وزّع المهمة على المهندسين'));
    await tester.pumpAndSettle();

    expect(find.text('اكتب المهمة التي تريد من NOVA التخطيط لها.'), findsOneWidget);
  });
}
