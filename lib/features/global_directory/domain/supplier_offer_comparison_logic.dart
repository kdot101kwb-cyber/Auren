/// Pure comparison rules for supplier quotes. No currency conversion is performed.
class SupplierOfferComparisonLogic {
  const SupplierOfferComparisonLogic._();

  static double? parseNonNegativeAmount(String value) {
    final raw = value.trim();
    // Accept plain digits or correctly grouped thousands separators only.
    // Removing every comma first would incorrectly accept values like "1,,2".
    final validNumber = RegExp(
      r'^(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)(?:[.][0-9]+)?$',
    );
    if (!validNumber.hasMatch(raw)) return null;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  static double? total(String price, String shipping) {
    final parsedPrice = parseNonNegativeAmount(price);
    final parsedShipping = parseNonNegativeAmount(shipping);
    if (parsedPrice == null || parsedShipping == null) return null;
    final value = parsedPrice + parsedShipping;
    return value.isFinite ? value : null;
  }

  /// Parses only an unambiguous ISO calendar date (YYYY-MM-DD).
  /// Free-form validity notes intentionally return null rather than being guessed.
  static DateTime? parseIsoValidityDate(String value) {
    final raw = value.trim();
    final parts = raw.split('-');
    if (raw.length != 10 ||
        parts.length != 3 ||
        parts[0].length != 4 ||
        parts[1].length != 2 ||
        parts[2].length != 2 ||
        parts.any((part) => int.tryParse(part) == null)) {
      return null;
    }

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Classifies quote validity for reminders and filtering.
  /// Unknown/free-form notes are never guessed; the seven-day window is inclusive.
  static String validityCategory(String value, {DateTime? today}) {
    final days = daysUntilValidity(value, today: today);
    if (days == null) return 'unknown';
    if (days < 0) return 'expired';
    if (days == 0) return 'today';
    if (days <= 7) return 'soon';
    return 'valid';
  }

  /// Returns calendar days until an ISO validity date, or null for free-form
  /// notes and invalid dates. Uses calendar days, not elapsed 24-hour periods.
  static int? daysUntilValidity(String value, {DateTime? today}) {
    final date = parseIsoValidityDate(value);
    if (date == null) return null;
    final reference = today ?? DateTime.now();
    final todayUtc = DateTime.utc(reference.year, reference.month, reference.day);
    return date.difference(todayUtc).inDays;
  }

  static bool isLowest({
    required String currency,
    required String price,
    required String shipping,
    required Iterable<Map<String, String>> offers,
  }) {
    final candidateTotal = total(price, shipping);
    if (candidateTotal == null) return false;
    final comparable = offers
        .where((offer) => offer['currency'] == currency)
        .map((offer) => total(offer['price'] ?? '', offer['shipping'] ?? ''))
        .whereType<double>();
    if (comparable.isEmpty) return false;
    return candidateTotal == comparable.reduce((a, b) => a < b ? a : b);
  }

  static int compare({
    required String aCurrency,
    required String aSupplier,
    required String aPrice,
    required String aShipping,
    required String bCurrency,
    required String bSupplier,
    required String bPrice,
    required String bShipping,
  }) {
    // Currency groups are alphabetical; numeric totals are only compared
    // inside the same currency, never across currencies.
    if (aCurrency != bCurrency) return aCurrency.compareTo(bCurrency);
    final aTotal = total(aPrice, aShipping);
    final bTotal = total(bPrice, bShipping);
    if (aTotal == null && bTotal == null) return aSupplier.compareTo(bSupplier);
    if (aTotal == null) return 1;
    if (bTotal == null) return -1;
    final totalOrder = aTotal.compareTo(bTotal);
    // Keep equal-price offers in a deterministic order across rebuilds.
    return totalOrder != 0 ? totalOrder : aSupplier.compareTo(bSupplier);
  }

  /// Escapes a CSV field and guards spreadsheet formula injection.
  /// Every cell is quoted; embedded quotes are doubled per RFC 4180.
  static String csvCell(String value) {
    var safeValue = value;
    if (RegExp(r'^\s*[=+@-]').hasMatch(safeValue)) {
      safeValue = "'$safeValue";
    }
    return '"${safeValue.replaceAll('"', '""')}"';
  }

  /// Serializes one row as comma-separated, quoted cells.
  static String csvRow(Iterable<String> values) =>
      values.map(csvCell).join(',');
}
