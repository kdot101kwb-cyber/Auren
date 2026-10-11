/// Offline, deterministic first-pass extraction for supplier RFQ requests.
class SupplierRfqIntent {
  const SupplierRfqIntent({
    this.product,
    this.quantity,
    this.unit,
    this.destination,
    this.budget,
    this.currency,
    this.leadTime,
  });

  final String? product;
  final String? quantity;
  final String? unit;
  final String? destination;
  final String? budget;
  final String? currency;
  final String? leadTime;

  bool get hasUsefulFields => [
        product,
        quantity,
        destination,
        budget,
        currency,
        leadTime,
      ].any((value) => value != null && value.isNotEmpty);

  List<String> get missingRequiredFields => [
        if (product == null || product!.isEmpty) 'المنتج',
        if (quantity == null || quantity!.isEmpty) 'الكمية',
        if (destination == null || destination!.isEmpty) 'وجهة التسليم',
      ];
}

class SupplierRfqIntentParser {
  const SupplierRfqIntentParser._();

  static SupplierRfqIntent parse(String input) {
    final text = _digits(input).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return const SupplierRfqIntent();

    final quantityMatch = RegExp(
      r'(?:quantity\s*[:=]?\s*|qty\s*[:=]?\s*|الكمية\s*[:=]?\s*|عدد\s*)?(\d+(?:[,.]\d+)?)\s*(pieces?|pcs|units?|kg|g|tons?|liters?|litres?|meters?|metres?|yards?|boxes?|قطعة|قطع|حبة|حبات|كيلو(?:غرام)?|طن|لتر|متر|كرتون|صندوق)?',
      caseSensitive: false,
    ).firstMatch(text);
    final amount = quantityMatch?.group(1)?.replaceAll(',', '.');
    final unit = _unit(quantityMatch?.group(2));

    String? destination;
    final destinationMatch = RegExp(
      r'(?:delivered\s+to|shipped?\s+to|destination\s*[:=]?|to|إلى|الى|للتسليم في|التسليم إلى|في)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (destinationMatch != null) {
      destination = destinationMatch.group(1)!.trim();
      destination = destination.replaceFirst(
        RegExp(
          r'\s+(?:with a budget|budget|under|within|in\s+\d+\s+days|خلال|بميزانية|ميزانية|بحدود).*$',
          caseSensitive: false,
        ),
        '',
      ).trim();
      if (destination.isEmpty) destination = null;
    }

    String? budget;
    String? currency;
    final budgetMatch = RegExp(
      r'(?:budget|بميزانية|ميزانية|بحدود|حد أقصى)\s*[:=]?\s*(USD|EUR|SDG|KES|NGN|\$|€)?\s*(\d[\d,.]*)\s*(USD|EUR|SDG|KES|NGN|دولار|دولارات|يورو|جنيه)?',
      caseSensitive: false,
    ).firstMatch(text);
    final symbolMatch = RegExp(r'([$€])\s*(\d[\d,.]*)').firstMatch(text);
    if (budgetMatch != null) {
      budget = budgetMatch.group(2)?.replaceAll(',', '');
      currency = _currency(budgetMatch.group(1)) ??
          _currency(budgetMatch.group(3));
    } else if (symbolMatch != null) {
      budget = symbolMatch.group(2)?.replaceAll(',', '');
      currency = _currency(symbolMatch.group(1));
    }
    final currencyCodeMatch = RegExp(
      r'\b(USD|EUR|SDG|KES|NGN)\b',
      caseSensitive: false,
    ).firstMatch(text);
    currency ??= _currency(currencyCodeMatch?.group(1));
    if (currency == null && RegExp(r'دولار|دولارات').hasMatch(text)) {
      currency = 'USD';
    }
    if (currency == null && RegExp(r'يورو').hasMatch(text)) currency = 'EUR';

    String? leadTime;
    final leadTimeMatch = RegExp(
      r'(?:within|in|lead time\s*[:=]?|خلال|مدة التوريد\s*[:=]?)\s*(\d+)\s*(days?|weeks?|أيام|يوم|أسابيع|أسبوع)',
      caseSensitive: false,
    ).firstMatch(text);
    if (leadTimeMatch != null) {
      leadTime = '${leadTimeMatch.group(1)} ${leadTimeMatch.group(2)}';
    }

    String? product;
    if (quantityMatch != null) {
      var beforeQuantity = text.substring(0, quantityMatch.start).trim();
      beforeQuantity = beforeQuantity.replaceFirst(
        RegExp(
          r'^(?:i need|need|looking for|طلب|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+',
          caseSensitive: false,
        ),
        '',
      );
      beforeQuantity = beforeQuantity.replaceFirst(
        RegExp(r'^(?:about|around|approximately)\s+', caseSensitive: false),
        '',
      );
      if (beforeQuantity.isNotEmpty) {
        product = beforeQuantity;
      } else {
        var afterQuantity = text.substring(quantityMatch.end).trim();
        afterQuantity = afterQuantity.replaceFirst(
          RegExp(r'^(?:of|من)\s+', caseSensitive: false),
          '',
        );
        if (afterQuantity.isNotEmpty) {
          product = afterQuantity
              .split(
                RegExp(
                  r'\s+(?:delivered\s+to|shipped?\s+to|with\s+a\s+budget|budget|within|to|in|for|إلى|الى|في|بميزانية|خلال)\s+',
                  caseSensitive: false,
                ),
              )
              .first
              .trim();
        }
      }
    } else {
      final productMatch = RegExp(
        r'(?:i need|need|looking for|product\s*[:=]?|المنتج\s*[:=]?|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+(.+)',
        caseSensitive: false,
      ).firstMatch(text);
      if (productMatch != null) {
        product = productMatch
            .group(1)!
            .split(
              RegExp(
                r'\s+(?:to|in|for|إلى|الى|في|بميزانية|ميزانية|خلال)\s+',
                caseSensitive: false,
              ),
            )
            .first
            .trim();
      }
    }

    if (product != null) {
      product = product
          .replaceFirst(
            RegExp(r'\s+(?:budget|بميزانية|ميزانية|\$|€).*$', caseSensitive: false),
            '',
          )
          .trim();
      if (product.isEmpty) product = null;
    }

    return SupplierRfqIntent(
      product: product,
      quantity: amount == null ? null : '$amount${unit == null ? '' : ' $unit'}',
      unit: unit,
      destination: destination,
      budget: budget,
      currency: currency,
      leadTime: leadTime,
    );
  }

  static String _digits(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    final output = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final arabicIndex = arabicDigits.indexOf(character);
      final persianIndex = persianDigits.indexOf(character);
      output.write(
        arabicIndex >= 0
            ? arabicIndex
            : persianIndex >= 0
                ? persianIndex
                : character,
      );
    }
    return output.toString();
  }

  static String? _unit(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final value = raw.toLowerCase();
    if ([
      'piece',
      'pieces',
      'pcs',
      'unit',
      'units',
      'قطعة',
      'قطع',
      'حبة',
      'حبات',
    ].contains(value)) {
      return 'pieces';
    }
    if (['kg', 'g', 'كيلو', 'كيلوغرام'].contains(value)) {
      return value == 'g' ? 'g' : 'kg';
    }
    if (['ton', 'tons', 'طن'].contains(value)) return 'tons';
    if (['liter', 'liters', 'litre', 'litres', 'لتر'].contains(value)) {
      return 'liters';
    }
    if (['meter', 'meters', 'metre', 'metres', 'متر'].contains(value)) {
      return 'meters';
    }
    if (['yard', 'yards'].contains(value)) return 'yards';
    if (['box', 'boxes', 'صندوق', 'كرتون'].contains(value)) return 'boxes';
    return value;
  }

  static String? _currency(String? raw) {
    if (raw == null) return null;
    switch (raw.toUpperCase()) {
      case 'USD':
      case r'$':
      case 'دولار':
      case 'دولارات':
        return 'USD';
      case 'EUR':
      case '€':
      case 'يورو':
        return 'EUR';
      case 'SDG':
        return 'SDG';
      case 'KES':
        return 'KES';
      case 'NGN':
        return 'NGN';
      default:
        return null;
    }
  }
}
