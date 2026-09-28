import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AurenTvChannel {
  final String id, name, logo, country, language, category, url, tvgId;
  const AurenTvChannel({required this.id, required this.name, required this.logo, required this.country, required this.language, required this.category, required this.url, this.tvgId = ''});
}

class AurenTvSource {
  final String id, name, type, url, epgUrl, username, password;
  const AurenTvSource({required this.id, required this.name, required this.type, this.url = '', this.epgUrl = '', this.username = '', this.password = ''});
}

class AurenTvService {
  AurenTvService._();
  static final instance = AurenTvService._();
  static const playlist = 'https://iptv-org.github.io/iptv/index.country.m3u';
  static const entertainmentPlaylist = 'https://iptv-org.github.io/iptv/categories/entertainment.m3u';
  static const sportsPlaylist = 'https://iptv-org.github.io/iptv/categories/sports.m3u';
  static const newsPlaylist = 'https://iptv-org.github.io/iptv/categories/news.m3u';
  static const sudanPlaylist = 'https://iptv-org.github.io/iptv/countries/sd.m3u';
  static const moviesPlaylist = 'https://iptv-org.github.io/iptv/categories/movies.m3u';
  static const musicPlaylist = 'https://iptv-org.github.io/iptv/categories/music.m3u';
  static const kidsPlaylist = 'https://iptv-org.github.io/iptv/categories/kids.m3u';
  static const animationPlaylist = 'https://iptv-org.github.io/iptv/categories/animation.m3u';
  static const documentaryPlaylist = 'https://iptv-org.github.io/iptv/categories/documentary.m3u';
  static const seriesPlaylist = 'https://iptv-org.github.io/iptv/categories/series.m3u';
  List<AurenTvChannel>? _entertainmentCache;
  List<AurenTvChannel>? _sportsCache;
  List<AurenTvChannel>? _newsCache;
  List<AurenTvChannel>? _moviesCache;
  List<AurenTvChannel>? _musicCache;
  List<AurenTvChannel>? _kidsCache;
  List<AurenTvChannel>? _animationCache;
  List<AurenTvChannel>? _documentaryCache;
  List<AurenTvChannel>? _seriesCache;
  List<AurenTvChannel>? _cache;
  String? _epgUrl;
  Map<String, List<Map<String, String>>>? _epgCache;

  static const _sourcesKey = 'auren_tv_sources';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  List<AurenTvSource>? _sourcesCache;

  Future<List<AurenTvSource>> sources() async {
    if (_sourcesCache != null) return List.unmodifiable(_sourcesCache!);
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_sourcesKey) ?? const <String>[];
    final out = <AurenTvSource>[];
    for (final item in raw) {
      try {
        final m = jsonDecode(item) as Map<String, dynamic>;
        final id = m['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final password = await _secure.read(key: 'auren_tv_source_password_$id') ?? '';
        out.add(AurenTvSource(id: id, name: m['name']?.toString() ?? 'IPTV', type: m['type']?.toString() ?? 'm3u', url: m['url']?.toString() ?? '', epgUrl: m['epgUrl']?.toString() ?? '', username: m['username']?.toString() ?? '', password: password));
      } catch (_) {}
    }
    _sourcesCache = out;
    return List.unmodifiable(out);
  }

  Future<void> saveSource(AurenTvSource source) async {
    final current = (await sources()).where((x) => x.id != source.id).toList()..add(source);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_sourcesKey, current.map((x) => jsonEncode({'id': x.id, 'name': x.name, 'type': x.type, 'url': x.url, 'epgUrl': x.epgUrl, 'username': x.username})).toList());
    await _secure.write(key: 'auren_tv_source_password_${source.id}', value: source.password);
    _sourcesCache = current;
  }

  Future<void> deleteSource(String id) async {
    final current = (await sources()).where((x) => x.id != id).toList();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_sourcesKey, current.map((x) => jsonEncode({'id': x.id, 'name': x.name, 'type': x.type, 'url': x.url, 'epgUrl': x.epgUrl, 'username': x.username})).toList());
    await _secure.delete(key: 'auren_tv_source_password_$id');
    _sourcesCache = current;
  }

  Future<List<AurenTvChannel>> loadSource(AurenTvSource source, {int limit = 500}) async {
    if (source.epgUrl.trim().isNotEmpty) { _epgUrl = source.epgUrl.trim(); _epgCache = null; }
    if (source.type == 'xtream') return _fetchXtream(source, limit: limit);
    if (source.url.trim().isEmpty) throw Exception('أدخل رابط M3U صالحاً.');
    return _fetchPlaylist(source.url.trim(), fallbackCategory: 'IPTV');
  }

  Future<List<AurenTvChannel>> _fetchXtream(AurenTvSource source, {int limit = 500}) async {
    if (source.url.trim().isEmpty || source.username.trim().isEmpty || source.password.isEmpty) throw Exception('بيانات Xtream غير مكتملة.');
    final base = source.url.trim().replaceFirst(RegExp(r'/+
    _cache ??= await _fetch();
    final c = country.trim().toLowerCase();
    final k = category.trim().toLowerCase();
    return _cache!.where((x) =>
      (c.isEmpty || x.country.toLowerCase().contains(c)) &&
      (k.isEmpty || x.category.toLowerCase().contains(k))).take(500).toList();
  }

  /// Fast continent browsing: return a small curated slice instead of
  /// forcing the user to scan the entire global catalogue.
  Future<List<AurenTvChannel>> loadFeaturedByCountries(
    Set<String> countryCodes, {
    int limit = 20,
  }) async {
    _cache ??= await _fetch();
    final codes = countryCodes.map((e) => e.toUpperCase()).toSet();
    final result = <AurenTvChannel>[];
    final seen = <String>{};
    for (final channel in _cache!) {
      if (!codes.contains(channel.country.toUpperCase())) continue;
      final key = '${channel.name}|${channel.country}|${channel.url}';
      if (!seen.add(key)) continue;
      result.add(channel);
      if (result.length >= limit) break;
    }
    return result;
  }


  Future<List<AurenTvChannel>> loadEntertainment({int limit = 500}) async {
    _entertainmentCache ??= await _fetchPlaylist(entertainmentPlaylist, fallbackCategory: 'Entertainment');
    return _entertainmentCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadSports({int limit = 500}) async {
    _sportsCache ??= await _fetchPlaylist(sportsPlaylist, fallbackCategory: 'Sports');
    return _sportsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadNews({int limit = 500}) async {
    if (_newsCache == null) {
      final news = await _fetchPlaylist(newsPlaylist, fallbackCategory: 'News');
      final sudan = await _fetchPlaylist(sudanPlaylist, fallbackCategory: 'Sudan');
      final merged = <AurenTvChannel>[];
      final seen = <String>{};
      for (final channel in [...news, ...sudan]) {
        final key = '${channel.tvgId}|${channel.url}|${channel.name}'.toLowerCase();
        if (seen.add(key)) merged.add(channel);
      }
      _newsCache = merged;
    }
    return _newsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadMovies({int limit = 500}) async {
    _moviesCache ??= await _fetchPlaylist(moviesPlaylist, fallbackCategory: 'Movies');
    return _moviesCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadMusic({int limit = 500}) async {
    _musicCache ??= await _fetchPlaylist(musicPlaylist, fallbackCategory: 'Music');
    return _musicCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadKids({int limit = 500}) async {
    _kidsCache ??= await _fetchPlaylist(kidsPlaylist, fallbackCategory: 'Kids');
    return _kidsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadAnimation({int limit = 500}) async {
    _animationCache ??= await _fetchPlaylist(animationPlaylist, fallbackCategory: 'Animation');
    return _animationCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadDocumentary({int limit = 500}) async {
    _documentaryCache ??= await _fetchPlaylist(documentaryPlaylist, fallbackCategory: 'Documentary');
    return _documentaryCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadSeries({int limit = 500}) async {
    _seriesCache ??= await _fetchPlaylist(seriesPlaylist, fallbackCategory: 'Series');
    return _seriesCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> _fetchPlaylist(String source, {String fallbackCategory = ''}) async {
    final r = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل قائمة IPTV العامة.');
    final out = <AurenTvChannel>[];
    Map<String, String>? meta;
    for (final line in const LineSplitter().convert(r.body)) {
      if (line.startsWith('#EXTM3U')) {
        _epgUrl ??= ((_attr(line, 'x-tvg-url') ?? _attr(line, 'url-tvg')) ?? '').split(',').map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');
      } else if (line.startsWith('#EXTINF:')) {
        meta = {
          'name': _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
          'logo': _attr(line, 'tvg-logo') ?? '',
          'country': _attr(line, 'tvg-country') ?? '',
          'language': _attr(line, 'tvg-language') ?? '',
          'category': _attr(line, 'group-title') ?? fallbackCategory,
          'tvgId': _attr(line, 'tvg-id') ?? '',
        };
      } else if (line.trim().startsWith('http') && meta != null) {
        out.add(AurenTvChannel(
          id: 'tv-' + source.hashCode.toString() + '-' + out.length.toString(),
          name: meta['name']!, logo: meta['logo']!, country: meta['country']!, language: meta['language']!,
          category: meta['category']!, tvgId: meta['tvgId']!, url: line.trim(),
        ));
        meta = null;
      }
    }
    return out;
  }

  Future<List<AurenTvChannel>> _fetch() async {
    final r = await http.get(Uri.parse(playlist)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل قائمة IPTV العامة.');
    final out = <AurenTvChannel>[];
    Map<String, String>? meta;
    for (final line in const LineSplitter().convert(r.body)) {
      if (line.startsWith('#EXTM3U')) {
        _epgUrl = ((_attr(line, 'x-tvg-url') ?? _attr(line, 'url-tvg')) ?? '').split(',').map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');
      } else if (line.startsWith('#EXTINF:')) {
        meta = {
          'name': _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
          'logo': _attr(line, 'tvg-logo') ?? '',
          'country': _attr(line, 'tvg-country') ?? '',
          'language': _attr(line, 'tvg-language') ?? '',
          'category': _attr(line, 'group-title') ?? '',
          'tvgId': _attr(line, 'tvg-id') ?? '',
        };
      } else if (line.trim().startsWith('http') && meta != null) {
        out.add(AurenTvChannel(
          id: 'tv-${out.length}', name: meta['name']!, logo: meta['logo']!,
          country: meta['country']!, language: meta['language']!,
          category: meta['category']!, tvgId: meta['tvgId']!, url: line.trim(),
        ));
        meta = null;
      }
    }
    return out;
  }

  Future<Set<String>> favorites() async =>
      (await SharedPreferences.getInstance()).getStringList('auren_tv_favorites')?.toSet() ?? <String>{};

  Future<void> setFavorite(String id, bool value) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList('auren_tv_favorites')?.toSet() ?? <String>{};
    if (value) { ids.add(id); } else { ids.remove(id); }
    await p.setStringList('auren_tv_favorites', ids.toList());
  }

  Future<Map<String, String>?> nowNext(String tvgId) async {
    final list = await schedule(tvgId);
    if (list.isEmpty) return null;
    final current = list.firstWhere((x) => x['state'] == 'now', orElse: () => <String,String>{});
    final next = list.firstWhere((x) => x['state'] == 'next', orElse: () => <String,String>{});
    return {'current': current['title'] ?? '', 'next': next['title'] ?? ''};
  }

  Future<List<Map<String, String>>> schedule(String tvgId, {int hours = 24}) async {
    if (tvgId.isEmpty || _epgUrl == null || _epgUrl!.isEmpty) return const [];
    _epgCache ??= await _loadEpg();
    final now = DateTime.now().toUtc();
    final until = now.add(Duration(hours: hours));
    return (_epgCache![tvgId] ?? const [])
        .where((x) {
          final stop = DateTime.tryParse(x['stopIso'] ?? '');
          return stop != null && stop.isAfter(now) && stop.isBefore(until);
        }).take(12).toList();
  }

  Future<Map<String, List<Map<String, String>>>> _loadEpg() async {
    try {
      final r = await http.get(Uri.parse(_epgUrl!)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return {};
      final result = <String, List<Map<String, String>>>{};
      final now = DateTime.now().toUtc();
      final pattern = RegExp(r'<programme\b([^>]*)>([\s\S]*?)</programme>', caseSensitive: false);
      for (final m in pattern.allMatches(r.body).take(30000)) {
        final attrs = m.group(1)!;
        final body = m.group(2)!;
        final channel = _xmlAttr(attrs, 'channel');
        final start = _xmlAttr(attrs, 'start');
        final stop = _xmlAttr(attrs, 'stop');
        if (channel.isEmpty || start.isEmpty || stop.isEmpty) continue;
        final from = _epgDate(start), until = _epgDate(stop);
        if (from == null || until == null || until.isBefore(now)) continue;
        final titleMatch = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(body);
        final title = _decodeXml(titleMatch?.group(1) ?? '');
        final state = from.isBefore(now) && until.isAfter(now) ? 'now' : 'next';
        result.putIfAbsent(channel, () => <Map<String,String>>[]).add({
          'title': title,
          'startIso': from.toIso8601String(),
          'stopIso': until.toIso8601String(),
          'state': state,
        });
      }
      for (final list in result.values) {
        list.sort((a,b) => (DateTime.tryParse(a['startIso'] ?? '') ?? DateTime(9999)).compareTo(DateTime.tryParse(b['startIso'] ?? '') ?? DateTime(9999)));
        var foundNow = false;
        for (final item in list) {
          if (item['state'] == 'now') {
            if (foundNow) item['state'] = 'next';
            foundNow = true;
          }
        }
      }
      return result;
    } catch (_) { return {}; }
  }

  static DateTime? _epgDate(String value) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*([+-]\d{4}))?').firstMatch(value);
    if (m == null) return null;
    final zone = m.group(7) ?? '+0000';
    final iso = '${m.group(1)}-${m.group(2)}-${m.group(3)}T${m.group(4)}:${m.group(5)}:${m.group(6)}${zone.substring(0,3)}:${zone.substring(3)}';
    return DateTime.tryParse(iso)?.toUtc();
  }
  static String _xmlAttr(String s, String key) => RegExp('$key="([^"]*)"').firstMatch(s)?.group(1) ?? '';
  static String _decodeXml(String s) => s.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'");
  static String? _attr(String s, String key) => RegExp(key + '="([^"]*)"').firstMatch(s)?.group(1);
}
), '');
    final api = Uri.parse(base + '/player_api.php').replace(queryParameters: {'username': source.username, 'password': source.password});
    final r = await http.get(api).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر الاتصال بمصدر Xtream.');
    final data = jsonDecode(r.body);
    final streams = data is Map<String, dynamic> ? data['live_streams'] : null;
    if (streams is! List) throw Exception('استجابة Xtream لا تحتوي على القنوات المباشرة.');
    return _xtreamChannels(streams, base, source, limit);
  }

  List<AurenTvChannel> _xtreamChannels(List<dynamic> streams, String base, AurenTvSource source, int limit) {
    final out = <AurenTvChannel>[];
    for (final item in streams) {
      if (item is! Map) continue;
      final id = item['stream_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final name = item['name']?.toString() ?? 'Channel';
      final ext = item['container_extension']?.toString() ?? 'ts';
      final logo = item['stream_icon']?.toString() ?? '';
      final category = item['category_name']?.toString() ?? 'IPTV';
      final tvgId = item['epg_channel_id']?.toString() ?? item['epg_id']?.toString() ?? '';
      final url = base + '/live/' + Uri.encodeComponent(source.username) + '/' + Uri.encodeComponent(source.password) + '/' + id + '.' + ext;
      out.add(AurenTvChannel(id: 'xtream-' + source.id + '-' + id, name: name, logo: logo, country: '', language: '', category: category, tvgId: tvgId, url: url));
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<AurenTvChannel>> load({String country = '', String category = ''}) async {
    _cache ??= await _fetch();
    final c = country.trim().toLowerCase();
    final k = category.trim().toLowerCase();
    return _cache!.where((x) =>
      (c.isEmpty || x.country.toLowerCase().contains(c)) &&
      (k.isEmpty || x.category.toLowerCase().contains(k))).take(500).toList();
  }

  /// Fast continent browsing: return a small curated slice instead of
  /// forcing the user to scan the entire global catalogue.
  Future<List<AurenTvChannel>> loadFeaturedByCountries(
    Set<String> countryCodes, {
    int limit = 20,
  }) async {
    _cache ??= await _fetch();
    final codes = countryCodes.map((e) => e.toUpperCase()).toSet();
    final result = <AurenTvChannel>[];
    final seen = <String>{};
    for (final channel in _cache!) {
      if (!codes.contains(channel.country.toUpperCase())) continue;
      final key = '${channel.name}|${channel.country}|${channel.url}';
      if (!seen.add(key)) continue;
      result.add(channel);
      if (result.length >= limit) break;
    }
    return result;
  }


  Future<List<AurenTvChannel>> loadEntertainment({int limit = 500}) async {
    _entertainmentCache ??= await _fetchPlaylist(entertainmentPlaylist, fallbackCategory: 'Entertainment');
    return _entertainmentCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadSports({int limit = 500}) async {
    _sportsCache ??= await _fetchPlaylist(sportsPlaylist, fallbackCategory: 'Sports');
    return _sportsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadNews({int limit = 500}) async {
    if (_newsCache == null) {
      final news = await _fetchPlaylist(newsPlaylist, fallbackCategory: 'News');
      final sudan = await _fetchPlaylist(sudanPlaylist, fallbackCategory: 'Sudan');
      final merged = <AurenTvChannel>[];
      final seen = <String>{};
      for (final channel in [...news, ...sudan]) {
        final key = '${channel.tvgId}|${channel.url}|${channel.name}'.toLowerCase();
        if (seen.add(key)) merged.add(channel);
      }
      _newsCache = merged;
    }
    return _newsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadMovies({int limit = 500}) async {
    _moviesCache ??= await _fetchPlaylist(moviesPlaylist, fallbackCategory: 'Movies');
    return _moviesCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadMusic({int limit = 500}) async {
    _musicCache ??= await _fetchPlaylist(musicPlaylist, fallbackCategory: 'Music');
    return _musicCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadKids({int limit = 500}) async {
    _kidsCache ??= await _fetchPlaylist(kidsPlaylist, fallbackCategory: 'Kids');
    return _kidsCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadAnimation({int limit = 500}) async {
    _animationCache ??= await _fetchPlaylist(animationPlaylist, fallbackCategory: 'Animation');
    return _animationCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadDocumentary({int limit = 500}) async {
    _documentaryCache ??= await _fetchPlaylist(documentaryPlaylist, fallbackCategory: 'Documentary');
    return _documentaryCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> loadSeries({int limit = 500}) async {
    _seriesCache ??= await _fetchPlaylist(seriesPlaylist, fallbackCategory: 'Series');
    return _seriesCache!.take(limit).toList();
  }

  Future<List<AurenTvChannel>> _fetchPlaylist(String source, {String fallbackCategory = ''}) async {
    final r = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل قائمة IPTV العامة.');
    final out = <AurenTvChannel>[];
    Map<String, String>? meta;
    for (final line in const LineSplitter().convert(r.body)) {
      if (line.startsWith('#EXTM3U')) {
        _epgUrl ??= ((_attr(line, 'x-tvg-url') ?? _attr(line, 'url-tvg')) ?? '').split(',').map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');
      } else if (line.startsWith('#EXTINF:')) {
        meta = {
          'name': _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
          'logo': _attr(line, 'tvg-logo') ?? '',
          'country': _attr(line, 'tvg-country') ?? '',
          'language': _attr(line, 'tvg-language') ?? '',
          'category': _attr(line, 'group-title') ?? fallbackCategory,
          'tvgId': _attr(line, 'tvg-id') ?? '',
        };
      } else if (line.trim().startsWith('http') && meta != null) {
        out.add(AurenTvChannel(
          id: 'tv-' + source.hashCode.toString() + '-' + out.length.toString(),
          name: meta['name']!, logo: meta['logo']!, country: meta['country']!, language: meta['language']!,
          category: meta['category']!, tvgId: meta['tvgId']!, url: line.trim(),
        ));
        meta = null;
      }
    }
    return out;
  }

  Future<List<AurenTvChannel>> _fetch() async {
    final r = await http.get(Uri.parse(playlist)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل قائمة IPTV العامة.');
    final out = <AurenTvChannel>[];
    Map<String, String>? meta;
    for (final line in const LineSplitter().convert(r.body)) {
      if (line.startsWith('#EXTM3U')) {
        _epgUrl = ((_attr(line, 'x-tvg-url') ?? _attr(line, 'url-tvg')) ?? '').split(',').map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');
      } else if (line.startsWith('#EXTINF:')) {
        meta = {
          'name': _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
          'logo': _attr(line, 'tvg-logo') ?? '',
          'country': _attr(line, 'tvg-country') ?? '',
          'language': _attr(line, 'tvg-language') ?? '',
          'category': _attr(line, 'group-title') ?? '',
          'tvgId': _attr(line, 'tvg-id') ?? '',
        };
      } else if (line.trim().startsWith('http') && meta != null) {
        out.add(AurenTvChannel(
          id: 'tv-${out.length}', name: meta['name']!, logo: meta['logo']!,
          country: meta['country']!, language: meta['language']!,
          category: meta['category']!, tvgId: meta['tvgId']!, url: line.trim(),
        ));
        meta = null;
      }
    }
    return out;
  }

  Future<Set<String>> favorites() async =>
      (await SharedPreferences.getInstance()).getStringList('auren_tv_favorites')?.toSet() ?? <String>{};

  Future<void> setFavorite(String id, bool value) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList('auren_tv_favorites')?.toSet() ?? <String>{};
    if (value) { ids.add(id); } else { ids.remove(id); }
    await p.setStringList('auren_tv_favorites', ids.toList());
  }

  Future<Map<String, String>?> nowNext(String tvgId) async {
    final list = await schedule(tvgId);
    if (list.isEmpty) return null;
    final current = list.firstWhere((x) => x['state'] == 'now', orElse: () => <String,String>{});
    final next = list.firstWhere((x) => x['state'] == 'next', orElse: () => <String,String>{});
    return {'current': current['title'] ?? '', 'next': next['title'] ?? ''};
  }

  Future<List<Map<String, String>>> schedule(String tvgId, {int hours = 24}) async {
    if (tvgId.isEmpty || _epgUrl == null || _epgUrl!.isEmpty) return const [];
    _epgCache ??= await _loadEpg();
    final now = DateTime.now().toUtc();
    final until = now.add(Duration(hours: hours));
    return (_epgCache![tvgId] ?? const [])
        .where((x) {
          final stop = DateTime.tryParse(x['stopIso'] ?? '');
          return stop != null && stop.isAfter(now) && stop.isBefore(until);
        }).take(12).toList();
  }

  Future<Map<String, List<Map<String, String>>>> _loadEpg() async {
    try {
      final r = await http.get(Uri.parse(_epgUrl!)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return {};
      final result = <String, List<Map<String, String>>>{};
      final now = DateTime.now().toUtc();
      final pattern = RegExp(r'<programme\b([^>]*)>([\s\S]*?)</programme>', caseSensitive: false);
      for (final m in pattern.allMatches(r.body).take(30000)) {
        final attrs = m.group(1)!;
        final body = m.group(2)!;
        final channel = _xmlAttr(attrs, 'channel');
        final start = _xmlAttr(attrs, 'start');
        final stop = _xmlAttr(attrs, 'stop');
        if (channel.isEmpty || start.isEmpty || stop.isEmpty) continue;
        final from = _epgDate(start), until = _epgDate(stop);
        if (from == null || until == null || until.isBefore(now)) continue;
        final titleMatch = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(body);
        final title = _decodeXml(titleMatch?.group(1) ?? '');
        final state = from.isBefore(now) && until.isAfter(now) ? 'now' : 'next';
        result.putIfAbsent(channel, () => <Map<String,String>>[]).add({
          'title': title,
          'startIso': from.toIso8601String(),
          'stopIso': until.toIso8601String(),
          'state': state,
        });
      }
      for (final list in result.values) {
        list.sort((a,b) => (DateTime.tryParse(a['startIso'] ?? '') ?? DateTime(9999)).compareTo(DateTime.tryParse(b['startIso'] ?? '') ?? DateTime(9999)));
        var foundNow = false;
        for (final item in list) {
          if (item['state'] == 'now') {
            if (foundNow) item['state'] = 'next';
            foundNow = true;
          }
        }
      }
      return result;
    } catch (_) { return {}; }
  }

  static DateTime? _epgDate(String value) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*([+-]\d{4}))?').firstMatch(value);
    if (m == null) return null;
    final zone = m.group(7) ?? '+0000';
    final iso = '${m.group(1)}-${m.group(2)}-${m.group(3)}T${m.group(4)}:${m.group(5)}:${m.group(6)}${zone.substring(0,3)}:${zone.substring(3)}';
    return DateTime.tryParse(iso)?.toUtc();
  }
  static String _xmlAttr(String s, String key) => RegExp('$key="([^"]*)"').firstMatch(s)?.group(1) ?? '';
  static String _decodeXml(String s) => s.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'");
  static String? _attr(String s, String key) => RegExp(key + '="([^"]*)"').firstMatch(s)?.group(1);
}
