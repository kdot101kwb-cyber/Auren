import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'household_inventory_service.dart';

/// Device-local inventory storage scoped by authenticated Firebase UID.
///
/// This is intentionally not cloud sync: the data lives on this device and
/// can be lost if app data is cleared or the app is removed.
class AurenHouseholdInventoryStore {
  AurenHouseholdInventoryStore({SharedPreferences? preferences})
      : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;
  static const _keyPrefix = 'auren_household_inventory_v1_';

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? SharedPreferences.getInstance();

  String _keyFor(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'Authenticated user id is required.');
    }
    // Firebase UIDs are opaque strings. Encode to avoid key delimiter issues.
    return '$_keyPrefix${base64Url.encode(utf8.encode(normalized))}';
  }

  Future<List<AurenHouseholdItem>> loadItems(String uid) async {
    final prefs = await _preferences;
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null || raw.isEmpty) return <AurenHouseholdItem>[];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored household inventory has an invalid shape.');
    }
    _validateDocumentVersion(decoded);
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const FormatException('Stored household inventory has no item list.');
    }
    final items = rawItems.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Stored household item is invalid.');
      }
      final item = _itemFromJson(Map<String, dynamic>.from(entry));
      final issue = item.validate();
      if (issue != null) throw FormatException('Stored household item is invalid: $issue');
      return item;
    }).toList();
    return List.unmodifiable(items);
  }

  Future<List<AurenHouseholdStockMovement>> loadMovements(String uid) async {
    final prefs = await _preferences;
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null || raw.isEmpty) return <AurenHouseholdStockMovement>[];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored household inventory has an invalid shape.');
    }
    _validateDocumentVersion(decoded);
    final rawMovements = decoded['movements'] ?? const <dynamic>[];
    if (rawMovements is! List) {
      throw const FormatException('Stored household movement history is invalid.');
    }
    final movements = rawMovements.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Stored household movement is invalid.');
      }
      final movement = _movementFromJson(Map<String, dynamic>.from(entry));
      final issue = movement.validate();
      if (issue != null) throw FormatException('Stored movement is invalid: $issue');
      return movement;
    }).toList()
      ..sort((a, b) {
        final time = a.occurredAt.compareTo(b.occurredAt);
        return time != 0 ? time : a.id.compareTo(b.id);
      });
    return List.unmodifiable(movements);
  }

  /// Adds a new item or replaces metadata for an existing ID without changing
  /// its current quantity. Invalid items are rejected before any write.
  Future<void> saveItem(String uid, AurenHouseholdItem item) async {
    final issue = item.validate();
    if (issue != null) throw ArgumentError(issue);
    final prefs = await _preferences;
    final key = _keyFor(uid);
    final data = _readDocument(prefs.getString(key));
    final items = _itemsFromDocument(data);
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = AurenHouseholdItem(
        id: item.id,
        name: item.name,
        category: item.category,
        quantity: items[index].quantity,
        lowStockThreshold: item.lowStockThreshold,
        unit: item.unit,
        notes: item.notes,
      );
    }
    await _writeDocument(prefs, key, items, _movementsFromDocument(data));
  }

  /// Applies a stock movement and stores the resulting item plus audit entry
  /// in one SharedPreferences value. This is device-local, not transactional
  /// across devices, and not a substitute for server-side authorization.
  Future<AurenHouseholdItem> recordMovement(
    String uid,
    AurenHouseholdStockMovement movement,
  ) async {
    final issue = movement.validate();
    if (issue != null) throw ArgumentError(issue);
    final prefs = await _preferences;
    final key = _keyFor(uid);
    final data = _readDocument(prefs.getString(key));
    final items = _itemsFromDocument(data);
    final movements = _movementsFromDocument(data);
    if (movements.any((existing) => existing.id == movement.id)) {
      throw ArgumentError('Duplicate stock movement id: ${movement.id}.');
    }
    final index = items.indexWhere((item) => item.id == movement.itemId);
    if (index == -1) throw ArgumentError('Household item was not found.');
    final updated = movement.applyTo(items[index]);
    items[index] = updated;
    movements.add(movement);
    await _writeDocument(prefs, key, items, movements);
    return updated;
  }

  Map<String, dynamic> _readDocument(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{'items': <dynamic>[], 'movements': <dynamic>[]};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored household inventory has an invalid shape.');
    }
    _validateDocumentVersion(decoded);
    return decoded;
  }

  void _validateDocumentVersion(Map<String, dynamic> data) {
    // Documents written before versioning are treated as legacy v1. Never
    // rewrite an explicitly newer or malformed version with this older client.
    final version = data['version'];
    if (version != null && (version is! int || version != 1)) {
      throw FormatException('Unsupported household inventory version: $version.');
    }
  }

  List<AurenHouseholdItem> _itemsFromDocument(Map<String, dynamic> data) {
    final rawItems = data['items'] ?? const <dynamic>[];
    if (rawItems is! List) {
      throw const FormatException('Stored household inventory has no item list.');
    }
    return rawItems.map((entry) {
      if (entry is! Map) throw const FormatException('Stored household item is invalid.');
      final item = _itemFromJson(Map<String, dynamic>.from(entry));
      final issue = item.validate();
      if (issue != null) throw FormatException('Stored household item is invalid: $issue');
      return item;
    }).toList();
  }

  List<AurenHouseholdStockMovement> _movementsFromDocument(
    Map<String, dynamic> data,
  ) {
    final rawMovements = data['movements'] ?? const <dynamic>[];
    if (rawMovements is! List) {
      throw const FormatException('Stored household movement history is invalid.');
    }
    return rawMovements.map((entry) {
      if (entry is! Map) throw const FormatException('Stored household movement is invalid.');
      final movement = _movementFromJson(Map<String, dynamic>.from(entry));
      final issue = movement.validate();
      if (issue != null) throw FormatException('Stored movement is invalid: $issue');
      return movement;
    }).toList();
  }

  Future<void> _writeDocument(
    SharedPreferences prefs,
    String key,
    List<AurenHouseholdItem> items,
    List<AurenHouseholdStockMovement> movements,
  ) async {
    final document = <String, dynamic>{
      'version': 1,
      'items': items.map(_itemToJson).toList(),
      'movements': movements.map(_movementToJson).toList(),
    };
    final saved = await prefs.setString(key, jsonEncode(document));
    if (!saved) throw StateError('Could not save household inventory on this device.');
  }

  static Map<String, dynamic> _itemToJson(AurenHouseholdItem item) => {
    'id': item.id,
    'name': item.name,
    'category': item.category,
    'quantity': item.quantity,
    'lowStockThreshold': item.lowStockThreshold,
    'unit': item.unit,
    'notes': item.notes,
  };

  static AurenHouseholdItem _itemFromJson(Map<String, dynamic> json) =>
      AurenHouseholdItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        lowStockThreshold: (json['lowStockThreshold'] as num).toDouble(),
        unit: json['unit'] as String,
        notes: json['notes'] as String? ?? '',
      );

  static Map<String, dynamic> _movementToJson(
    AurenHouseholdStockMovement movement,
  ) => {
    'id': movement.id,
    'itemId': movement.itemId,
    'type': movement.type.name,
    'amount': movement.amount,
    'note': movement.note,
    'occurredAt': movement.occurredAt.toUtc().toIso8601String(),
  };

  static AurenHouseholdStockMovement _movementFromJson(
    Map<String, dynamic> json,
  ) {
    final typeName = json['type'] as String;
    final type = switch (typeName) {
      'restock' => AurenStockMovementType.restock,
      'consume' => AurenStockMovementType.consume,
      _ => throw const FormatException('Unknown stock movement type.'),
    };
    return AurenHouseholdStockMovement(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      type: type,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
    );
  }
}
