import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/home/presentation/more_screen.dart';

void main() {
  group('AurenMoreScreen creation and production entries', () {
    testWidgets('exposes the distinct creation tools without replacing existing studio', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AurenMoreScreen()));

      expect(find.byType(ListView), findsOneWidget);
      final list = find.byType(ListView).first;
      for (var i = 0; i < 8; i++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('AUREN Audio Workshop'), findsOneWidget);
      expect(find.text('AUREN Visual Creator'), findsOneWidget);
      expect(find.text('AUREN Creative Projects'), findsOneWidget);
      expect(find.text('AUREN Document Studio'), findsOneWidget);

      await tester.drag(list, const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.text('Creator Studio'), findsOneWidget);
    });
  });
}
