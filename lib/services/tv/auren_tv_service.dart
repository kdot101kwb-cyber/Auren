import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AurenTvHealth {
  final String status;
  final int? latencyMs;
  final DateTime checkedAt;
  const AurenTvHealth({required this.status, required this.latencyMs, required this.checkedAt});
}

class AurenTvChannel {
  final String id, name, logo, country, language, category, url, tvgId;
  const AurenTvChannel({required this.id, required this.name, required this.logo, required this.country, required this.language, required this.category, required this.url, this.tvgId = ''});
}

class AurenTvSource {
  final String id, name, type, url, epgUrl, username, password;
  final bool enabled;
  const AurenTvSource({required this.id, required this.name, required this.type, this.url = '', this.epgUrl = '', this.username = '', this.password = '', this.enabled = true});
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
  final Map<String, String> _sourceEpgUrls = <String, String>{};
  final Map<String, Map<String, List<Map<String, String>>>> _sourceEpgCaches = <String, Map<String, List<Map<String, String>>>>{};
  final Map<String, Map<String, Map<String, String>>> _epgChannelMetadata = <String, Map<String, Map<String, String>>>{};
  final Map<String, List<AurenTvChannel>> _sourceChannelCaches = <String, List<AurenTvChannel>>{};
  final Map<String, DateTime> _sourceChannelCacheTimes = <String, DateTime>{};
  static const Duration _sourceChannelCacheTtl = Duration(minutes: 10);

  static const _sourcesKey = 'auren_tv_sources';
  static const _defaultSourceKey = 'auren_tv_default_source';
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
        out.add(AurenTvSource(id: id, name: m['name']?.toString() ?? 'IPTV', type: m['type']?.toString() ?? 'm3u', url: m['url']?.toString() ?? '', epgUrl: m['epgUrl']?.toString() ?? '', username: m['username']?.toString() ?? '', password: password, enabled: m['enabled'] != false));
      } catch (_) {}
    }
    _sourcesCache = out;
    return List.unmodifiable(out);
  }

  Future<void> saveSource(AurenTvSource source) async {
    final current = (await sources()).where((x) => x.id != source.id).toList()..add(source);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_sourcesKey, current.map((x) => jsonEncode({'id': x.id, 'name': x.name, 'type': x.type, 'url': x.url, 'epgUrl': x.epgUrl, 'username': x.username, 'enabled': x.enabled})).toList());
    await _secure.write(key: 'auren_tv_source_password_${source.id}', value: source.password);
    _sourcesCache = current;
  }

  Future<String?> defaultSourceId() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_defaultSourceKey);
    if (id == null || id.isEmpty) return null;
    final exists = (await sources()).any((x) => x.id == id && x.enabled);
    return exists ? id : null;
  }

  Future<void> setDefaultSource(String? id) async {
    final p = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await p.remove(_defaultSourceKey);
      return;
    }
    final exists = (await sources()).any((x) => x.id == id && x.enabled);
    if (exists) await p.setString(_defaultSourceKey, id);
  }

  Future<void> setSourceEnabled(String id, bool enabled) async {
    final current = await sources();
    final source = current.where((x) => x.id == id).toList();
    if (source.isEmpty) return;
    await saveSource(AurenTvSource(id: source.first.id, name: source.first.name, type: source.first.type, url: source.first.url, epgUrl: source.first.epgUrl, username: source.first.username, password: source.first.password, enabled: enabled));
    if (!enabled && await defaultSourceId() == id) await setDefaultSource(null);
  }

  Future<void> deleteSource(String id) async {
    final current = (await sources()).where((x) => x.id != id).toList();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_sourcesKey, current.map((x) => jsonEncode({'id': x.id, 'name': x.name, 'type': x.type, 'url': x.url, 'epgUrl': x.epgUrl, 'username': x.username, 'enabled': x.enabled})).toList());
    await _secure.delete(key: 'auren_tv_source_password_$id');
    _sourcesCache = current;
    _sourceChannelCaches.remove(id);
    _sourceChannelCacheTimes.remove(id);
    _sourceEpgUrls.remove(id);
    _sourceEpgCaches.remove(id);
    _epgChannelMetadata.remove(id);
    final p2 = await SharedPreferences.getInstance();
    if (p2.getString(_defaultSourceKey) == id) await p2.remove(_defaultSourceKey);
  }

  static const _healthKey = 'auren_tv_channel_health';
  final Map<String, AurenTvHealth> _healthCache = <String, AurenTvHealth>{};

  Future<AurenTvHealth> checkChannelHealth(AurenTvChannel channel, {Duration timeout = const Duration(seconds: 6)}) async {
    final started = DateTime.now();
    try {
      final r = await http.head(Uri.parse(channel.url), followRedirects: true).timeout(timeout);
      final ms = DateTime.now().difference(started).inMilliseconds;
      final ok = r.statusCode >= 200 && r.statusCode < 500;
      final health = AurenTvHealth(status: ok ? 'online' : 'offline', latencyMs: ms, checkedAt: DateTime.now());
      _healthCache[channel.id] = health;
      await _saveHealth(channel.id, health);
      return health;
    } catch (_) {
      final health = AurenTvHealth(status: 'offline', latencyMs: null, checkedAt: DateTime.now());
      _healthCache[channel.id] = health;
      await _saveHealth(channel.id, health);
      return health;
    }
  }

  Future<AurenTvHealth?> channelHealth(String channelId) async {
    if (_healthCache.containsKey(channelId)) return _healthCache[channelId];
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_healthKey);
    if (raw == null) return null;
    try {
      final all = jsonDecode(raw) as Map<String, dynamic>;
      final m = all[channelId] as Map<String, dynamic>?;
      if (m == null) return null;
      return _healthCache[channelId] = AurenTvHealth(status: m['status']?.toString() ?? 'unknown', latencyMs: m['latencyMs'] is int ? m['latencyMs'] as int : null, checkedAt: DateTime.tryParse(m['checkedAt']?.toString() ?? '') ?? DateTime.now());
    } catch (_) { return null; }
  }

  Future<void> _saveHealth(String id, AurenTvHealth health) async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> all = {};
    try { all = (jsonDecode(p.getString(_healthKey) ?? '{}') as Map).cast<String, dynamic>(); } catch (_) {}
    all[id] = {'status': health.status, 'latencyMs': health.latencyMs, 'checkedAt': health.checkedAt.toIso8601String()};
    if (all.length > 300) all.remove(all.keys.first);
    await p.setString(_healthKey, jsonEncode(all));
  }

  Future<void> autoRefreshSources({int limit = 500}) async {
    final all = await sources();
    for (final source in all.where((x) => x.enabled)) {
      final cachedAt = _sourceChannelCacheTimes[source.id];
      if (cachedAt == null || DateTime.now().difference(cachedAt) >= _sourceChannelCacheTtl) {
        try { await loadSource(source, limit: limit); } catch (_) {}
      }
    }
  }

  Future<int> testSource(AurenTvSource source) async {
    if (source.type.toLowerCase() == 'xtream') {
      final channels = await _fetchXtream(source, limit: 500);
      return channels.length;
    }
    if (source.url.trim().isEmpty) throw Exception('أدخل رابط M3U صالحاً.');
    final channels = await _fetchPlaylist(source.url.trim(), fallbackCategory: 'IPTV', limit: 500, sourceId: source.id);
    return channels.length;
  }

  Future<List<AurenTvChannel>> loadSource(AurenTvSource source, {int limit = 500, bool forceRefresh = false}) async {
    if (!source.enabled) return const [];
    final cachedAt = _sourceChannelCacheTimes[source.id];
    final cached = _sourceChannelCaches[source.id];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _sourceChannelCacheTtl) {
      return cached.take(limit).toList();
    }
    if (source.epgUrl.trim().isNotEmpty) {
      _sourceEpgUrls[source.id] = source.epgUrl.trim();
    }
    final channels = source.type.toLowerCase() == 'xtream'
        ? await _fetchXtream(source, limit: 500)
        : await _loadM3uSource(source, limit: 500);
    _sourceChannelCaches[source.id] = channels;
    _sourceChannelCacheTimes[source.id] = DateTime.now();
    return channels.take(limit).toList();
  }

  Future<List<AurenTvChannel>> _loadM3uSource(AurenTvSource source, {int limit = 500}) async {
    if (source.url.trim().isEmpty) throw Exception('أدخل رابط M3U صالحاً.');
    return _fetchPlaylist(source.url.trim(), fallbackCategory: 'IPTV', limit: limit, sourceId: source.id);
  }

  Future<List<AurenTvChannel>> refreshSource(AurenTvSource source, {int limit = 500}) async {
    _sourceChannelCaches.remove(source.id);
    _sourceChannelCacheTimes.remove(source.id);
    _sourceEpgCaches.remove(source.id);
    _sourceEpgUrls.remove(source.id);
    return loadSource(source, limit: limit, forceRefresh: true);
  }


  Future<List<AurenTvChannel>> _fetchXtream(AurenTvSource source, {int limit = 500}) async {
    if (source.url.trim().isEmpty || source.username.trim().isEmpty || source.password.isEmpty) {
      throw Exception('بيانات Xtream غير مكتملة.');
    }
    final base = source.url.trim().replaceFirst(RegExp(r'/+$'), '');
    final api = Uri.parse(base + '/player_api.php').replace(
      queryParameters: {'username': source.username, 'password': source.password},
    );
    final r = await http.get(api).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر الاتصال بمصدر Xtream.');
    dynamic data;
    try { data = jsonDecode(r.body); } catch (_) { throw Exception('استجابة Xtream غير صالحة.'); }
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
      final category = _classifyCategory(name: name, category: item['category_name']?.toString() ?? 'IPTV');
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

  Future<List<AurenTvChannel>> _fetchPlaylist(String source, {String fallbackCategory = '', int limit = 500, String? sourceId}) async {
    final r = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('تعذر تحميل قائمة IPTV العامة.');
    final out = <AurenTvChannel>[];
    Map<String, String>? meta;
    for (final line in const LineSplitter().convert(r.body)) {
      if (line.startsWith('#EXTM3U')) {
        final embeddedEpg = ((_attr(line, 'x-tvg-url') ?? _attr(line, 'url-tvg')) ?? '').split(',').map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');
        if (sourceId != null && embeddedEpg.isNotEmpty) _sourceEpgUrls[sourceId] = embeddedEpg;
        if (source == playlist && embeddedEpg.isNotEmpty) _epgUrl = embeddedEpg;
      } else if (line.startsWith('#EXTINF:')) {
        meta = {
          'name': _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
          'logo': _attr(line, 'tvg-logo') ?? '',
          'country': _attr(line, 'tvg-country') ?? '',
          'language': _attr(line, 'tvg-language') ?? '',
          'category': _classifyCategory(
            name: _attr(line, 'tvg-name') ?? line.split(',').last.trim(),
            category: _attr(line, 'group-title') ?? fallbackCategory,
          ),
          'tvgId': _attr(line, 'tvg-id') ?? '',
        };
      } else if (line.trim().startsWith('http') && meta != null) {
        out.add(AurenTvChannel(
          id: 'tv-' + source.hashCode.toString() + '-' + out.length.toString(),
          name: meta['name']!, logo: meta['logo']!, country: meta['country']!, language: meta['language']!,
          category: meta['category']!, tvgId: meta['tvgId']!, url: line.trim(),
        ));
        meta = null;
        if (out.length >= limit) break;
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

  static String _normalizeIdentity(String value) {
    return value.toLowerCase()
        .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '')
        .replaceAll(RegExp(r'[^a-z0-9\\u0600-\\u06ff]+'), '')
        .trim();
  }

  static String favoriteKey(AurenTvChannel channel) {
    final tvg = _normalizeIdentity(channel.tvgId);
    if (tvg.isNotEmpty) return 'tvg:$tvg';
    return 'name:${_normalizeIdentity(channel.name)}|country:${_normalizeIdentity(channel.country)}';
  }

  Future<bool> isFavorite(AurenTvChannel channel) async {
    final ids = await favorites();
    return ids.contains(favoriteKey(channel)) || ids.contains(channel.id);
  }

  Future<void> setChannelFavorite(AurenTvChannel channel, bool value) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList('auren_tv_favorites')?.toSet() ?? <String>{};
    final key = favoriteKey(channel);
    if (value) {
      ids.add(key);
      ids.remove(channel.id);
    } else {
      ids.remove(key);
      ids.remove(channel.id);
    }
    await p.setStringList('auren_tv_favorites', ids.toList());
  }

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

  Future<Map<String, String>?> nowNextForSource(AurenTvSource source, String tvgId) async {
    final list = await scheduleForSource(source, tvgId);
    if (list.isEmpty) return null;
    final current = list.firstWhere((x) => x['state'] == 'now', orElse: () => <String, String>{});
    final next = list.firstWhere((x) => x['state'] == 'next', orElse: () => <String, String>{});
    return {'current': current['title'] ?? '', 'next': next['title'] ?? ''};
  }

  Future<Map<String, String>?> nowNextForChannel(AurenTvChannel channel, {AurenTvSource? source}) async {
    final list = source == null
        ? await scheduleForChannel(channel)
        : await scheduleForSourceChannel(source, channel);
    if (list.isEmpty) return null;
    final current = list.firstWhere((x) => x['state'] == 'now', orElse: () => <String, String>{});
    final next = list.firstWhere((x) => x['state'] == 'next', orElse: () => <String, String>{});
    return {'current': current['title'] ?? '', 'next': next['title'] ?? ''};
  }

  Future<List<Map<String, String>>> schedule(String tvgId, {int hours = 24}) async {
    if (tvgId.isEmpty || _epgUrl == null || _epgUrl!.isEmpty) return const [];
    _epgCache ??= await _loadEpg(_epgUrl!, metadataKey: 'global');
    return _filterSchedule(_matchEpg(_epgCache!, tvgId), hours);
  }

  Future<List<Map<String, String>>> scheduleForSource(AurenTvSource source, String tvgId, {int hours = 24}) async {
    if (tvgId.isEmpty) return const [];
    final epgUrl = source.epgUrl.trim().isNotEmpty ? source.epgUrl.trim() : (_sourceEpgUrls[source.id] ?? '');
    if (epgUrl.isEmpty) return const [];
    final cache = _sourceEpgCaches[source.id] ??= await _loadEpg(epgUrl, metadataKey: source.id);
    return _filterSchedule(_matchEpg(cache, tvgId), hours);
  }

  Future<List<Map<String, String>>> scheduleForChannel(AurenTvChannel channel, {int hours = 24}) async {
    if (_epgUrl == null || _epgUrl!.isEmpty) return const [];
    _epgCache ??= await _loadEpg(_epgUrl!, metadataKey: 'global');
    final matched = _matchEpgForChannel(_epgCache!, channel, _epgChannelMetadata['global'] ?? const {});
    return _filterSchedule(matched, hours);
  }

  Future<List<Map<String, String>>> scheduleForSourceChannel(AurenTvSource source, AurenTvChannel channel, {int hours = 24}) async {
    final epgUrl = source.epgUrl.trim().isNotEmpty ? source.epgUrl.trim() : (_sourceEpgUrls[source.id] ?? '');
    if (epgUrl.isEmpty) return const [];
    final cache = _sourceEpgCaches[source.id] ??= await _loadEpg(epgUrl, metadataKey: source.id);
    final matched = _matchEpgForChannel(cache, channel, _epgChannelMetadata[source.id] ?? const {});
    return _filterSchedule(matched, hours);
  }

  List<Map<String, String>> _matchEpg(Map<String, List<Map<String, String>>> cache, String tvgId) {
    if (cache.isEmpty || tvgId.isEmpty) return const [];
    final exact = cache[tvgId];
    if (exact != null && exact.isNotEmpty) return exact;
    final wanted = _normalizeIdentity(tvgId);
    if (wanted.isEmpty) return const [];
    for (final entry in cache.entries) {
      final key = _normalizeIdentity(entry.key);
      if (key == wanted || key.contains(wanted) || wanted.contains(key)) return entry.value;
    }
    return const [];
  }

  List<Map<String, String>> _matchEpgForChannel(
    Map<String, List<Map<String, String>>> cache,
    AurenTvChannel channel,
    Map<String, Map<String, String>> metadata,
  ) {
    if (cache.isEmpty) return const [];
    final byId = _matchEpg(cache, channel.tvgId);
    if (byId.isNotEmpty) return byId;

    final wantedName = _normalizeIdentity(channel.name);
    if (wantedName.isEmpty) return const [];

    List<Map<String, String>>? best;
    var bestScore = 0.0;
    for (final entry in metadata.entries) {
      final programs = cache[entry.key];
      if (programs == null || programs.isEmpty) continue;
      final metaName = _normalizeIdentity(entry.value['name'] ?? '');
      if (metaName.isEmpty) continue;

      final nameScore = _identitySimilarity(wantedName, metaName);
      if (nameScore < 0.72) continue;

      final metaCountry = _normalizeIdentity(entry.value['country'] ?? '');
      final wantedCountry = _normalizeIdentity(channel.country);
      final metaLanguage = _normalizeIdentity(entry.value['language'] ?? '');
      final wantedLanguage = _normalizeIdentity(channel.language);

      var score = nameScore;
      if (wantedCountry.isNotEmpty && metaCountry.isNotEmpty) {
        if (wantedCountry == metaCountry) {
          score += 0.12;
        } else if (metaCountry.contains(wantedCountry) || wantedCountry.contains(metaCountry)) {
          score += 0.06;
        } else {
          score -= 0.10;
        }
      }
      if (wantedLanguage.isNotEmpty && metaLanguage.isNotEmpty) {
        if (wantedLanguage == metaLanguage) {
          score += 0.08;
        } else if (metaLanguage.contains(wantedLanguage) || wantedLanguage.contains(metaLanguage)) {
          score += 0.04;
        } else {
          score -= 0.06;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = programs;
      }
    }
    return bestScore >= 0.78 ? best ?? const [] : const [];
  }

  static double _identitySimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    if (a.contains(b) || b.contains(a)) {
      final shorter = a.length < b.length ? a : b;
      final longer = a.length >= b.length ? a : b;
      return shorter.length / longer.length;
    }
    final aTokens = _identityTokens(a);
    final bTokens = _identityTokens(b);
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    final overlap = aTokens.intersection(bTokens).length;
    return overlap / aTokens.union(bTokens).length;
  }

  static Set<String> _identityTokens(String value) {
    return RegExp(r'[a-z0-9\\u0600-\\u06ff]+').allMatches(value)
        .map((m) => m.group(0)!)
        .where((x) => x.length >= 2)
        .toSet();
  }

  List<Map<String, String>> _filterSchedule(List<Map<String, String>> programs, int hours) {
    final now = DateTime.now().toUtc();
    final until = now.add(Duration(hours: hours));
    return programs.where((x) {
      final stop = DateTime.tryParse(x['stopIso'] ?? '');
      return stop != null && stop.isAfter(now) && stop.isBefore(until);
    }).take(12).toList();
  }

  Future<Map<String, List<Map<String, String>>>> _loadEpg(String epgUrl, {String metadataKey = 'global'}) async {
    try {
      final r = await http.get(Uri.parse(epgUrl)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return {};
      final result = <String, List<Map<String, String>>>{};
      final metadata = <String, Map<String, String>>{};
      final channelPattern = RegExp(r'<channel\\b([^>]*)>([\\s\\S]*?)</channel>', caseSensitive: false);
      for (final m in channelPattern.allMatches(r.body).take(10000)) {
        final attrs = m.group(1)!;
        final body = m.group(2)!;
        final id = _xmlAttr(attrs, 'id');
        if (id.isEmpty) continue;
        final displayNames = RegExp(r'<display-name[^>]*>([\\s\\S]*?)</display-name>', caseSensitive: false)
            .allMatches(body)
            .map((x) => _decodeXml(x.group(1) ?? ''))
            .where((x) => x.trim().isNotEmpty)
            .toList();
        final firstDisplay = RegExp(r'<display-name\\b([^>]*)>', caseSensitive: false).firstMatch(body);
        final language = _xmlAttr(firstDisplay?.group(1) ?? '', 'lang');
        metadata[id] = {
          'name': displayNames.isEmpty ? '' : displayNames.first,
          'names': displayNames.join(' | '),
          'language': language,
          'country': _extractCountryHint(displayNames.join(' ') + ' ' + id),
        };
      }
      _epgChannelMetadata[metadataKey] = metadata;
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

  static String _classifyCategory({required String name, required String category}) {
    final value = '$name $category'.toLowerCase();
    if (RegExp(r'news|breaking|24/7|اخبار').hasMatch(value)) return 'News';
    if (RegExp(r'sport|football|soccer|fifa|uefa|nba|fiba|tennis|espn').hasMatch(value)) return 'Sports';
    if (RegExp(r'movie|film|cinema|movies').hasMatch(value)) return 'Movies';
    if (RegExp(r'series|serial|drama|soap').hasMatch(value)) return 'Series';
    if (RegExp(r'music|musical|mtv|vh1').hasMatch(value)) return 'Music';
    if (RegExp(r'kids|children|nickelodeon|cartoon').hasMatch(value)) return 'Kids';
    if (RegExp(r'anime|animation').hasMatch(value)) return 'Animation';
    if (RegExp(r'documentary|documentaries').hasMatch(value)) return 'Documentary';
    if (RegExp(r'comedy|humor|funny').hasMatch(value)) return 'Comedy';
    if (RegExp(r'entertainment|variety|culture|lifestyle').hasMatch(value)) return 'Entertainment';
    return category.trim().isEmpty ? 'General' : category.trim();
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
  static String _extractCountryHint(String value) {
    final upper = value.toUpperCase();
    final matches = RegExp(r'\\b([A-Z]{2})\\b').allMatches(upper).map((m) => m.group(1)!).toSet();
    const known = {
      'SD','EG','SA','AE','QA','KW','BH','OM','JO','IQ','LB','MA','DZ','TN','TR','ZA','NG','KE',
      'IN','CN','JP','KR','GB','FR','DE','IT','ES','US','CA','BR','AU','RU','UA','PK','BD',
    };
    for (final code in matches) {
      if (known.contains(code)) return code;
    }
    return '';
  }
  static String? _attr(String s, String key) => RegExp(key + '="([^"]*)"').firstMatch(s)?.group(1);
}
