/// Pure comparison rules for supplier quotes. No currency conversion is performed.
class SupplierOfferComparisonLogic {
  const SupplierOfferComparisonLogic._();

  static double? parseNonNegativeAmount(String value) {
    final raw = value.trim();
    // Accept plain digits or correctly grouped thousands separators only.
    // Removing every comma first would incorrectly accept values like "1,,2".
    final validNumber = RegExp(r'^(?:\\d+|\\d{1,3}(?:,\\d{3})+)(?:\\.\\d+)?$');
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
    return aTotal.compareTo(bTotal);
  }
}
