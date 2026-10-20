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

  AurenHouseholdItem copyWith({double? quantity}) => AurenHouseholdItem(
    id: id,
    name: name,
    category: category,
    quantity: quantity ?? this.quantity,
    lowStockThreshold: lowStockThreshold,
    unit: unit,
    notes: notes,
  );
}

/// Pure local calculation; no supplier or delivery service is contacted.
class AurenHouseholdRestockPlanner {
  const AurenHouseholdRestockPlanner._();

  static List<AurenHouseholdItem> itemsToRestock(
    Iterable<AurenHouseholdItem> items,
  ) => items.where((item) => item.validate() == null && item.needsRestock).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// A local stock adjustment. It is not persisted and never places an order.
enum AurenStockMovementType { restock, consume }

@immutable
class AurenHouseholdStockMovement {
  final String id;
  final String itemId;
  final AurenStockMovementType type;
  final double amount;
  final String note;
  final DateTime occurredAt;

  const AurenHouseholdStockMovement({
    required this.id,
    required this.itemId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.note = '',
  });

  String? validate() {
    if (id.trim().isEmpty) return 'Movement id is required.';
    if (itemId.trim().isEmpty) return 'Item id is required.';
    if (!amount.isFinite || amount <= 0) {
      return 'Movement amount must be finite and greater than zero.';
    }
    if (note.length > 500) return 'Movement note is too long.';
    return null;
  }

  /// Returns an updated immutable item; callers decide whether/how to persist it.
  AurenHouseholdItem applyTo(AurenHouseholdItem item) {
    final movementIssue = validate();
    if (movementIssue != null) throw ArgumentError(movementIssue);
    final itemIssue = item.validate();
    if (itemIssue != null) throw ArgumentError(itemIssue);
    if (item.id != itemId) {
      throw ArgumentError('Movement item id does not match the supplied item.');
    }

    final nextQuantity = type == AurenStockMovementType.restock
        ? item.quantity + amount
        : item.quantity - amount;
    if (!nextQuantity.isFinite || nextQuantity < 0) {
      throw StateError('Stock movement would produce an invalid quantity.');
    }
    return item.copyWith(quantity: nextQuantity);
  }
}

/// Replays a validated movement history deterministically, without persistence.
class AurenHouseholdStockLedger {
  const AurenHouseholdStockLedger._();

  static AurenHouseholdItem replay(
    AurenHouseholdItem initial,
    Iterable<AurenHouseholdStockMovement> movements,
  ) {
    final ordered = movements.toList()
      ..sort((a, b) {
        final byTime = a.occurredAt.compareTo(b.occurredAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    final seenIds = <String>{};
    var current = initial;
    for (final movement in ordered) {
      if (!seenIds.add(movement.id)) {
        throw ArgumentError('Duplicate stock movement id: ${movement.id}.');
      }
      current = movement.applyTo(current);
    }
    return current;
  }
}
