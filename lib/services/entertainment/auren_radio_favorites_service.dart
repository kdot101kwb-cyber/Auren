import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AurenRadioFavorite {
  const AurenRadioFavorite({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.country = '',
    this.language = '',
    this.tags = '',
  });

  final String id;
  final String name;
  final String streamUrl;
  final String country;
  final String language;
  final String tags;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'country': country,
        'language': language,
        'tags': tags,
      };

  factory AurenRadioFavorite.fromMap(Map<String, dynamic> map) =>
      AurenRadioFavorite(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        streamUrl: map['streamUrl'] as String? ?? '',
        country: map['country'] as String? ?? '',
        language: map['language'] as String? ?? '',
        tags: map['tags'] as String? ?? '',
      );
}

/// Keeps a bounded list of radio favorites on the current device.
class AurenRadioFavoritesService {
  AurenRadioFavoritesService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _key = 'auren.radio_favorites.v1';
  static const maxFavorites = 100;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<AurenRadioFavorite>> list() async {
    final raw = (await _store).getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => AurenRadioFavorite.fromMap(
              Map<String, dynamic>.from(item)))
          .where((item) =>
              item.id.isNotEmpty &&
              item.name.isNotEmpty &&
              _validStream(item.streamUrl))
          .take(maxFavorites)
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<bool> contains(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return false;
    return (await list()).any((item) => item.id == normalized);
  }

  Future<void> save(AurenRadioFavorite favorite) async {
    final id = favorite.id.trim();
    final name = favorite.name.trim();
    if (id.isEmpty || id.length > 180 || name.isEmpty || name.length > 180 ||
        favorite.streamUrl.length > 2048 || !_validStream(favorite.streamUrl)) {
      throw ArgumentError('Radio favorite metadata is invalid.');
    }
    final store = await _store;
    final items = await list();
    items.removeWhere((item) => item.id == id);
    if (items.length >= maxFavorites) {
      throw StateError('Radio favorites limit reached.');
    }
    items.insert(0, AurenRadioFavorite(
      id: id,
      name: name,
      streamUrl: favorite.streamUrl.trim(),
      country: favorite.country.trim().substring(
          0, favorite.country.trim().length.clamp(0, 80)),
      language: favorite.language.trim().substring(
          0, favorite.language.trim().length.clamp(0, 80)),
      tags: favorite.tags.trim().substring(
          0, favorite.tags.trim().length.clamp(0, 300)),
    ));
    await store.setString(_key, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<void> remove(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) throw ArgumentError('Favorite ID is required.');
    final store = await _store;
    final items = await list();
    items.removeWhere((item) => item.id == normalized);
    await store.setString(_key, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  static bool _validStream(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        const {'http', 'https'}.contains(uri.scheme.toLowerCase()) &&
        uri.host.isNotEmpty;
  }
}
