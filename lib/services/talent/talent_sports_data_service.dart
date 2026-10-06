import 'dart:convert';
import 'package:http/http.dart' as http;

class TalentSportsDataService {
  static const _base = 'https://www.thesportsdb.com/api/v1/json/123';

  String localized(dynamic item, String language) {
    const fields = <String, String>{
      'ar': 'strDescriptionAR',
      'de': 'strDescriptionDE',
      'es': 'strDescriptionES',
      'fr': 'strDescriptionFR',
      'it': 'strDescriptionIT',
      'pt': 'strDescriptionPT',
      'ru': 'strDescriptionRU',
      'ja': 'strDescriptionJP',
      'nl': 'strDescriptionNL',
      'pl': 'strDescriptionPL',
      'no': 'strDescriptionNO',
      'sv': 'strDescriptionSE',
      'zh': 'strDescriptionCN',
      'en': 'strDescriptionEN',
    };
    final key = fields[language] ?? fields['en']!;
    return (item[key] ?? item['strDescriptionEN'] ?? item['strDescription'] ?? '').toString();
  }

  Future<List<Map<String, dynamic>>> lookupTeam(String id) async {
    final data = await _get('/lookupteam.php', {'id': id});
    return _maps(data['teams']);
  }

  Future<List<Map<String, dynamic>>> lookupPlayer(String id) async {
    final data = await _get('/lookupplayer.php', {'id': id});
    return _maps(data['players']);
  }

  Future<List<Map<String, dynamic>>> lookupLeague(String id) async {
    final data = await _get('/lookupleague.php', {'id': id});
    return _maps(data['leagues']);
  }

  Future<List<Map<String, dynamic>>> searchLeagues(String query) async {
    final data = await _get('/searchleague.php', {'l': query});
    return _maps(data['leagues']);
  }

  Future<List<Map<String, dynamic>>> allCountries() async {
    final data = await _get('/all_countries.php', {});
    return _maps(data['countries']);
  }

  Future<List<Map<String, dynamic>>> allSports() async {
    final data = await _get('/all_sports.php', {});
    return _maps(data['sports']);
  }

  Future<List<Map<String, dynamic>>> searchTeams(String query) async {
    final data = await _get('/searchteams.php', {'t': query});
    return _maps(data['teams']);
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final data = await _get('/searchplayers.php', {'p': query});
    return _maps(data['player']);
  }

  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    final data = await _get('/searchevents.php', {'e': query});
    return _maps(data['event']);
  }

  Future<List<Map<String, dynamic>>> teamNextEvents(String teamId) async {
    final data = await _get('/eventsnext.php', {'id': teamId});
    return _maps(data['events']);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final response = await http
        .get(Uri.parse(_base + path).replace(queryParameters: query))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Sports data unavailable (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid sports data response.');
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
