import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/home_utility_ledger_service.dart';
void main() {
 AurenUtilityReading makeReading({required String id, required double value, required int day, String unit = 'kWh'}) => AurenUtilityReading(id: id, meterId: 'main', label: 'Main meter', kind: AurenUtilityKind.electricity, value: value, unit: unit, recordedAt: DateTime(2026, 10, day));
 test('computes usage from two valid readings', () { final values = [makeReading(id: 'a', value: 120, day: 1), makeReading(id: 'b', value: 157.5, day: 15)]; expect(AurenHomeUtilityLedger.latestUsage(values, 'main'), 37.5); expect(AurenHomeUtilityLedger.latestUsage(values.take(1), 'main'), isNull); });
 test('rejects decreasing cumulative readings and unit changes', () { expect(AurenHomeUtilityLedger.validateSeries([makeReading(id: 'a', value: 20, day: 1), makeReading(id: 'b', value: 10, day: 2)]), isNotNull); expect(AurenHomeUtilityLedger.validateSeries([makeReading(id: 'a', value: 20, day: 1), makeReading(id: 'b', value: 21, day: 2, unit: 'MWh')]), isNotNull); });

 test('does not calculate usage from an invalid reading history', () {
  final duplicateTime = [
   makeReading(id: 'a', value: 10, day: 1),
   makeReading(id: 'b', value: 12, day: 1),
   makeReading(id: 'c', value: 15, day: 2),
  ];
  expect(AurenHomeUtilityLedger.latestUsage(duplicateTime, 'main'), isNull);

  final changedUnit = [
   makeReading(id: 'a', value: 10, day: 1, unit: 'kWh'),
   makeReading(id: 'b', value: 12, day: 2, unit: 'MWh'),
   makeReading(id: 'c', value: 15, day: 3, unit: 'MWh'),
  ];
  expect(AurenHomeUtilityLedger.latestUsage(changedUnit, 'main'), isNull);
 });
}
