import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/auren_raw_to_product_screen.dart';

Widget _app() => const MaterialApp(
      locale: Locale('en'),
      supportedLocales: [Locale('en'), Locale('ar')],
      home: AurenRawToProductScreen(),
    );

void main() {
  group('AurenRawToProductScreen input validation', () {
    testWidgets('shows no estimate for malformed numeric input', (tester) async {
      await tester.pumpWidget(_app());

      await tester.enterText(find.byType(TextFormField).at(2), '12abc');
      await tester.pump();

      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(find.text('Estimated result'), findsNothing);
    });

    testWidgets('shows no estimate when raw quantity is zero', (tester) async {
      await tester.pumpWidget(_app());

      await tester.enterText(find.byType(TextFormField).at(2), '0');
      await tester.pump();

      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(find.text('Estimated result'), findsNothing);
    });

    testWidgets('shows no estimate when yield exceeds one hundred percent',
        (tester) async {
      await tester.pumpWidget(_app());

      await tester.enterText(find.byType(TextFormField).at(3), '100.01');
      await tester.pump();

      expect(find.text('Enter a valid number'), findsOneWidget);
      expect(find.text('Estimated result'), findsNothing);
    });

    testWidgets('keeps a valid estimate visible for valid inputs',
        (tester) async {
      await tester.pumpWidget(_app());

      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
