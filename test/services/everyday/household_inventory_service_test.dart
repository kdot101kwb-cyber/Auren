import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/everyday/household_inventory_service.dart';

void main() {
  AurenHouseholdItem item(String id, String name, double quantity, double threshold) =>
      AurenHouseholdItem(id: id, name: name, category: 'Kitchen',
        quantity: quantity, lowStockThreshold: threshold, unit: 'pieces');

  test('flags stock at or below threshold', () {
    expect(item('1', 'Rice', 1, 1).needsRestock, isTrue);
    expect(item('2', 'Soap', 2, 1).needsRestock, isFalse);
  });

  test('rejects negative or non-finite quantities', () {
    expect(item('1', 'Rice', -1, 2).validate(), isNotNull);
    expect(item('2', 'Rice', double.nan, 2).validate(), isNotNull);
    expect(item('3', 'Rice', 2, double.infinity).validate(), isNotNull);
  });

  test('rejects missing required fields', () {
    expect(item(' ', 'Rice', 1, 2).validate(), isNotNull);
    expect(item('1', ' ', 1, 2).validate(), isNotNull);
  });

  test('restock list excludes invalid entries and sorts by name', () {
    final result = AurenHouseholdRestockPlanner.itemsToRestock([
      item('1', 'Zaatar', 0, 1),
      item('2', 'Bread', 1, 1),
      item('3', 'Milk', 3, 1),
      item(' ', 'Invalid', 0, 1),
    ]);
    expect(result.map((e) => e.name).toList(), ['Bread', 'Zaatar']);
  });

  test('restock and consumption return updated immutable items', () {
    final original = item('rice', 'Rice', 2, 1);
    final restocked = AurenHouseholdStockMovement(
      id: 'm1', itemId: 'rice', type: AurenStockMovementType.restock,
      amount: 3, occurredAt: DateTime(2026, 10, 20),
    ).applyTo(original);
    expect(restocked.quantity, 5);
    expect(original.quantity, 2);

    final consumed = AurenHouseholdStockMovement(
      id: 'm2', itemId: 'rice', type: AurenStockMovementType.consume,
      amount: 1.5, occurredAt: DateTime(2026, 10, 21),
    ).applyTo(restocked);
    expect(consumed.quantity, 3.5);
  });

  test('rejects invalid movements, mismatched items, and consuming too much', () {
    AurenHouseholdStockMovement movement({
      String id = 'm1',
      String itemId = 'rice',
      double amount = 1,
      AurenStockMovementType type = AurenStockMovementType.consume,
    }) => AurenHouseholdStockMovement(
      id: id, itemId: itemId, type: type, amount: amount,
      occurredAt: DateTime(2026, 10, 20),
    );

    expect(movement(amount: 0).validate(), isNotNull);
    expect(movement(amount: double.infinity).validate(), isNotNull);
    expect(() => movement(itemId: 'other').applyTo(item('rice', 'Rice', 2, 1)),
      throwsArgumentError);
    expect(() => movement(amount: 3).applyTo(item('rice', 'Rice', 2, 1)),
      throwsStateError);
  });
}
