import 'package:flutter/foundation.dart';

/// User-owned household stock item. This model does not place orders.
@immutable
class AurenHouseholdItem {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final double lowStockThreshold;
  final String unit;
  final String notes;

  const AurenHouseholdItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.lowStockThreshold,
    required this.unit,
    this.notes = '',
  });

  bool get needsRestock => quantity <= lowStockThreshold;

  String? validate() {
    if (id.trim().isEmpty) return 'Item id is required.';
    if (name.trim().isEmpty || name.trim().length > 120) {
      return 'Item name must contain 1–120 characters.';
    }
    if (category.trim().isEmpty || category.trim().length > 60) {
      return 'Category must contain 1–60 characters.';
    }
    if (!quantity.isFinite || quantity < 0) return 'Quantity must be finite and non-negative.';
    if (!lowStockThreshold.isFinite || lowStockThreshold < 0) {
      return 'Restock threshold must be finite and non-negative.';
    }
    if (unit.trim().isEmpty || unit.trim().length > 24) return 'A valid unit is required.';
    if (notes.length > 1000) return 'Notes are too long.';
    return null;
  }
}

/// Pure local calculation; no supplier or delivery service is contacted.
class AurenHouseholdRestockPlanner {
  const AurenHouseholdRestockPlanner._();

  static List<AurenHouseholdItem> itemsToRestock(
    Iterable<AurenHouseholdItem> items,
  ) => items.where((item) => item.validate() == null && item.needsRestock).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
