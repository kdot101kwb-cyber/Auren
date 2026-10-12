import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/agri_crop_suitability/domain/crop_suitability_scorer.dart';

void main() {
  const scorer = CropSuitabilityScorer();
  const crop = CropRequirements(
    name: 'Crop',
    minRainfall: 300,
    maxRainfall: 800,
    minTemp: 18,
    maxTemp: 32,
    minPh: 5.5,
    maxPh: 7.5,
  );

  test('in-range field scores 100 and explains each measurement', () {
    final result = scorer.score(
      crop,
      const FieldConditions(rainfall: 500, temperature: 25, ph: 6.5),
    );

    expect(result.score, 100);
    expect(result.crop, 'Crop');
    expect(result.reasons, hasLength(3));
    expect(result.reasons.every((reason) => reason.contains('within')), isTrue);
  });

  test('out-of-range measurements receive no points for those measurements', () {
    final result = scorer.score(
      crop,
      const FieldConditions(rainfall: 100, temperature: 40, ph: 8),
    );

    expect(result.score, 0);
    expect(result.reasons.every((reason) => reason.contains('outside')), isTrue);
  });

  test('rejects non-finite measurements', () {
    expect(
      () => scorer.score(
        crop,
        const FieldConditions(rainfall: double.nan, temperature: 20, ph: 6),
      ),
      throwsArgumentError,
    );
    expect(
      () => scorer.score(
        crop,
        const FieldConditions(
          rainfall: 400,
          temperature: double.infinity,
          ph: 6,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid rainfall, pH, names, and reversed ranges', () {
    expect(
      () => scorer.score(
        crop,
        const FieldConditions(rainfall: -1, temperature: 20, ph: 6),
      ),
      throwsArgumentError,
    );
    expect(
      () => scorer.score(
        crop,
        const FieldConditions(rainfall: 400, temperature: 20, ph: 14.1),
      ),
      throwsArgumentError,
    );
    expect(
      () => scorer.score(
        const CropRequirements(
          name: ' ',
          minRainfall: 300,
          maxRainfall: 800,
          minTemp: 18,
          maxTemp: 32,
          minPh: 5.5,
          maxPh: 7.5,
        ),
        const FieldConditions(rainfall: 400, temperature: 20, ph: 6),
      ),
      throwsArgumentError,
    );
    expect(
      () => scorer.score(
        const CropRequirements(
          name: 'Invalid',
          minRainfall: 800,
          maxRainfall: 300,
          minTemp: 18,
          maxTemp: 32,
          minPh: 5.5,
          maxPh: 7.5,
        ),
        const FieldConditions(rainfall: 400, temperature: 20, ph: 6),
      ),
      throwsArgumentError,
    );
  });

  test('rejects reversed temperature and out-of-range pH requirements', () {
    expect(
      () => scorer.score(
        const CropRequirements(
          name: 'Invalid temperature range',
          minRainfall: 300,
          maxRainfall: 800,
          minTemp: 35,
          maxTemp: 20,
          minPh: 5.5,
          maxPh: 7.5,
        ),
        const FieldConditions(rainfall: 400, temperature: 25, ph: 6),
      ),
      throwsArgumentError,
    );
    expect(
      () => scorer.score(
        const CropRequirements(
          name: 'Invalid pH range',
          minRainfall: 300,
          maxRainfall: 800,
          minTemp: 18,
          maxTemp: 32,
          minPh: 15,
          maxPh: 16,
        ),
        const FieldConditions(rainfall: 400, temperature: 25, ph: 6),
      ),
      throwsArgumentError,
    );
  });

  test('returns an immutable explanation list', () {
    final result = scorer.score(
      crop,
      const FieldConditions(rainfall: 500, temperature: 25, ph: 6.5),
    );

    expect(() => result.reasons.add('unexpected'), throwsUnsupportedError);
  });
}
