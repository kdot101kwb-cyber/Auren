import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/knowledge/presentation/auren_knowledge_hub_screen.dart';

void main() {
  testWidgets('Knowledge Hub shows distinct learning domains', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenKnowledgeHubScreen()),
    );

    expect(find.text('AUREN Knowledge Hub'), findsOneWidget);
    for (final domain in [
      'Science & Technology',
      'Business & Economics',
      'History & Society',
      'Practical Skills',
      'Sudan & Africa',
    ]) {
      await tester.scrollUntilVisible(
        find.text(domain),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(domain), findsOneWidget);
    }
  });
}
