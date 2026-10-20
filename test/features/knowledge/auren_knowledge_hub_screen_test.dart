import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/knowledge/presentation/auren_knowledge_hub_screen.dart';

void main() {
  testWidgets('Knowledge Hub shows distinct learning domains', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(find.text(domain), findsOneWidget);
    }
  });
}
