/// Parses numeric input using Latin, Arabic, and Persian digits and separators.
///
/// Ambiguous comma-only input follows the planner's established convention:
/// grouped thousands such as 1,234 are thousands; otherwise comma is decimal.
class RawToProductNumberParser {
  static String _normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var normalized = value.trim();
    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(arabic[i], '$i');
      normalized = normalized.replaceAll(persian[i], '$i');
    }
    return normalized;
  }

  static double? parse(String value) {
    var normalized = _normalizeDigits(value)
        .replaceAll('٫', '.')
        .replaceAll('٬', ',');
    final whitespace = RegExp(r'[\s\u00A0\u202F]');
    if (whitespace.hasMatch(normalized)) {
      // Whitespace is accepted only as a valid thousands-group separator.
      // This prevents malformed values such as "1 2" silently becoming 12.
      final validWhitespaceGrouping = RegExp(
        r'^\d{1,3}(?:[\s\u00A0\u202F]\d{3})+(?:[,.]\d+)?$',
      );
      if (!validWhitespaceGrouping.hasMatch(normalized)) return null;
      normalized = normalized.replaceAll(whitespace, '');
    }

    final commaDecimalWithDotGrouping =
        RegExp(r'^\d{1,3}(?:\.\d{3})+,\d+$');
    final commaThousandsWithDotDecimal =
        RegExp(r'^\d{1,3}(?:,\d{3})+\.\d+$');
    final commaThousandsOnly =
        RegExp(r'^\d{1,3}(?:,\d{3})+$');

    if (commaDecimalWithDotGrouping.hasMatch(normalized)) {
      // European format, e.g. 1.234,56.
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (commaThousandsWithDotDecimal.hasMatch(normalized) ||
        commaThousandsOnly.hasMatch(normalized)) {
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      // Preserve the established convention: 1,234 is thousands,
      // while 12,5 is a decimal.
      final validThousands = RegExp(r'^\d{1,3}(?:,\d{3})+$');
      if (validThousands.hasMatch(normalized)) {
        normalized = normalized.replaceAll(',', '');
      } else {
        if (!RegExp(r'^\d+,\d+$').hasMatch(normalized)) return null;
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (normalized.contains(',')) {
      // Mixed separators must match a known, unambiguous format.
      return null;
    }

    final parsed = double.tryParse(normalized);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
