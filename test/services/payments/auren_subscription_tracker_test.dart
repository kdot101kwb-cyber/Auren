import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/payments/auren_subscription_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AurenSubscription item({
    String id = 'netflix',
    String name = 'Streaming',
    int amount = 1299,
    String currency = 'USD',
    DateTime? due,
    bool active = true,
  }) => AurenSubscription(
        id: id,
        name: name,
        amountMinor: amount,
        currency: currency,
        nextDue: due ?? DateTime(2026, 10, 25),
        active: active,
      );

  group('AurenSubscription', () {
    test('rejects invalid amounts, names, currency, and cadence', () {
      expect(item(amount: 0).validate(), isNotNull);
      expect(item(name: ' ').validate(), isNotNull);
      expect(item(currency: 'usd').validate(), isNotNull);
      expect(item().copyWithForTest(cadenceDays: 0).validate(), isNotNull);
    });

    test('round-trips its stored representation', () {
      final original = item();
      expect(AurenSubscription.fromJson(original.toJson()).toJson(),
          original.toJson());
    });
  });

  group('AurenSubscriptionTracker', () {
    const tracker = AurenSubscriptionTracker();

    test('isolates local records by account and persists them', () async {
      await tracker.save('user-a', [item()]);
      expect((await tracker.load('user-a')).single.id, 'netflix');
      expect(await tracker.load('user-b'), isEmpty);
    });

    test('rejects duplicate IDs instead of silently overwriting', () async {
      await expectLater(
        tracker.save('user-a', [item(), item(name: 'Another')]),
        throwsArgumentError,
      );
    });

    test('summarizes currencies separately and ignores inactive records',
        () {
      final summary = tracker.summarize(
        [
          item(),
          item(id: 'music', amount: 500, currency: 'USD'),
          item(id: 'mobile', amount: 900, currency: 'SDG'),
          item(id: 'paused', amount: 200, active: false),
          item(id: 'later', due: DateTime(2027, 2, 1)),
        ],
        now: DateTime(2026, 10, 22),
      );
      expect(summary.activeCount, 4);
      expect(summary.totalsByCurrency, {'USD': 1799, 'SDG': 900});
      expect(summary.upcoming.map((x) => x.id), ['netflix', 'music', 'mobile']);
    });

    test('rejects an invalid due window', () {
      expect(
        () => tracker.summarize([], now: DateTime(2026), dueWithinDays: 500),
        throwsArgumentError,
      );
    });
  });
}

extension on AurenSubscription {
  AurenSubscription copyWithForTest({int? cadenceDays}) => AurenSubscription(
        id: id,
        name: name,
        amountMinor: amountMinor,
        currency: currency,
        nextDue: nextDue,
        cadenceDays: cadenceDays ?? this.cadenceDays,
        active: active,
        notes: notes,
      );
}
