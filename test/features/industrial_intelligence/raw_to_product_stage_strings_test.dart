import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/i18n/auren_localizations.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_stage_strings.dart';

void main() {
  group('RawToProductStageStrings', () {
    test('provides route-specific names and descriptions in Arabic and English', () {
      expect(
        RawToProductStageStrings.name(
          'sesame-to-tahini', 2, 'en', 'fallback',
        ),
        'Grinding and homogenizing',
      );
      expect(
        RawToProductStageStrings.purpose(
          'sesame-to-tahini', 2, 'ar', 'fallback',
        ),
        'طحن السمسم المعالج إلى قوام الطحينة المستهدف.',
      );
      expect(
        RawToProductStageStrings.name(
          'cotton-to-garment', 1, 'ar', 'fallback',
        ),
        'الغزل',
      );
    });

    test('uses localized generic fallback for other supported languages', () {
      for (final locale in AurenLocalizations.supportedLocales) {
        final languageCode = locale.languageCode;
        final name = RawToProductStageStrings.name(
          'sesame-to-tahini', 0, languageCode, 'localized fallback',
        );
        final purpose = RawToProductStageStrings.purpose(
          'sesame-to-tahini', 0, languageCode, 'localized purpose fallback',
        );
        expect(name, isNotEmpty, reason: languageCode);
        expect(purpose, isNotEmpty, reason: languageCode);
      }
    });

    test('uses fallback for unknown routes and out-of-range stages', () {
      expect(
        RawToProductStageStrings.name('unknown', 0, 'en', 'fallback'),
        'fallback',
      );
      expect(
        RawToProductStageStrings.purpose(
          'cotton-to-garment', 99, 'en', 'fallback purpose',
        ),
        'fallback purpose',
      );
    });
  });
}
