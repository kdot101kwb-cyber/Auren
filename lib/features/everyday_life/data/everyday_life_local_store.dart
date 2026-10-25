import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/everyday_life_item.dart';

typedef EverydayLifeWriteString = Future<bool> Function(
  SharedPreferences preferences,
  String key,
  String value,
);

class EverydayLifeLocalStore {
  EverydayLifeLocalStore({
    SharedPreferences? preferences,
    EverydayLifeWriteString? writeString,
  })  : _preferences = preferences,
        _writeString = writeString;

  static const storageKey = 'auren_everyday_life_records_v1';
  final SharedPreferences? _preferences;
  final EverydayLifeWriteString? _writeString;

  // Every store instance writes the same local JSON document. Use one
  // queue so concurrent read-modify-write operations cannot overwrite one
  // another with stale snapshots.
  static Future<void> _mutationTail = Future<void>.value();

  Future<T> _serializeMutation<T>(Future<T> Function() operation) {
    final previous = _mutationTail;
    final next = Completer<void>();
    _mutationTail = next.future;
    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        next.complete();
      }
    }();
  }

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<EverydayLifeItem>> readAll() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw StateError(
          'Stored AUREN Everyday Life data has an invalid format; '
          'refusing to overwrite it.',
        );
      }
      final records = <EverydayLifeItem>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        try {
          records.add(EverydayLifeItem.fromJson(
            Map<String, dynamic>.from(entry),
          ));
        } on FormatException {
          // Skip one damaged record rather than losing all locally saved data.
        } on TypeError {
          // Skip malformed records and preserve the rest.
        }
      }
      return List.unmodifiable(records);
    } on FormatException {
      // Do not treat a damaged top-level payload as an empty store: the next
      // write would silently replace the original bytes and lose recoverable
      // local data. Individual malformed records above remain skippable.
      throw StateError(
        'Stored AUREN Everyday Life data is corrupted; '
        'refusing to overwrite it.',
      );
    }
  }

  Future<void> save(EverydayLifeItem item) =>
      _serializeMutation(() => _save(item));

  Future<void> _save(EverydayLifeItem item) async {
    if (item.id.trim().isEmpty || item.title.trim().isEmpty) {
      throw ArgumentError('A record needs an ID and a non-empty title.');
    }
    final records = (await readAll()).toList();
    final index = records.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      records.add(item);
    } else {
      if (records[index].kind != item.kind) {
        // IDs are global within this feature. Never let an accidental ID
        // collision in another system silently replace a saved record.
        throw StateError(
          'Record ID "${item.id}" already belongs to '
          '${records[index].kind.name}, not ${item.kind.name}.',
        );
      }
      records[index] = item;
    }
    await _write(records);
  }

  Future<void> delete(String id) =>
      _serializeMutation(() => _delete(id));

  Future<void> _delete(String id) async {
    final records = (await readAll()).where((entry) => entry.id != id).toList();
    await _write(records);
  }

  /// Removes every Everyday Life record from this device.
  ///
  /// This is intentionally scoped to this feature's storage key; it does not
  /// clear unrelated app preferences or remote data.
  Future<void> clearAll() => _serializeMutation(_clearAll);

  Future<void> _clearAll() async {
    final preferences = await _prefs;
    // Erasure is idempotent: an empty store is already in the desired state.
    if (!preferences.containsKey(storageKey)) return;

    final removed = await preferences.remove(storageKey);
    if (!removed && preferences.containsKey(storageKey)) {
      throw StateError(
        'Unable to clear AUREN Everyday Life records from this device.',
      );
    }
  }

  Future<void> _write(List<EverydayLifeItem> records) async {
    final raw = jsonEncode(records.map((entry) => entry.toJson()).toList());
    final preferences = await _prefs;
    final saved = await (_writeString?.call(preferences, storageKey, raw) ??
        preferences.setString(storageKey, raw));
    if (!saved) {
      // SharedPreferences can report a failed write without throwing.
      // Surface it so callers never mistake an unsaved change for success.
      throw StateError('Unable to persist AUREN Everyday Life records locally.');
    }
  }
}
