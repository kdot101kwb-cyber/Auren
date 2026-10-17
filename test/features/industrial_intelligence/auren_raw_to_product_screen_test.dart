import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/auren_raw_to_product_screen.dart';

Widget _app({Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const AurenRawToProductScreen(),
    );

Finder _formScrollable() => find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    ).first;

Future<void> _enterField(
  WidgetTester tester, {
  required String label,
  required String value,
}) async {
  final field = find.byKey(ValueKey<String>(label));
  final scrollable = _formScrollable();

  // Ask the test framework to advance the actual form list until the lazy
  // child is built; other scrollables may belong to dropdown overlays.
  await tester.scrollUntilVisible(
    field,
    250,
    scrollable: scrollable,
  );
  expect(field, findsOneWidget, reason: 'Field label: $label');
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _expectInvalid(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Enter a valid number'),
    250,
    scrollable: _formScrollable(),
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

    testWidgets('hides estimate when a required numeric input is empty', (tester) async {
      await tester.pumpWidget(_app());
      await _enterField(
        tester,
        label: 'Selling price per product',
        value: '',
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
        scrollable: find.byType(ListView).first,
      );
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('0.00'), findsWidgets);
      expect(find.text('Unavailable because there is no usable output'), findsOneWidget);
    });

    testWidgets('selecting a route fills its raw and finished product names',
        (tester) async {
      await tester.pumpWidget(_app());
      final selector = find.byKey(
        const ValueKey<String>('manufacturing-route-selector'),
      );
      final scrollable = _formScrollable();
      for (var attempt = 0; attempt < 24 && selector.evaluate().isEmpty; attempt++) {
        await tester.drag(scrollable, const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(selector, findsOneWidget);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sesame → tahini').last);
      await tester.pumpAndSettle();

      final rawField = tester.widget<TextFormField>(
        find.byKey(const ValueKey<String>('Raw material name')),
      );
      final productField = tester.widget<TextFormField>(
        find.byKey(const ValueKey<String>('Finished product name')),
      );
      expect(rawField.controller?.text, 'Sesame');
      expect(productField.controller?.text, 'tahini');
    });

    testWidgets('Arabic digits are validated with Arabic error messages',
        (tester) async {
      await tester.pumpWidget(_app(locale: const Locale('ar')));
      await _enterField(
        tester,
        label: 'نسبة التحويل إلى منتج صالح (%)',
        value: '١٠٠٫٠١',
      );
      final calculate = find.text('احسب خطة التصنيع');
      final scrollable = find.byType(ListView).first;
      for (var attempt = 0; attempt < 24 && calculate.evaluate().isEmpty; attempt++) {
        await tester.drag(scrollable, const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(calculate, findsOneWidget);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.text('القيمة يجب ألا تزيد عن 100'), findsOneWidget);
      expect(find.text('النتيجة التقديرية'), findsNothing);
    });

    testWidgets('shows an estimate for valid default inputs', (tester) async {
      await tester.pumpWidget(_app());
      await tester.scrollUntilVisible(
        find.text('Estimated result'),
        250,
        scrollable: find.byType(ListView).first,
      );
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
