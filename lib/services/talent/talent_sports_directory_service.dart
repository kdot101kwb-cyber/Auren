import 'dart:convert';

import 'package:http/http.dart' as http;

/// Extended directory endpoints kept separate from the core sports service.
///
/// The free V1 API exposes countries, sports, leagues, league teams and
/// team players. Premium V2 provides larger list limits and the same
/// relationships with dedicated list endpoints.
class TalentSportsDirectoryService {
  static const _base = 'https://www.thesportsdb.com/api/v1/json/123';

  Future<List<Map<String, dynamic>>> allLeagues() async {
    final data = await _get('/all_leagues.php', {});
    return _maps(data['leagues']);
  }

  Future<List<Map<String, dynamic>>> leaguesByCountryAndSport({
    required String country,
    required String sport,
  }) async {
    final data = await _get('/search_all_leagues.php', {
      'c': country,
      's': sport,
    });
    return _maps(data['countries']);
  }

  Future<List<Map<String, dynamic>>> teamsByLeague({
    required String league,
  }) async {
    final data = await _get('/search_all_teams.php', {'l': league});
    return _maps(data['teams']);
  }

  Future<List<Map<String, dynamic>>> teamsByCountryAndSport({
    required String country,
    required String sport,
  }) async {
    final data = await _get('/search_all_teams.php', {
      'c': country,
      's': sport,
    });
    return _maps(data['teams']);
  }

  Future<List<Map<String, dynamic>>> playersByTeam(String teamId) async {
    final data = await _get('/lookup_all_players.php', {'id': teamId});
    return _maps(data['player']);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final response = await http
        .get(Uri.parse(_base + path).replace(queryParameters: query))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Sports directory unavailable (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid sports directory response.');
    }
    return decoded;
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
