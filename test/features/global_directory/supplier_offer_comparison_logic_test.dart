import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/domain/supplier_offer_comparison_logic.dart';

void main() {
  group('SupplierOfferComparisonLogic.parseNonNegativeAmount', () {
    test('accepts plain and correctly grouped decimal amounts', () {
      expect(SupplierOfferComparisonLogic.parseNonNegativeAmount('0'), 0);
      expect(SupplierOfferComparisonLogic.parseNonNegativeAmount(' 12.50 '), 12.5);
      expect(SupplierOfferComparisonLogic.parseNonNegativeAmount('1,234.56'), 1234.56);
      expect(SupplierOfferComparisonLogic.parseNonNegativeAmount('123456'), 123456);
    });

    test('rejects malformed grouping, signs, and non-finite values', () {
      for (final value in [
        '',
        '-1',
        '+1',
        '1,,2',
        '12,34',
        '1,23,456',
        '1.',
        '.5',
        '1e3',
        'NaN',
        'Infinity',
        '1 000',
      ]) {
        expect(
          SupplierOfferComparisonLogic.parseNonNegativeAmount(value),
          isNull,
          reason: 'Expected "$value" to be rejected',
        );
      }
    });

    test('rejects values that overflow a finite double', () {
      expect(
        SupplierOfferComparisonLogic.parseNonNegativeAmount(
          '1' + List.filled(309, '0').join(),
        ),
        isNull,
      );
    });
  });

  group('SupplierOfferComparisonLogic.total', () {
    test('adds price and shipping only when both are valid', () {
      expect(SupplierOfferComparisonLogic.total('100', '25.50'), 125.5);
      expect(SupplierOfferComparisonLogic.total('1,000', '0'), 1000);
      expect(SupplierOfferComparisonLogic.total('100', ''), isNull);
      expect(SupplierOfferComparisonLogic.total('bad', '10'), isNull);
    });

    test('rejects a non-finite sum', () {
      expect(
        SupplierOfferComparisonLogic.total(
          '170' + List.filled(306, '0').join(),
          '170' + List.filled(306, '0').join(),
        ),
        isNull,
      );
    });
  });

  group('SupplierOfferComparisonLogic.isLowest', () {
    test('compares totals only in the same currency', () {
      final offers = [
        {'currency': 'USD', 'price': '100', 'shipping': '20'},
        {'currency': 'USD', 'price': '110', 'shipping': '0'},
        {'currency': 'EUR', 'price': '1', 'shipping': '0'},
      ];

      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'USD',
          price: '110',
          shipping: '0',
          offers: offers,
        ),
        isTrue,
      );
      // 100 + 20 is not the lowest USD total because 110 + 0 is cheaper.
      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'USD',
          price: '100',
          shipping: '20',
          offers: offers,
        ),
        isFalse,
      );
      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'EUR',
          price: '1',
          shipping: '0',
          offers: offers,
        ),
        isTrue,
      );
    });

    test('does not rank invalid candidate amounts and ignores invalid peers', () {
      final offers = [
        {'currency': 'USD', 'price': 'bad', 'shipping': '0'},
        {'currency': 'USD', 'price': '50', 'shipping': '5'},
      ];
      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'USD',
          price: 'bad',
          shipping: '0',
          offers: offers,
        ),
        isFalse,
      );
      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'USD',
          price: '50',
          shipping: '5',
          offers: offers,
        ),
        isTrue,
      );
    });

    test('returns false when there is no comparable offer', () {
      expect(
        SupplierOfferComparisonLogic.isLowest(
          currency: 'USD',
          price: '10',
          shipping: '0',
          offers: const [
            {'currency': 'EUR', 'price': '1', 'shipping': '0'},
          ],
        ),
        isFalse,
      );
    });
  });

  group('SupplierOfferComparisonLogic quote validity dates', () {
    test('parses only real ISO calendar dates', () {
      expect(
        SupplierOfferComparisonLogic.parseIsoValidityDate('2028-02-29'),
        DateTime.utc(2028, 2, 29),
      );
      expect(
        SupplierOfferComparisonLogic.parseIsoValidityDate(' 2026-10-11 '),
        DateTime.utc(2026, 10, 11),
      );
      for (final value in [
        '',
        'valid for 30 days',
        '11/10/2026',
        '2026-2-03',
        '2026-02-30',
        '2025-02-29',
        '2026-13-01',
      ]) {
        expect(
          SupplierOfferComparisonLogic.parseIsoValidityDate(value),
          isNull,
          reason: 'Expected "$value" to be treated as unparsed validity text',
        );
      }
    });

    test('classifies expired, today, soon, valid and unknown dates', () {
      final today = DateTime(2026, 10, 11, 23, 45);
      expect(SupplierOfferComparisonLogic.validityCategory('2026-10-10', today: today), 'expired');
      expect(SupplierOfferComparisonLogic.validityCategory('2026-10-11', today: today), 'today');
      expect(SupplierOfferComparisonLogic.validityCategory('2026-10-18', today: today), 'soon');
      expect(SupplierOfferComparisonLogic.validityCategory('2026-10-19', today: today), 'valid');
      expect(SupplierOfferComparisonLogic.validityCategory('valid for 30 days', today: today), 'unknown');
      expect(SupplierOfferComparisonLogic.validityCategory('2026-02-30', today: today), 'unknown');
    });

    test('calculates calendar days to expiry without using elapsed hours', () {
      final today = DateTime(2026, 10, 11, 23, 45);
      expect(
        SupplierOfferComparisonLogic.daysUntilValidity('2026-10-10', today: today),
        -1,
      );
      expect(
        SupplierOfferComparisonLogic.daysUntilValidity('2026-10-11', today: today),
        0,
      );
      expect(
        SupplierOfferComparisonLogic.daysUntilValidity('2026-10-18', today: today),
        7,
      );
      expect(
        SupplierOfferComparisonLogic.daysUntilValidity('2026-10-19', today: today),
        8,
      );
      expect(
        SupplierOfferComparisonLogic.daysUntilValidity('valid for 30 days', today: today),
        isNull,
      );
    });
  });

  group('SupplierOfferComparisonLogic.compare', () {
    int compare({
      required String aCurrency,
      required String aSupplier,
      required String aPrice,
      required String aShipping,
      required String bCurrency,
      required String bSupplier,
      required String bPrice,
      required String bShipping,
    }) =>
        SupplierOfferComparisonLogic.compare(
          aCurrency: aCurrency,
          aSupplier: aSupplier,
          aPrice: aPrice,
          aShipping: aShipping,
          bCurrency: bCurrency,
          bSupplier: bSupplier,
          bPrice: bPrice,
          bShipping: bShipping,
        );

    test('groups currencies before comparing numeric totals', () {
      expect(
        compare(
          aCurrency: 'EUR',
          aSupplier: 'A',
          aPrice: '1',
          aShipping: '0',
          bCurrency: 'USD',
          bSupplier: 'B',
          bPrice: '999',
          bShipping: '0',
        ),
        lessThan(0),
      );
      expect(
        compare(
          aCurrency: 'USD',
          aSupplier: 'A',
          aPrice: '80',
          aShipping: '10',
          bCurrency: 'USD',
          bSupplier: 'B',
          bPrice: '100',
          bShipping: '0',
        ),
        lessThan(0),
      );
    });

    test('uses supplier name as a deterministic tie-breaker for equal totals', () {
      expect(
        compare(
          aCurrency: 'USD',
          aSupplier: 'Zulu Supplies',
          aPrice: '80',
          aShipping: '20',
          bCurrency: 'USD',
          bSupplier: 'Alpha Textiles',
          bPrice: '90',
          bShipping: '10',
        ),
        greaterThan(0),
      );
    });

    test('places invalid totals last and sorts invalid peers by supplier', () {
      expect(
        compare(
          aCurrency: 'USD',
          aSupplier: 'Z',
          aPrice: 'bad',
          aShipping: '0',
          bCurrency: 'USD',
          bSupplier: 'A',
          bPrice: '10',
          bShipping: '0',
        ),
        greaterThan(0),
      );
      expect(
        compare(
          aCurrency: 'USD',
          aSupplier: 'Alpha',
          aPrice: 'bad',
          aShipping: '0',
          bCurrency: 'USD',
          bSupplier: 'Zulu',
          bPrice: 'bad',
          bShipping: '0',
        ),
        lessThan(0),
      );
    });
  });

  group('SupplierOfferComparisonLogic CSV export', () {
    test('quotes every cell and escapes commas, quotes and newlines', () {
      expect(SupplierOfferComparisonLogic.csvCell('Acme, Ltd'), '"Acme, Ltd"');
      expect(SupplierOfferComparisonLogic.csvCell('He said "yes"'), '"He said ""yes"""');
      expect(SupplierOfferComparisonLogic.csvCell('line 1\\nline 2'), '"line 1\\nline 2"');
      expect(SupplierOfferComparisonLogic.csvRow(['supplier', 'price']), '"supplier","price"');
    });

    test('neutralizes spreadsheet formula prefixes including leading whitespace', () {
      for (final value in ['=1+1', '+SUM(A1:A2)', '-cmd', '@SUM(A1)', '  =1+1', '\\t=1+1']) {
        expect(
          SupplierOfferComparisonLogic.csvCell(value),
          '"' + "'$value" + '"',
          reason: 'CSV formula-like cell should be treated as text: $value',
        );
      }
      expect(SupplierOfferComparisonLogic.csvCell('123.45'), '"123.45"');
      expect(SupplierOfferComparisonLogic.csvCell('Normal supplier'), '"Normal supplier"');
    });
  });
}
