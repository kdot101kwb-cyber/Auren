import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Four community extensions that remain on this device until a user explicitly
/// chooses a future sharing flow. Nothing here publishes or contacts members.
class AurenCommunityMemberExtensionsService {
  AurenCommunityMemberExtensionsService({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _prefix = 'auren.community_member_extensions.v1.';
  static const _maxItems = 100;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  String _key(String communityId, String feature) {
    final id = communityId.trim();
    if (id.isEmpty || id.length > 160) {
      throw ArgumentError('A valid community ID is required.');
    }
    return '$_prefix$id.$feature';
  }

  Future<List<Map<String, dynamic>>> _read(
    String communityId,
    String feature,
  ) async {
    final raw = (await _store).getString(_key(communityId, feature));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ).where((item) => item['id'] is String && (item['id'] as String).isNotEmpty)
          .take(_maxItems).toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> _add(
    String communityId,
    String feature,
    Map<String, dynamic> item,
  ) async {
    final items = await _read(communityId, feature);
    if (items.length >= _maxItems) {
      throw StateError('The local item limit has been reached.');
    }
    items.insert(0, item);
    await (await _store).setString(
      _key(communityId, feature),
      jsonEncode(items),
    );
  }

  Future<void> _remove(
    String communityId,
    String feature,
    String id,
  ) async {
    final items = await _read(communityId, feature);
    items.removeWhere((item) => item['id'] == id);
    await (await _store).setString(
      _key(communityId, feature),
      jsonEncode(items),
    );
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<List<Map<String, dynamic>>> translations(String communityId) =>
      _read(communityId, 'translations');

  Future<void> addTranslation({
    required String communityId,
    required String sourceText,
    required String translatedText,
    required String language,
  }) async {
    final source = sourceText.trim();
    final translated = translatedText.trim();
    final lang = language.trim();
    if (source.isEmpty || source.length > 1000 ||
        translated.isEmpty || translated.length > 1000 ||
        lang.isEmpty || lang.length > 60) {
      throw ArgumentError('Translation fields are required and must be bounded.');
    }
    await _add(communityId, 'translations', {
      'id': _id(), 'sourceText': source, 'translatedText': translated,
      'language': lang, 'status': 'draft', 'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeTranslation(String communityId, String id) =>
      _remove(communityId, 'translations', id);

  Future<List<Map<String, dynamic>>> volunteerHours(String communityId) =>
      _read(communityId, 'volunteer_hours');

  Future<void> addVolunteerHours({
    required String communityId,
    required String activity,
    required double hours,
    required DateTime date,
  }) async {
    final label = activity.trim();
    if (label.isEmpty || label.length > 120 ||
        !hours.isFinite || hours <= 0 || hours > 24) {
      throw ArgumentError('Enter an activity and hours between 0 and 24.');
    }
    await _add(communityId, 'volunteer_hours', {
      'id': _id(), 'activity': label, 'hours': hours,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    });
  }

  Future<void> removeVolunteerHours(String communityId, String id) =>
      _remove(communityId, 'volunteer_hours', id);

  Future<Map<String, dynamic>> availability(String communityId) async {
    final store = await _store;
    final raw = store.getString(_key(communityId, 'availability'));
    if (raw == null) return {'visible': false, 'text': ''};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final text = decoded['text'];
        return {
          'visible': decoded['visible'] == true,
          'text': text is String ? text : '',
        };
      }
    } on FormatException {
      // Return a safe empty profile when the cached value is malformed.
    }
    return {'visible': false, 'text': ''};
  }

  Future<void> saveAvailability({
    required String communityId,
    required String text,
    required bool visible,
  }) async {
    final clean = text.trim();
    if (clean.length > 500) {
      throw ArgumentError('Availability notes must be 500 characters or fewer.');
    }
    await (await _store).setString(_key(communityId, 'availability'),
      jsonEncode({'visible': visible, 'text': clean}));
  }

  Future<List<Map<String, dynamic>>> glossary(String communityId) =>
      _read(communityId, 'glossary');

  Future<void> addGlossaryTerm({
    required String communityId,
    required String term,
    required String meaning,
    required String language,
  }) async {
    final cleanTerm = term.trim(), cleanMeaning = meaning.trim();
    final cleanLanguage = language.trim();
    if (cleanTerm.isEmpty || cleanTerm.length > 120 ||
        cleanMeaning.isEmpty || cleanMeaning.length > 500 ||
        cleanLanguage.isEmpty || cleanLanguage.length > 60) {
      throw ArgumentError('Glossary term, meaning, and language are required.');
    }
    await _add(communityId, 'glossary', {
      'id': _id(), 'term': cleanTerm, 'meaning': cleanMeaning,
      'language': cleanLanguage,
    });
  }

  Future<void> removeGlossaryTerm(String communityId, String id) =>
      _remove(communityId, 'glossary', id);
}
