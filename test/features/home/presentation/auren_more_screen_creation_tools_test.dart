import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/home/presentation/more_screen.dart';

void main() {
  group('AurenMoreScreen creation and production entries', () {
    testWidgets('exposes the distinct creation tools without replacing existing studio', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AurenMoreScreen()));

      expect(find.text('Creator Studio'), findsOneWidget);
      expect(find.text('AUREN Document Studio'), findsOneWidget);
      expect(find.text('AUREN Visual Creator'), findsOneWidget);
      expect(find.text('AUREN Audio Workshop'), findsOneWidget);
      expect(find.text('AUREN Creative Projects'), findsOneWidget);
    });
  });
}
