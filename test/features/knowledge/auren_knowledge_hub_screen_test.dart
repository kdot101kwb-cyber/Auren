import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/knowledge/presentation/auren_knowledge_hub_screen.dart';

void main() {
  testWidgets('Knowledge Hub shows distinct learning domains', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenKnowledgeHubScreen()),
    );

    expect(find.text('AUREN Knowledge Hub'), findsOneWidget);
    expect(find.text('Science & Technology'), findsOneWidget);
    expect(find.text('Business & Economics'), findsOneWidget);
    expect(find.text('History & Society'), findsOneWidget);
    expect(find.text('Practical Skills'), findsOneWidget);
    expect(find.text('Sudan & Africa'), findsOneWidget);
  });
}
