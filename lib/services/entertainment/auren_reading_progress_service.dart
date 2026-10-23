import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum AurenReadingStatus { wantToRead, inProgress, completed }

class AurenReadingProgress {
  const AurenReadingProgress({
    required this.itemId,
    required this.title,
    required this.status,
    required this.updatedAt,
  });

  final String itemId;
  final String title;
  final AurenReadingStatus status;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'title': title,
        'status': status.name,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory AurenReadingProgress.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? '';
    final matches = AurenReadingStatus.values
        .where((value) => value.name == statusName)
        .toList();
    final status = matches.isEmpty ? AurenReadingStatus.wantToRead : matches.first;
    return AurenReadingProgress(
      itemId: map['itemId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: status,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// Reading state is a private, bounded device-local shelf; no content is downloaded.
class AurenReadingProgressService {
  AurenReadingProgressService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _key = 'auren.reading_progress.v1';
  static const maxItems = 300;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<AurenReadingProgress>> list() async {
    final raw = (await _store).getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => AurenReadingProgress.fromMap(
              Map<String, dynamic>.from(item)))
          .where((item) => item.itemId.isNotEmpty && item.title.isNotEmpty)
          .take(maxItems)
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<AurenReadingProgress?> get(String itemId) async {
    final id = itemId.trim();
    if (id.isEmpty) return null;
    for (final item in await list()) {
      if (item.itemId == id) return item;
    }
    return null;
  }

  Future<void> setStatus({
    required String itemId,
    required String title,
    required AurenReadingStatus status,
  }) async {
    final id = itemId.trim();
    final name = title.trim();
    if (id.isEmpty || id.length > 240 || name.isEmpty || name.length > 240) {
      throw ArgumentError('Reading item metadata is invalid.');
    }
    final store = await _store;
    final items = await list();
    items.removeWhere((item) => item.itemId == id);
    if (items.length >= maxItems) {
      throw StateError('Reading shelf limit reached.');
    }
    items.insert(0, AurenReadingProgress(
      itemId: id,
      title: name,
      status: status,
      updatedAt: DateTime.now().toUtc(),
    ));
    await store.setString(_key, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<void> remove(String itemId) async {
    final id = itemId.trim();
    if (id.isEmpty) throw ArgumentError('Reading item ID is required.');
    final store = await _store;
    final items = await list();
    items.removeWhere((item) => item.itemId == id);
    await store.setString(_key, jsonEncode(items.map((item) => item.toMap()).toList()));
  }
}
