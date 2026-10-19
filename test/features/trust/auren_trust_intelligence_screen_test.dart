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
      expect(find.text('Safer opportunities and commerce'), findsOneWidget);
    });

    testWidgets('does not present an unvalidated public trust score',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AurenTrustIntelligenceScreen()),
      );

      expect(
        find.textContaining('No public trust score is shown in this initial release.'),
        findsOneWidget,
      );
    });
  });
}
