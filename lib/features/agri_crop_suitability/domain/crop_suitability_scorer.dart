/// Deterministic, explainable crop suitability scoring.
///
/// This is a screening aid, not agronomic advice. It scores only the supplied
/// field measurements against supplied crop ranges; callers must source
/// region-appropriate requirements from a trusted agronomic source.
class CropRequirements {
  const CropRequirements({
    required this.name,
    required this.minRainfall,
    required this.maxRainfall,
    required this.minTemp,
    required this.maxTemp,
    required this.minPh,
    required this.maxPh,
  });

  final String name;
  final double minRainfall;
  final double maxRainfall;
  final double minTemp;
  final double maxTemp;
  final double minPh;
  final double maxPh;
}

class FieldConditions {
  const FieldConditions({
    required this.rainfall,
    required this.temperature,
    required this.ph,
  });

  final double rainfall;
  final double temperature;
  final double ph;
}

class CropSuitabilityResult {
  const CropSuitabilityResult(this.crop, this.score, this.reasons);

  final String crop;

  /// A weighted score from 0 to 100 based on three supplied measurements.
  final int score;
  final List<String> reasons;
}

class CropSuitabilityScorer {
  const CropSuitabilityScorer();

  CropSuitabilityResult score(CropRequirements crop, FieldConditions field) {
    final values = <double>[
      crop.minRainfall,
      crop.maxRainfall,
      crop.minTemp,
      crop.maxTemp,
      crop.minPh,
      crop.maxPh,
      field.rainfall,
      field.temperature,
      field.ph,
    ];
    if (values.any((value) => !value.isFinite) ||
        crop.name.trim().isEmpty ||
        crop.minRainfall < 0 ||
        crop.maxRainfall < 0 ||
        crop.minRainfall > crop.maxRainfall ||
        crop.minTemp > crop.maxTemp ||
        crop.minPh < 0 ||
        crop.maxPh > 14 ||
        crop.minPh > crop.maxPh ||
        field.rainfall < 0 ||
        field.ph < 0 ||
        field.ph > 14) {
      throw ArgumentError('Invalid crop requirements or field conditions');
    }

    var points = 0;
    final reasons = <String>[];

    void check(
      String label,
      double value,
      double minimum,
      double maximum,
      int weight,
    ) {
      if (value >= minimum && value <= maximum) {
        points += weight;
        reasons.add(
          '$label is within the supplied range ($minimum–$maximum)',
        );
      } else {
        reasons.add(
          '$label is outside the supplied range ($minimum–$maximum)',
        );
      }
    }

    check('Rainfall', field.rainfall, crop.minRainfall, crop.maxRainfall, 34);
    check('Temperature', field.temperature, crop.minTemp, crop.maxTemp, 33);
    check('Soil pH', field.ph, crop.minPh, crop.maxPh, 33);

    return CropSuitabilityResult(
      crop.name.trim(),
      points,
      List.unmodifiable(reasons),
    );
  }
}
