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
}
