/// Pure comparison rules for supplier quotes. No currency conversion is performed.
class SupplierOfferComparisonLogic {
  const SupplierOfferComparisonLogic._();

  static double? parseNonNegativeAmount(String value) {
    final raw = value.trim();
    // Accept plain digits or correctly grouped thousands separators only.
    // Removing every comma first would incorrectly accept values like "1,,2".
    final validNumber = RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$');
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
    if (!RegExp(r'^\\d{4}-\\d{2}-\\d{2}
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
}
).hasMatch(raw)) return null;
    final parts = raw.split('-').map(int.parse).toList(growable: false);
    final date = DateTime.utc(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] || date.month != parts[1] || date.day != parts[2]) {
      return null;
    }
    return date;
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
}
