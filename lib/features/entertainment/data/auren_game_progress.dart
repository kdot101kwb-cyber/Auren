import 'package:shared_preferences/shared_preferences.dart';

class AurenGameProgress {
  static const _prefix = 'auren_game_';

  static Future<void> save({
    required int gameIndex,
    required int score,
    required int round,
    required int wins,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefix + gameIndex.toString();
    final best = prefs.getInt(key + '_best') ?? 0;
    final storedWins = prefs.getInt(key + '_wins') ?? 0;
    if (score > best) await prefs.setInt(key + '_best', score);
    if (wins > storedWins) await prefs.setInt(key + '_wins', wins);
    await prefs.setInt(key + '_round', round);
  }

  static Future<Map<String, int>> load(int gameIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefix + gameIndex.toString();
    return {
      'best': prefs.getInt(key + '_best') ?? 0,
      'wins': prefs.getInt(key + '_wins') ?? 0,
      'round': prefs.getInt(key + '_round') ?? 0,
    };
  }
}
