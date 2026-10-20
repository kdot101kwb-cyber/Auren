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
  final field = find.byKey(ValueKey<String>(label), skipOffstage: false);
  await _scrollToBuilt(tester, field);
  expect(field, findsOneWidget, reason: 'Field label: $label');
  // enterText handles bringing an off-screen editable field into view.
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
  final scrollView = tester.widget<SingleChildScrollView>(listFinder);
  final controller = scrollView.controller!;
  await tester.pump();

  // First move to an end so lazy scroll children can be built if necessary.
  if (target.evaluate().isEmpty) {
    controller.jumpTo(
      towardTop ? 0.0 : controller.position.maxScrollExtent,
    );
    await tester.pump();
  }
  if (target.evaluate().isEmpty) return;

  // Position the target using geometry and jumpTo. Avoid ensureVisible and
  // animated scrolling, which can deadlock or throw when finders are not
  // unique and are unnecessary for widget-test setup.
  final targetRect = tester.getRect(target.first);
  final viewportRect = tester.getRect(listFinder);
  double delta = 0;
  if (targetRect.bottom > viewportRect.bottom) {
    delta = targetRect.bottom - viewportRect.bottom;
  } else if (targetRect.top < viewportRect.top) {
    delta = targetRect.top - viewportRect.top;
  }
  if (delta != 0) {
    final nextOffset = (controller.offset + delta)
        .clamp(0.0, controller.position.maxScrollExtent)
        .toDouble();
    controller.jumpTo(nextOffset);
    await tester.pump();
  }
}

Future<void> _expectInvalid(WidgetTester tester) async {
  final calculate = find.text('Calculate manufacturing plan');
  await _scrollToBuilt(tester, calculate);
  await tester.tap(calculate);
  await tester.pump();
  // Several invalid fields can display the same validation message.
  // Avoid ensureVisible on a non-unique text finder.
  expect(find.text('Enter a valid number'), findsWidgets);
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
        label: 'Selling price per product unit',
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
        label: 'Selling price per product unit',
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

    testWidgets('prepopulates names for the default manufacturing route',
        (tester) async {
      await tester.pumpWidget(_app());
      final rawFinder = find.byKey(const ValueKey<String>('Raw material name'));
      final productFinder = find.byKey(const ValueKey<String>('Finished product name'));
      await _scrollToBuilt(tester, rawFinder, towardTop: true);
      await _scrollToBuilt(tester, productFinder, towardTop: true);
      expect(tester.widget<TextFormField>(rawFinder).controller?.text, 'Cotton');
      expect(
        tester.widget<TextFormField>(productFinder).controller?.text,
        'cotton garments',
      );
    });

    testWidgets('prepopulates default route names in Arabic', (tester) async {
      await tester.pumpWidget(_app(locale: const Locale('ar')));
      final rawFinder = find.byKey(const ValueKey<String>('اسم المادة الخام'));
      final productFinder = find.byKey(const ValueKey<String>('اسم المنتج النهائي'));
      await _scrollToBuilt(tester, rawFinder, towardTop: true);
      await _scrollToBuilt(tester, productFinder, towardTop: true);
      expect(tester.widget<TextFormField>(rawFinder).controller?.text, 'القطن');
      expect(
        tester.widget<TextFormField>(productFinder).controller?.text,
        'الملابس القطنية',
      );
    });

    testWidgets('shows an estimate for valid default inputs', (tester) async {
      await tester.pumpWidget(_app());
      await _scrollToBuilt(tester, find.text('Estimated result'));
      expect(find.text('Estimated result'), findsOneWidget);
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });
}
