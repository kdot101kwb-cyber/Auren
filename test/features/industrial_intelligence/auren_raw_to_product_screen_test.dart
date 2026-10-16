import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/auren_raw_to_product_screen.dart';

Widget _app() => const MaterialApp(
      locale: Locale('en'),
      supportedLocales: [Locale('en'), Locale('ar')],
      home: AurenRawToProductScreen(),
    );

Future<void> _enterField(
  WidgetTester tester, {
  required String label,
  required String value,
}) async {
  final field = find.byKey(ValueKey<String>(label));
  expect(field, findsOneWidget, reason: 'Field label: $label');
  await tester.scrollUntilVisible(
    field,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _expectInvalid(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Enter a valid number'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  expect(find.text('Enter a valid number'), findsOneWidget);
  expect(find.text('Estimated result'), findsNothing);
}

void main() {
  group('AurenRawToProductScreen input validation', () {
    testWidgets('hides estimate for malformed numeric input', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Raw material quantity',
        value: '12abc',
      );
      await _expectInvalid(tester);
    });

    testWidgets('hides estimate when raw quantity is zero', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Raw material quantity',
        value: '0',
      );
      await _expectInvalid(tester);
    });

    testWidgets('hides estimate when yield exceeds one hundred percent',
        (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Usable product yield (%)',
        value: '100.01',
      );
      await _expectInvalid(tester);
    });

    testWidgets('hides estimate when a cost is negative', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Processing per raw unit',
        value: '-0.01',
      );
      await _expectInvalid(tester);
    });

    testWidgets('hides estimate when selling price is malformed', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Selling price per product',
        value: '3.2oops',
      );
      await _expectInvalid(tester);
    });

    testWidgets('allows zero yield and displays zero output safely', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Usable product yield (%)',
        value: '0',
      );
      await tester.scrollUntilVisible(
        find.text('Estimated result'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('0.00'), findsWidgets);
      expect(find.text('Unavailable because there is no usable output'), findsOneWidget);
    });

    testWidgets('shows an estimate for valid default inputs', (tester) async {
      await tester.pumpWidget(_app());
      await tester.scrollUntilVisible(
        find.text('Estimated result'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
