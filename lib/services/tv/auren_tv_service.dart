import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AurenTvChannel {
  final String id, name, logo, country, language, category, url, tvgId;
  const AurenTvChannel({required this.id, required this.name, required this.logo, required this.country, required this.language, required this.category, required this.url, this.tvgId = ''});
}

class AurenTvService {
  AurenTvService._();
  static final instance = AurenTvService._();
  static const playlist = 'https://iptv-org.github.io/iptv/index.country.m3u';
  List<AurenTvChannel>? _cache;
  String? _epgUrl;
  Map<String, Map<String, String>>? _epgCache;

  Future<List<AurenTvChannel>> load({String country = '', String category = ''}) async {
    _cache ??= await _fetch();
    final c = country.trim().toLowerCase();
    final k = category.trim().toLowerCase();
    return _cache!.where((x) =>
      (c.isEmpty || x.country.toLowerCase().contains(c)) &&
      (k.isEmpty || x.category.toLowerCase().contains(k))).take(500).toList();
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
    if (tvgId.isEmpty || _epgUrl == null || _epgUrl!.isEmpty) return null;
    _epgCache ??= await _loadEpg();
    return _epgCache![tvgId];
  }

  Future<Map<String, Map<String, String>>> _loadEpg() async {
    try {
      final r = await http.get(Uri.parse(_epgUrl!)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return {};
      final result = <String, Map<String, String>>{};
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
        if (from == null || until == null) continue;
        final titleMatch = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(body);
        final title = _decodeXml(titleMatch?.group(1) ?? '');
        if (from.isBefore(now) && until.isAfter(now)) {
          result[channel] = {'current': title, 'next': ''};
        } else if (from.isAfter(now)) {
          final old = result[channel];
          if (old == null || old['nextStart'] == null || from.isBefore(DateTime.parse(old['nextStart']!))) {
            result[channel] = {...?old, 'next': title, 'nextStart': from.toIso8601String()};
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
