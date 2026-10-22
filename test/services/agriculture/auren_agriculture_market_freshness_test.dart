import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/agriculture/agriculture_market_prices_service.dart';

AgricultureNormalizedLocalMarketPrice price({
  String? source = 'FAO GIEWS FPMA',
  String? sourceUrl = 'https://fpma.fao.org/',
  String? observedAt = '2026-10-20T12:00:00Z',
}) {
  return AgricultureNormalizedLocalMarketPrice(
    id: 'row-1',
    iso3: 'SDN',
    item: 'Sorghum',
    nativePrice: 100,
    currency: 'SDG',
    unit: 'kg',
    priceLocalPerTonne: 100000,
    usdPerLocalUnit: null,
    priceUsdPerTonne: null,
    fxDate: null,
    status: 'needs_unit_or_fx',
    observedAt: observedAt,
    source: source,
    sourceUrl: sourceUrl,
  );
}

void main() {
  group('Agriculture normalized market source freshness', () {
    final now = DateTime.utc(2026, 10, 21, 12);

    test('requires a source label and traceable HTTP URL', () {
      expect(price().hasTraceableSource, isTrue);
      expect(price(sourceUrl: null).hasTraceableSource, isFalse);
      expect(price(sourceUrl: 'javascript:alert(1)').hasTraceableSource, isFalse);
      expect(price(source: ' ').hasTraceableSource, isFalse);
    });

    test('does not call a recent observation trustworthy when URL is absent', () {
      final row = price(sourceUrl: null);
      expect(row.isStaleAt(now), isFalse);
      expect(row.freshnessLabelAt(now), contains('رابط المصدر غير متحقق'));
    });

    test('labels a traceable recent observation with a bounded freshness claim', () {
      final row = price();
      expect(row.freshnessLabelAt(now), contains('حديث'));
      expect(row.freshnessLabelAt(now), contains('راجع المصدر'));
    });

    test('treats missing, future and old observation dates as stale', () {
      expect(price(observedAt: null).isStaleAt(now), isTrue);
      expect(price(observedAt: '2026-10-22T12:00:00Z').isStaleAt(now), isTrue);
      expect(price(observedAt: '2026-10-01T12:00:00Z').isStaleAt(now), isTrue);
    });
  });
}
