import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/i18n/auren_localizations.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_strings.dart';

void main() {
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
