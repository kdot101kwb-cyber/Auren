import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_number_parser.dart';

void main() {
  group('RawToProductNumberParser edge cases', () {
    test('trims surrounding whitespace without changing the value', () {
      expect(RawToProductNumberParser.parse('  123.45  '), 123.45);
    });

    test('parses repeated comma thousands groups', () {
      expect(RawToProductNumberParser.parse('1,234,567'), 1234567);
      expect(RawToProductNumberParser.parse('1,234,567.89'), 1234567.89);
    });

    test('parses repeated ordinary and narrow non-breaking space groups', () {
      expect(RawToProductNumberParser.parse('1 234 567,89'), 1234567.89);
      expect(RawToProductNumberParser.parse('1\u202F234\u202F567٫٨٩'), 1234567.89);
    });

    test('rejects malformed comma groups instead of guessing a value', () {
      expect(RawToProductNumberParser.parse('12,34,567'), isNull);
      expect(RawToProductNumberParser.parse('1,23,456'), isNull);
      expect(RawToProductNumberParser.parse('1,234,56'), isNull);
    });

    test('rejects malformed mixed separators and repeated decimals', () {
      expect(RawToProductNumberParser.parse('1,23.456'), isNull);
      expect(RawToProductNumberParser.parse('1.2.3'), isNull);
      expect(RawToProductNumberParser.parse('1٫2٫3'), isNull);
    });

    test('rejects currency symbols and unit suffixes', () {
      expect(RawToProductNumberParser.parse('\$123.45'), isNull);
      expect(RawToProductNumberParser.parse('123 kg'), isNull);
      expect(RawToProductNumberParser.parse('SDG 123'), isNull);
    });

    test('rejects punctuation-only and sign-only input', () {
      expect(RawToProductNumberParser.parse(','), isNull);
      expect(RawToProductNumberParser.parse('.'), isNull);
      expect(RawToProductNumberParser.parse('-'), isNull);
      expect(RawToProductNumberParser.parse('+'), isNull);
    });
  });
}
