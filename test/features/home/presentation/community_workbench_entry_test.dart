import 'package:auren/features/home/presentation/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('More exposes the Community & Collaboration workbench entry',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AurenMoreScreen()),
    );

    expect(find.text('Community & Collaboration'), findsOneWidget);
    expect(
      find.text('المشاريع الجماعية، حوكمة المجتمعات، واللقاءات المحلية.'),
      findsOneWidget,
    );
  });
}
