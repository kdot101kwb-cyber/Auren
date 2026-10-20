import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/language_bridge/presentation/auren_language_bridge_screen.dart';

void main() {
  testWidgets('Language Bridge provides source, target, and text inputs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenLanguageBridgeScreen()),
    );

    expect(find.text('AUREN Language Bridge'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('افهم وترجم'), findsOneWidget);
  });

  testWidgets('Language Bridge asks for text before continuing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenLanguageBridgeScreen()),
    );

    await tester.tap(find.text('افهم وترجم'));
    await tester.pump();

    expect(find.text('أدخل النص أو المصطلح أولاً.'), findsOneWidget);
  });
}
