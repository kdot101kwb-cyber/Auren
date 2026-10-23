import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Private, device-local list of support resources chosen by the user.
class AurenWomenSupportResource {
  const AurenWomenSupportResource({
    required this.id,
    required this.title,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory AurenWomenSupportResource.fromMap(Map<String, dynamic> map) =>
      AurenWomenSupportResource(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        notes: map['notes']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class AurenWomenSupportResourceService {
  AurenWomenSupportResourceService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _storageKey = 'auren.women.support_resources.v1';
  static const maxResources = 100;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<AurenWomenSupportResource>> list() async {
    final raw = (await _store).getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) =>
              AurenWomenSupportResource.fromMap(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
          .take(maxResources)
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<String> add({required String title, String notes = ''}) async {
    final cleanTitle = title.trim();
    final cleanNotes = notes.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120 || cleanNotes.length > 500) {
      throw ArgumentError('العنوان أو الملاحظات غير صالحة.');
    }
    final items = await list();
    if (items.length >= maxResources) {
      throw StateError('تم الوصول إلى الحد الأقصى للعناصر.');
    }
    final now = DateTime.now().toUtc();
    final id = now.microsecondsSinceEpoch.toString();
    items.insert(0, AurenWomenSupportResource(
      id: id,
      title: cleanTitle,
      notes: cleanNotes,
      createdAt: now,
    ));
    await (await _store).setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toMap()).toList()),
    );
    return id;
  }

  Future<void> remove(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) throw ArgumentError('معرّف العنصر مطلوب.');
    final items = await list()
      ..removeWhere((item) => item.id == cleanId);
    await (await _store).setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toMap()).toList()),
    );
  }
}
