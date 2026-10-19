import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/trust/presentation/auren_trust_intelligence_screen.dart';

void main() {
  group('AurenTrustIntelligenceScreen', () {
    testWidgets('explains evidence-aware trust and existing safety tools',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AurenTrustIntelligenceScreen()),
      );

      expect(find.text('AUREN Trust Intelligence'), findsOneWidget);
      expect(find.text('Evidence-aware verification'), findsOneWidget);
      expect(find.text('Report suspicious activity'), findsOneWidget);
      expect(find.text('Personal safety controls'), findsOneWidget);

      final saferCommerce = find.text('Safer opportunities and commerce');
      await tester.scrollUntilVisible(
        saferCommerce,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(saferCommerce, findsOneWidget);
    });

    testWidgets('explains how to interpret claims, evidence, and reports',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AurenTrustIntelligenceScreen()),
      );

      final guidance = find.text('How to read trust signals');
      await tester.scrollUntilVisible(
        guidance,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(guidance);
      await tester.pumpAndSettle();

      expect(find.text('Read trust signals carefully'), findsOneWidget);
      expect(
        find.textContaining('Reports are unverified until reviewed.'),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('does not present an unvalidated public trust score',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AurenTrustIntelligenceScreen()),
      );

      final noPublicScore = find.textContaining(
        'No public trust score is shown in this initial release.',
      );
      await tester.scrollUntilVisible(
        noPublicScore,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(noPublicScore, findsOneWidget);
    });
  });
}
