import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AurenLocaleController extends ChangeNotifier {
  static const _key = 'auren_locale';
  String? _languageCode;
  String? get languageCode => _languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_key);
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }
}
