/// Parses numeric input using Latin, Arabic, and Persian digits and separators.
///
/// Ambiguous comma-only input follows the planner's existing convention:
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
        r'^\d{1,3}(?:[\s\u00A0\u202F]\d{3})+(?:[,.]\d+)?
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '.');
    }
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
,
      );
      if (!validWhitespaceGrouping.hasMatch(normalized)) return null;
      normalized = normalized.replaceAll(whitespace, '');
    }
    if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '.');
    }
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
).hasMatch(normalized)) {
      normalized = normalized.replaceAll(',', '');
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '.');
    }
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
