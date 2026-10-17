import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/auren_raw_to_product_screen.dart';

Widget _app({Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AurenRawToProductScreen(),
    );

Future<void> _enterField(
  WidgetTester tester, {
  required String label,
  required String value,
}) async {
  final field = find.byKey(ValueKey<String>(label));
  await _scrollToBuilt(tester, field);
  expect(field, findsOneWidget, reason: 'Field label: $label');
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _scrollToBuilt(
  WidgetTester tester,
  Finder target, {
  bool towardTop = false,
}) async {
  final listFinder = find.byKey(
    const ValueKey<String>('raw-to-product-form-list'),
  );
  final list = tester.widget<ListView>(listFinder);
  final controller = list.controller;
  expect(controller, isNotNull, reason: 'The form must expose its scroll controller');
  await tester.pumpAndSettle();

  for (var attempt = 0; attempt < 30 && target.evaluate().isEmpty; attempt++) {
    final position = controller!.position;
    final current = position.pixels;
    final step = (position.viewportDimension * 0.7).clamp(200.0, 500.0);
    final next = towardTop
        ? (current - step).clamp(0.0, position.maxScrollExtent)
        : (current + step).clamp(0.0, position.maxScrollExtent);
    if (next == current) break;
    controller.jumpTo(next);
    await tester.pumpAndSettle();
  }
}

Future<void> _expectInvalid(WidgetTester tester) async {
  await _scrollToBuilt(tester, find.text('Enter a valid number'));
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
      await _scrollToBuilt(tester, find.text('Estimated result'));
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
      await _scrollToBuilt(tester, selector);
      expect(selector, findsOneWidget);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sesame → tahini').last);
      await tester.pumpAndSettle();

      final rawFinder = find.byKey(const ValueKey<String>('Raw material name'));
      final productFinder = find.byKey(const ValueKey<String>('Finished product name'));
      await _scrollToBuilt(tester, rawFinder, towardTop: true);
      await _scrollToBuilt(tester, productFinder, towardTop: true);
      final rawField = tester.widget<TextFormField>(rawFinder);
      final productField = tester.widget<TextFormField>(productFinder);
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
      await _scrollToBuilt(tester, calculate);
      expect(calculate, findsOneWidget);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      // Validation text belongs to the yield field; bring it back into the
      // built viewport before asserting against the lazy ListView child.
      await _scrollToBuilt(
        tester,
        find.byKey(const ValueKey<String>('نسبة التحويل إلى منتج صالح (%)')),
        towardTop: true,
      );
      expect(find.text('القيمة يجب ألا تزيد عن 100.0'), findsOneWidget);
      expect(find.text('النتيجة التقديرية'), findsNothing);
    });

    testWidgets('shows an estimate for valid default inputs', (tester) async {
      await tester.pumpWidget(_app());
      await _scrollToBuilt(tester, find.text('Estimated result'));
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
