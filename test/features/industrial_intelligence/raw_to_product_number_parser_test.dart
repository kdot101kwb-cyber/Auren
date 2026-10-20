import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_number_parser.dart';

void main() {
  group('RawToProductNumberParser.parse', () {
    test('parses Arabic-Indic digits and Arabic decimal/thousands separators', () {
      expect(RawToProductNumberParser.parse('١٬٢٣٤٫٥'), 1234.5);
    });

    test('parses Persian digits and decimal separator', () {
      expect(RawToProductNumberParser.parse('۱۲۳٫۴۵'), 123.45);
    });

    test('accepts valid grouped whitespace and non-breaking spaces', () {
      expect(RawToProductNumberParser.parse('1 234.5'), 1234.5);
      expect(RawToProductNumberParser.parse('1\u00A0234,5'), 1234.5);
    });

    test('keeps the established comma convention for thousands and decimals', () {
      expect(RawToProductNumberParser.parse('1,234'), 1234);
      expect(RawToProductNumberParser.parse('12,5'), 12.5);
      expect(RawToProductNumberParser.parse('1,234.5'), 1234.5);
    });

    test('preserves explicit plus and minus signs for later validation', () {
      expect(RawToProductNumberParser.parse('+12.5'), 12.5);
      expect(RawToProductNumberParser.parse('-12.5'), -12.5);
    });

    test('rejects malformed grouping and non-finite values', () {
      expect(RawToProductNumberParser.parse('1 2'), isNull);
      expect(RawToProductNumberParser.parse('12 34'), isNull);
      expect(RawToProductNumberParser.parse('NaN'), isNull);
      expect(RawToProductNumberParser.parse('Infinity'), isNull);
      expect(RawToProductNumberParser.parse(''), isNull);
    });
  });
}
