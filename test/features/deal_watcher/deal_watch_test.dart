import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/deal_watcher/domain/deal_watch.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 2);
  final t2 = DateTime.utc(2026, 1, 3);

  DealPricePoint point(double amount, DateTime time) =>
      DealPricePoint(amount: amount, observedAt: time);

  DealWatch watch({
    List<DealPricePoint> history = const [],
    double? target,
    bool anyDrop = false,
    String currency = 'USD',
  }) =>
      DealWatch(
        id: 'watch-1',
        title: 'Rice cooker',
        productUrl: 'https://shop.example/item/1',
        currencyCode: currency,
        history: history,
        targetPrice: target,
        notifyOnAnyDrop: anyDrop,
      );

  test('computes absolute and fractional price changes', () {
    final item = watch(history: [point(100, t0), point(85, t1)]);
    expect(item.absoluteChange, -15);
    expect(item.fractionalChange, -0.15);
  });

  test('does not divide by zero when previous price is zero', () {
    final item = watch(history: [point(0, t0), point(5, t1)]);
    expect(item.fractionalChange, isNull);
  });

  test('target alert fires when price first reaches target', () {
    expect(
      watch(history: [point(80, t0)], target: 80).shouldNotify,
      isTrue,
    );
  });

  test('target alert fires on crossing, but not repeated below target', () {
    expect(
      watch(history: [point(100, t0), point(75, t1)], target: 80).shouldNotify,
      isTrue,
    );
    expect(
      watch(history: [point(75, t1), point(70, t2)], target: 80).shouldNotify,
      isFalse,
    );
  });

  test('optional any-drop alert only fires for a real decrease', () {
    expect(
      watch(history: [point(100, t0), point(99, t1)], anyDrop: true).shouldNotify,
      isTrue,
    );
    expect(
      watch(history: [point(100, t0), point(100, t1)], anyDrop: true).shouldNotify,
      isFalse,
    );
  });

  test('rejects malformed product URLs and currency codes', () {
    expect(
      () => DealWatch(
        id: 'x',
        title: 'Item',
        productUrl: 'javascript:alert(1)',
        currencyCode: 'USD',
        history: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => watch(currency: 'usd'),
      throwsArgumentError,
    );
  });

  test('rejects history that is not chronological', () {
    expect(
      () => watch(history: [point(10, t2), point(9, t1)]),
      throwsArgumentError,
    );
  });
}
