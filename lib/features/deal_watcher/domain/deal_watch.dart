/// Domain model for AUREN Deal Watcher.
///
/// This layer stores user-entered or explicitly sourced observations only.
/// It does not scrape websites, claim live prices, purchase products, or move money.
class DealPricePoint {
  const DealPricePoint({
    required this.amount,
    required this.observedAt,
  }) : assert(amount >= 0);

  final double amount;
  final DateTime observedAt;
}

class DealWatch {
  DealWatch({
    required this.id,
    required this.title,
    required this.productUrl,
    required this.currencyCode,
    required List<DealPricePoint> history,
    this.targetPrice,
    this.notifyOnAnyDrop = false,
  }) : history = List.unmodifiable(_validateHistory(history)) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    final uri = Uri.tryParse(productUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      throw ArgumentError.value(productUrl, 'productUrl', 'must be an HTTP(S) URL');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'must be a three-letter uppercase currency code',
      );
    }
    if (targetPrice != null && targetPrice! < 0) {
      throw ArgumentError.value(targetPrice, 'targetPrice', 'must be non-negative');
    }
  }

  final String id;
  final String title;
  final String productUrl;
  final String currencyCode;
  final List<DealPricePoint> history;
  final double? targetPrice;
  final bool notifyOnAnyDrop;

  DealPricePoint? get latest =>
      history.isEmpty ? null : history.last;

  DealPricePoint? get previous =>
      history.length < 2 ? null : history[history.length - 2];

  double? get absoluteChange {
    final now = latest?.amount;
    final before = previous?.amount;
    if (now == null || before == null) return null;
    return now - before;
  }

  /// Fractional change, e.g. -0.10 means a 10% decrease.
  double? get fractionalChange {
    final before = previous?.amount;
    final change = absoluteChange;
    if (before == null || before == 0 || change == null) return null;
    return change / before;
  }

  bool get shouldNotify {
    final now = latest?.amount;
    if (now == null) return false;

    final target = targetPrice;
    if (target != null && now <= target) {
      final before = previous?.amount;
      // Notify on crossing the target, or when the first observation already
      // meets the target. Repeated observations below the target do not notify.
      return before == null ? true : before > target;
    }

    final change = absoluteChange;
    return notifyOnAnyDrop && change != null && change < 0;
  }

  static List<DealPricePoint> _validateHistory(List<DealPricePoint> points) {
    final result = List<DealPricePoint>.of(points);
    for (var i = 1; i < result.length; i++) {
      if (result[i].observedAt.isBefore(result[i - 1].observedAt)) {
        throw ArgumentError('history must be ordered by observedAt ascending');
      }
    }
    return result;
  }
}
