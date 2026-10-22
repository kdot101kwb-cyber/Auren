import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/agriculture/agriculture_market_prices_service.dart';

AgricultureMarketPrice price({
  String source = 'FAO GIEWS FPMA',
  String sourceUrl = 'https://fpma.fao.org/',
  String? observedAt = '2026-10-20T12:00:00Z',
}) {
  return AgricultureMarketPrice(
    id: 'price-1',
    market: 'Central market',
    commodity: 'Sorghum',
    category: 'grain',
    country: 'Sudan',
    countryCode: 'SD',
    state: '',
    city: 'Khartoum',
    marketName: 'Central market',
    price: 120,
    currency: 'SDG',
    unit: 'kg',
    source: source,
    sourceUrl: sourceUrl,
    exchange: '',
    verified: false,
    observedAt: observedAt,
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 21, 12);

  test('recent observation with a traceable HTTP source is not stale', () {
    final row = price();

    expect(row.hasTraceableSource, isTrue);
    expect(row.isStaleAt(now), isFalse);
    expect(row.freshnessLabelAt(now), 'تاريخ الرصد حديث وفق حدّ التحقق');
  });

  test('missing or invalid observation date is treated as stale', () {
    expect(price(observedAt: null).isStaleAt(now), isTrue);
    expect(price(observedAt: 'not-a-date').isStaleAt(now), isTrue);
    expect(price(observedAt: null).freshnessLabelAt(now), 'تاريخ الرصد غير متوفر');
  });

  test('observations older than seven days and future-dated are stale', () {
    expect(price(observedAt: '2026-10-13T11:59:59Z').isStaleAt(now), isTrue);
    expect(price(observedAt: '2026-10-21T12:00:01Z').isStaleAt(now), isTrue);
  });

  test('source labels without a valid HTTP(S) URL are not traceable', () {
    expect(price(sourceUrl: 'javascript:alert(1)').hasTraceableSource, isFalse);
    expect(price(sourceUrl: 'not-a-url').hasTraceableSource, isFalse);
    expect(
      price(sourceUrl: '').freshnessLabelAt(now),
      'مصدر السعر غير مكتمل',
    );
  });

  test('normalized market rows require a traceable source for a current label', () {
    const row = AgricultureNormalizedLocalMarketPrice(
      id: 'normalized-1',
      iso3: 'SDN',
      item: 'Sorghum',
      nativePrice: 120,
      currency: 'SDG',
      unit: 'kg',
      priceLocalPerTonne: null,
      usdPerLocalUnit: null,
      priceUsdPerTonne: null,
      fxDate: null,
      status: 'needs_unit_or_fx',
      observedAt: '2026-10-20T12:00:00Z',
      source: 'Local market record',
    );

    expect(row.isStaleAt(now), isFalse);
    expect(
      row.freshnessLabelAt(now),
      'مصدر السعر غير مكتمل — رابط المصدر غير متحقق',
    );

    const traceableRow = AgricultureNormalizedLocalMarketPrice(
      id: 'normalized-traceable',
      iso3: 'SDN',
      item: 'Sorghum',
      nativePrice: 120,
      currency: 'SDG',
      unit: 'kg',
      priceLocalPerTonne: null,
      usdPerLocalUnit: null,
      priceUsdPerTonne: null,
      fxDate: null,
      status: 'needs_unit_or_fx',
      observedAt: '2026-10-20T12:00:00Z',
      source: 'FAO FPMA',
      sourceUrl: 'https://fpma.fao.org/',
    );
    expect(traceableRow.hasTraceableSource, isTrue);
    expect(
      traceableRow.freshnessLabelAt(now),
      'تاريخ الرصد حديث وفق حدّ التحقق؛ راجع المصدر قبل اتخاذ القرار',
    );

    const missingSource = AgricultureNormalizedLocalMarketPrice(
      id: 'normalized-2',
      iso3: 'SDN',
      item: 'Sorghum',
      nativePrice: 120,
      currency: 'SDG',
      unit: 'kg',
      priceLocalPerTonne: null,
      usdPerLocalUnit: null,
      priceUsdPerTonne: null,
      fxDate: null,
      status: 'needs_unit_or_fx',
      observedAt: '2026-10-20T12:00:00Z',
      source: ' ',
    );
    expect(missingSource.freshnessLabelAt(now), 'مصدر السعر غير مكتمل — رابط المصدر غير متحقق');

    const oldRow = AgricultureNormalizedLocalMarketPrice(
      id: 'normalized-3',
      iso3: 'SDN',
      item: 'Sorghum',
      nativePrice: 120,
      currency: 'SDG',
      unit: 'kg',
      priceLocalPerTonne: null,
      usdPerLocalUnit: null,
      priceUsdPerTonne: null,
      fxDate: null,
      status: 'needs_unit_or_fx',
      observedAt: '2026-10-13T11:59:59Z',
      source: 'Local market record',
    );
    expect(oldRow.isStaleAt(now), isTrue);
    expect(oldRow.freshnessLabelAt(now), 'مصدر السعر غير مكتمل — رابط المصدر غير متحقق');
  });
}
