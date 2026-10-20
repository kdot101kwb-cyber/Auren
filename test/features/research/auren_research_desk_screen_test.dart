import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/research/presentation/auren_research_desk_screen.dart';

void main() {
  testWidgets('Research Desk exposes the five focused research tools', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenResearchDeskScreen()),
    );

    expect(find.text('AUREN Research Desk'), findsOneWidget);
    expect(find.text('Research Brief'), findsOneWidget);
    expect(find.text('Compare Sources'), findsOneWidget);
    expect(find.text('Claim Check'), findsOneWidget);
    expect(find.text('Language Bridge'), findsOneWidget);
    expect(find.text('Citation Planner'), findsOneWidget);
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
