import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/everyday/household_inventory_service.dart';
import 'package:auren/services/everyday/household_inventory_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AurenHouseholdItem item({
    String id = 'rice',
    String name = 'Rice',
    double quantity = 2,
    double threshold = 1,
  }) => AurenHouseholdItem(
    id: id,
    name: name,
    category: 'Kitchen',
    quantity: quantity,
    lowStockThreshold: threshold,
    unit: 'kg',
  );

  test('stores and reloads items within a UID namespace', () async {
    final store = AurenHouseholdInventoryStore();
    await store.saveItem('user-A', item());
    await store.saveItem('user-B', item(id: 'beans', name: 'Beans'));

    expect((await store.loadItems('user-A')).map((e) => e.id), ['rice']);
    expect((await store.loadItems('user-B')).map((e) => e.id), ['beans']);
    expect(await store.loadItems('user-C'), isEmpty);
  });

  test('rejects blank UID and invalid item without writing', () async {
    final store = AurenHouseholdInventoryStore();
    await expectLater(store.loadItems('  '), throwsArgumentError);
    await expectLater(
      store.saveItem('user-A', item(quantity: double.nan)),
      throwsArgumentError,
    );
    expect(await store.loadItems('user-A'), isEmpty);
  });

  test('rejects an unsupported document version without overwriting original data', () async {
    final store = AurenHouseholdInventoryStore();
    final prefs = await SharedPreferences.getInstance();
    final key = 'auren_household_inventory_v1_${base64Url.encode(utf8.encode('user-A'))}';
    const original = '{"version":2,"items":[],"movements":[]}';
    await prefs.setString(key, original);

    await expectLater(store.loadItems('user-A'), throwsFormatException);
    await expectLater(store.loadMovements('user-A'), throwsFormatException);
    await expectLater(store.saveItem('user-A', item()), throwsFormatException);

    expect(prefs.getString(key), original);
  });

  test('updates item metadata but preserves existing stock quantity', () async {
    final store = AurenHouseholdInventoryStore();
    await store.saveItem('user-A', item(quantity: 7));
    await store.saveItem('user-A', item(name: 'Brown Rice', quantity: 99, threshold: 3));

    final stored = await store.loadItems('user-A');
    expect(stored, hasLength(1));
    expect(stored.single.name, 'Brown Rice');
    expect(stored.single.quantity, 7);
    expect(stored.single.lowStockThreshold, 3);
  });

  test('records a stock movement and reloads its audit history', () async {
    final store = AurenHouseholdInventoryStore();
    await store.saveItem('user-A', item());
    final movement = AurenHouseholdStockMovement(
      id: 'move-1',
      itemId: 'rice',
      type: AurenStockMovementType.restock,
      amount: 3,
      occurredAt: DateTime.utc(2026, 10, 20, 12),
      note: 'Bought at market',
    );

    final updated = await store.recordMovement('user-A', movement);
    expect(updated.quantity, 5);
    expect((await store.loadItems('user-A')).single.quantity, 5);
    final history = await store.loadMovements('user-A');
    expect(history, hasLength(1));
    expect(history.single.id, 'move-1');
    expect(history.single.note, 'Bought at market');
  });

  test('rejects duplicate movement and invalid consumption without changing stock', () async {
    final store = AurenHouseholdInventoryStore();
    await store.saveItem('user-A', item());
    final movement = AurenHouseholdStockMovement(
      id: 'move-1',
      itemId: 'rice',
      type: AurenStockMovementType.consume,
      amount: 1,
      occurredAt: DateTime.utc(2026, 10, 20),
    );
    await store.recordMovement('user-A', movement);

    await expectLater(
      store.recordMovement('user-A', movement),
      throwsArgumentError,
    );
    await expectLater(
      store.recordMovement('user-A', AurenHouseholdStockMovement(
        id: 'move-2',
        itemId: 'rice',
        type: AurenStockMovementType.consume,
        amount: 50,
        occurredAt: DateTime.utc(2026, 10, 21),
      )),
      throwsStateError,
    );
    expect((await store.loadItems('user-A')).single.quantity, 1);
    expect(await store.loadMovements('user-A'), hasLength(1));
  });

  test('rejects movement for missing item without creating history', () async {
    final store = AurenHouseholdInventoryStore();
    await expectLater(
      store.recordMovement('user-A', AurenHouseholdStockMovement(
        id: 'move-1',
        itemId: 'missing',
        type: AurenStockMovementType.restock,
        amount: 1,
        occurredAt: DateTime.utc(2026, 10, 20),
      )),
      throwsArgumentError,
    );
    expect(await store.loadMovements('user-A'), isEmpty);
  });
}
