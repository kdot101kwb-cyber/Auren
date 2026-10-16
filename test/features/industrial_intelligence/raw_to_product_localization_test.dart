import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/i18n/auren_localizations.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_strings.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_number_parser.dart';

void main() {
  group('RawToProductNumberParser', () {
    test('parses Arabic digits with Arabic thousands and decimal separators', () {
      expect(RawToProductNumberParser.parse('١٬٢٣٤٫٥'), 1234.5);
    });

    test('parses Persian digits and decimal separator', () {
      expect(RawToProductNumberParser.parse('۱۲۳٫۷۵'), 123.75);
    });

    test('accepts grouped thousands and decimal input with whitespace', () {
      expect(RawToProductNumberParser.parse('1,234.56'), 1234.56);
      expect(RawToProductNumberParser.parse('1 234,56'), 1234.56);
      expect(RawToProductNumberParser.parse('1\u00A0234,56'), 1234.56);
    });

    test('handles grouped thousands without changing digit values', () {
      expect(RawToProductNumberParser.parse('1,234,567'), 1234567);
      expect(RawToProductNumberParser.parse('١٬٢٣٤٬٥٦٧'), 1234567);
      expect(RawToProductNumberParser.parse('1\u202F234,56'), 1234.56);
    });

    test('does not silently accept malformed grouping or trailing text', () {
      expect(RawToProductNumberParser.parse('1,23,4'), isNull);
      expect(RawToProductNumberParser.parse('12.3.4'), isNull);
      expect(RawToProductNumberParser.parse('123abc'), isNull);
      expect(RawToProductNumberParser.parse('1,,234'), isNull);
    });

    test('documents comma-only ambiguity as thousands for three-digit groups', () {
      expect(RawToProductNumberParser.parse('1,234'), 1234);
      expect(RawToProductNumberParser.parse('12,34'), 12.34);
    });

    test('rejects malformed and non-finite values', () {
      expect(RawToProductNumberParser.parse('١٢x'), isNull);
      expect(RawToProductNumberParser.parse('NaN'), isNull);
      expect(RawToProductNumberParser.parse('Infinity'), isNull);
      expect(RawToProductNumberParser.parse(''), isNull);
    });
  });

  group('RawToProductStrings', () {
    test('provides planner translations for every supported app locale', () {
      for (final locale in AurenLocalizations.supportedLocales) {
        final strings = RawToProductStrings(locale.languageCode);
        expect(strings.title, isNotEmpty, reason: locale.languageCode);
        expect(strings.plan, isNotEmpty, reason: locale.languageCode);
        expect(strings.currency, isNotEmpty, reason: locale.languageCode);
        expect(strings.calculate, isNotEmpty, reason: locale.languageCode);
        expect(strings.warning, isNotEmpty, reason: locale.languageCode);
        expect(strings.routeName('cotton-to-garment'), isNotEmpty,
            reason: locale.languageCode);
        expect(strings.stageName(0), isNotEmpty, reason: locale.languageCode);
        expect(strings.prerequisites, hasLength(3), reason: locale.languageCode);
        expect(strings.prerequisites.every((item) => item.isNotEmpty), isTrue,
            reason: locale.languageCode);
      }
    });

    test('falls back to English for an unsupported language code', () {
      final strings = RawToProductStrings('xx');
      expect(strings.title, 'Raw to Product');
      expect(strings.calculate, 'Calculate manufacturing plan');
    });
  });
}
