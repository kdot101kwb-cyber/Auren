import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/domain/notification_preferences.dart';

/// Device-local preference store scoped by Firebase user ID.
/// It does not affect FCM permissions, external delivery, or Messenger.
class AurenNotificationPreferencesStore {
  const AurenNotificationPreferencesStore({SharedPreferences? preferences})
      : _provided = preferences;

  final SharedPreferences? _provided;
  static const _prefix = 'auren_notification_preferences_v1_';

  Future<SharedPreferences> get _prefs async =>
      _provided ?? SharedPreferences.getInstance();

  String _key(String uid) {
    final value = uid.trim();
    if (value.isEmpty || value.length > 128 || value.contains('/')) {
      throw ArgumentError('Invalid user ID.');
    }
    return '$_prefix$value';
  }

  Future<AurenNotificationPreferences> load(String uid) async {
    final raw = (await _prefs).getString(_key(uid));
    if (raw == null) return const AurenNotificationPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const AurenNotificationPreferences();
      return AurenNotificationPreferences.fromJson(
        Map<String, Object?>.from(decoded),
      );
    } catch (_) {
      return const AurenNotificationPreferences();
    }
  }

  Future<bool> save(String uid, AurenNotificationPreferences preferences) =>
      _prefs.then((prefs) => prefs.setString(_key(uid), jsonEncode(preferences.toJson())));

  Future<bool> clear(String uid) => _prefs.then((prefs) => prefs.remove(_key(uid)));
}
