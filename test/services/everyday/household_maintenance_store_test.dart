import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/household_maintenance_service.dart';
import 'package:auren/services/everyday/household_maintenance_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AurenMaintenanceTask makeTask({int? cost = 2500}) => AurenMaintenanceTask(
        id: 'leak',
        title: 'Fix leak',
        area: 'Kitchen',
        dueAt: DateTime.now().add(const Duration(days: 2)),
        estimatedCostMinor: cost,
      );

  test('isolates saved tasks by UID', () async {
    final store = AurenHouseholdMaintenanceStore();
    await store.saveTask('user-a', makeTask());
    expect((await store.loadTasks('user-a')).single.id, 'leak');
    expect(await store.loadTasks('user-b'), isEmpty);
  });

  test('rejects blank UID and invalid cost', () async {
    final store = AurenHouseholdMaintenanceStore();
    await expectLater(store.loadTasks(''), throwsArgumentError);
    await expectLater(store.saveTask('user-a', makeTask(cost: -1)), throwsArgumentError);
  });

  test('rejects duplicate stored task IDs and preserves the original data', () async {
    final store = AurenHouseholdMaintenanceStore();
    final prefs = await SharedPreferences.getInstance();
    final key = 'auren_household_maintenance_v1_${base64Url.encode(utf8.encode('user-a'))}';
    const original = '{"version":1,"items":['
        '{"id":"leak","title":"First","area":"Kitchen","status":"planned"},'
        '{"id":"leak","title":"Second","area":"Bathroom","status":"planned"}'
        ']}';
    await prefs.setString(key, original);

    await expectLater(store.loadTasks('user-a'), throwsFormatException);
    await expectLater(store.saveTask('user-a', makeTask()), throwsFormatException);
    expect(prefs.getString(key), original);
  });
}
