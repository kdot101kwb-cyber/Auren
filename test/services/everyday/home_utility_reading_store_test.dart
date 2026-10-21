import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/home_utility_ledger_service.dart';
import 'package:auren/services/everyday/home_utility_reading_store.dart';
void main() {
 setUp(() => SharedPreferences.setMockInitialValues({}));
 AurenUtilityReading makeReading({required String id, required double value, required int day, String meterId = 'power'}) => AurenUtilityReading(id: id, meterId: meterId, label: 'Main power', kind: AurenUtilityKind.electricity, value: value, unit: 'kWh', recordedAt: DateTime(2026, 10, day));
 test('persists readings per UID and computes usage', () async { final store = AurenHomeUtilityReadingStore(); await store.saveReading('user-a', makeReading(id: 'r1', value: 50, day: 1)); await store.saveReading('user-a', makeReading(id: 'r2', value: 74, day: 10)); await store.saveReading('user-b', makeReading(id: 'other', value: 9, day: 10, meterId: 'water')); expect(AurenHomeUtilityLedger.latestUsage(await store.loadReadings('user-a'), 'power'), 24); expect((await store.loadReadings('user-b')).map((v) => v.id), ['other']); });
 test('rejects duplicate timestamps and unit changes without overwriting history', () async {
  final store = AurenHomeUtilityReadingStore();
  final first = makeReading(id: 'r1', value: 50, day: 1);
  await store.saveReading('user-a', first);

  await expectLater(
    store.saveReading('user-a', makeReading(id: 'r2', value: 55, day: 1)),
    throwsArgumentError,
  );
  await expectLater(
    store.saveReading('user-a', AurenUtilityReading(
      id: 'r2',
      meterId: 'power',
      label: 'Main power',
      kind: AurenUtilityKind.electricity,
      value: 55,
      unit: 'MWh',
      recordedAt: DateTime(2026, 10, 2),
    )),
    throwsArgumentError,
  );

  final saved = await store.loadReadings('user-a');
  expect(saved, hasLength(1));
  expect(saved.single.id, 'r1');
  expect(saved.single.value, 50);
  expect(saved.single.unit, 'kWh');
 });

 test('rejects blank UID, invalid values and decreasing readings', () async { final store = AurenHomeUtilityReadingStore(); await expectLater(store.loadReadings(''), throwsArgumentError); await expectLater(store.saveReading('user-a', makeReading(id: 'bad', value: -1, day: 1)), throwsArgumentError); await store.saveReading('user-a', makeReading(id: 'r1', value: 50, day: 1)); await expectLater(store.saveReading('user-a', makeReading(id: 'r2', value: 49, day: 2)), throwsArgumentError); expect((await store.loadReadings('user-a')).map((v) => v.id), ['r1']); });
}
