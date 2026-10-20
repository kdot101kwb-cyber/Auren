import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/home/presentation/more_screen.dart';

void main() {
  group('AurenMoreScreen creation and production entries', () {
    testWidgets('exposes the distinct creation tools without replacing existing studio', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AurenMoreScreen()));

      final scrollable = find.byType(Scrollable).first;
      for (final title in [
        'AUREN Audio Workshop',
        'AUREN Visual Creator',
        'AUREN Creative Projects',
        'AUREN Document Studio',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          300,
          scrollable: scrollable,
        );
        expect(find.text(title), findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.text('Creator Studio'),
        300,
        scrollable: scrollable,
      );
      expect(find.text('Creator Studio'), findsOneWidget);
    });
  });
}
