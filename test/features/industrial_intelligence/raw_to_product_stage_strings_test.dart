import 'package:flutter_test/flutter_test.dart';
import 'package:auren/core/i18n/auren_localizations.dart';
import 'package:auren/features/industrial_intelligence/presentation/raw_to_product_stage_strings.dart';

void main() {
  const routes = <String, int>{
    'cotton-to-garment': 5,
    'sesame-to-tahini': 4,
    'peanut-to-peanut-butter': 4,
    'hides-to-leather-goods': 4,
    'iron-to-fabricated-products': 4,
  };

  group('RawToProductStageStrings', () {
    test('provides route-specific names and descriptions in Arabic and English', () {
      expect(
        RawToProductStageStrings.name('sesame-to-tahini', 2, 'en', 'fallback'),
        'Grinding and homogenizing',
      );
      expect(
        RawToProductStageStrings.purpose(
          'sesame-to-tahini', 2, 'ar', 'fallback',
        ),
        'طحن السمسم المعالج إلى قوام الطحينة المستهدف.',
      );
      expect(
        RawToProductStageStrings.name('cotton-to-garment', 1, 'ar', 'fallback'),
        'الغزل',
      );
    });

    test('localizes every stage name and purpose in every supported locale', () {
      for (final locale in AurenLocalizations.supportedLocales) {
        final languageCode = locale.languageCode;
        for (final route in routes.entries) {
          for (var index = 0; index < route.value; index++) {
            final name = RawToProductStageStrings.name(
              route.key, index, languageCode, 'UNLOCALIZED_STAGE_NAME',
            );
            final purpose = RawToProductStageStrings.purpose(
              route.key, index, languageCode, 'UNLOCALIZED_STAGE_PURPOSE',
            );
            expect(
              name,
              isNot('UNLOCALIZED_STAGE_NAME'),
              reason: '$languageCode: ${route.key} stage $index name',
            );
            expect(
              name.trim(),
              isNotEmpty,
              reason: '$languageCode: ${route.key} stage $index name is empty',
            );
            expect(
              purpose,
              isNot('UNLOCALIZED_STAGE_PURPOSE'),
              reason: '$languageCode: ${route.key} stage $index purpose',
            );
            expect(
              purpose.trim(),
              isNotEmpty,
              reason: '$languageCode: ${route.key} stage $index purpose is empty',
            );
          }
        }
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
