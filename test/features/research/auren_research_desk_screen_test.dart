import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/research/presentation/auren_research_desk_screen.dart';

void main() {
  testWidgets('Research Desk exposes the five focused research tools', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenResearchDeskScreen()),
    );

    expect(find.text('AUREN Research Desk'), findsOneWidget);
    for (final tool in [
      'Research Brief',
      'Compare Sources',
      'Claim Check',
      'Language Bridge',
      'Citation Planner',
    ]) {
      await tester.scrollUntilVisible(
        find.text(tool),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(tool), findsOneWidget);
    }
    expect(find.byType(TextField), findsOneWidget);
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
