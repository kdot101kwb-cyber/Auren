import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/research/presentation/auren_research_desk_screen.dart';

void main() {
  testWidgets('Research Desk exposes the five focused research tools', (tester) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AurenResearchDeskScreen()),
    );

    expect(find.text('AUREN Research Desk'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    for (final tool in [
      'Research Brief',
      'Compare Sources',
      'Claim Check',
      'Language Bridge',
      'Citation Planner',
    ]) {
      expect(find.text(tool), findsOneWidget);
    }
  });

  testWidgets('Research Desk explains source verification limits', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenResearchDeskScreen()),
    );

    expect(
      find.textContaining('لا يُعد الملخص وحده دليلاً على صحة المعلومة'),
      findsOneWidget,
    );
  });
}
