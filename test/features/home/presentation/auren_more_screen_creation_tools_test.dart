import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/home/presentation/more_screen.dart';

void main() {
  group('AurenMoreScreen creation and production entries', () {
    testWidgets('exposes the distinct creation tools and retains Creator Studio', (tester) async {
      // Give the ListView enough viewport height for its lazy children to build.
      tester.view.physicalSize = const Size(800, 12000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: AurenMoreScreen()));

      expect(find.text('AUREN Audio Workshop'), findsOneWidget);
      expect(find.text('AUREN Visual Creator'), findsOneWidget);
      expect(find.text('AUREN Creative Projects'), findsOneWidget);
      expect(find.text('AUREN Document Studio'), findsOneWidget);
      expect(find.text('Creator Studio'), findsOneWidget);
    });
  });
}
