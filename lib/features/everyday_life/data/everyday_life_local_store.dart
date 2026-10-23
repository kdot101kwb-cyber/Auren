import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/everyday_life_item.dart';

class EverydayLifeLocalStore {
  EverydayLifeLocalStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'auren_everyday_life_records_v1';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<EverydayLifeItem>> readAll() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
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
      return const [];
    }
  }

  Future<void> save(EverydayLifeItem item) async {
    if (item.id.trim().isEmpty || item.title.trim().isEmpty) {
      throw ArgumentError('A record needs an ID and a non-empty title.');
    }
    final records = (await readAll()).toList();
    final index = records.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      records.add(item);
    } else {
      records[index] = item;
    }
    await _write(records);
  }

  Future<void> delete(String id) async {
    final records = (await readAll()).where((entry) => entry.id != id).toList();
    await _write(records);
  }

  Future<void> _write(List<EverydayLifeItem> records) async {
    final raw = jsonEncode(records.map((entry) => entry.toJson()).toList());
    final saved = await (await _prefs).setString(storageKey, raw);
    if (!saved) {
      // SharedPreferences can report a failed write without throwing.
      // Surface it so callers never mistake an unsaved change for success.
      throw StateError('Unable to persist AUREN Everyday Life records locally.');
    }
  }
}
