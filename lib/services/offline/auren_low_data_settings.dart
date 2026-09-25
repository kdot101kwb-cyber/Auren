import 'package:shared_preferences/shared_preferences.dart';

/// User-controlled low-data preference for media/network layers.
class AurenLowDataSettings {
  AurenLowDataSettings._();
  static final AurenLowDataSettings instance = AurenLowDataSettings._();

  static const _enabledKey = 'auren_low_data_mode_v1';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> toggle() async {
    final enabled = !(await isEnabled());
    await setEnabled(enabled);
    return enabled;
  }
}
