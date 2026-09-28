import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auren_tv_service.dart';

class AurenTvHomeRecommendation {
  final AurenTvChannel channel;
  final double score;
  final String reason;
  const AurenTvHomeRecommendation({required this.channel, required this.score, required this.reason});
}

class AurenTvMultiChannelGuide {
  final AurenTvChannel channel;
  final Map<String, String>? nowNext;
  final List<Map<String, dynamic>> schedule;
  const AurenTvMultiChannelGuide({required this.channel, required this.nowNext, required this.schedule});
}

class AurenTvHomeService {
  AurenTvHomeService._();
  static final instance = AurenTvHomeService._();

  static const _historyKey = 'auren_tv_home_watch_history_v1';
  final Map<String, int> _opens = {};

  Future<void> recordWatch(AurenTvChannel channel) async {
    final key = AurenTvService.channelIdentity(channel);
    _opens[key] = (_opens[key] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    Map<String, dynamic> data = {};
    try { data = raw == null ? {} : (jsonDecode(raw) as Map).cast<String, dynamic>(); } catch (_) {}
    data[key] = (_opens[key] ?? 0);
    if (data.length > 300) {
      final entries = data.entries.toList()..sort((a,b) => ((b.value as num?)?.toDouble() ?? 0).compareTo((a.value as num?)?.toDouble() ?? 0));
      data = Map<String, dynamic>.fromEntries(entries.take(300));
    }
    await prefs.setString(_historyKey, jsonEncode(data));
  }

  Future<Map<String, int>> _history() async {
    if (_opens.isNotEmpty) return Map.unmodifiable(_opens);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    try {
      final map = (raw == null ? <String, dynamic>{} : (jsonDecode(raw) as Map).cast<String, dynamic>());
      _opens.addAll(map.map((k,v) => MapEntry(k, (v as num?)?.toInt() ?? 0)));
    } catch (_) {}
    return Map.unmodifiable(_opens);
  }

  Future<List<AurenTvChannel>> personalizedChannels({int limit = 20}) async {
    final channels = await AurenTvService.instance.loadAllEnabledSources(limitPerSource: 250);
    final favorites = await AurenTvService.instance.favorites();
    final history = await _history();
    final ranked = <AurenTvHomeRecommendation>[];
    for (final c in channels) {
      var score = 0.0;
      final key = AurenTvService.channelIdentity(c);
      final fav = favorites.contains(c.id) || favorites.contains('channel:' + key);
      if (fav) score += 100;
      score += (history[key] ?? 0) * 12;
      if (c.logo.isNotEmpty) score += 3;
      if (c.tvgId.isNotEmpty) score += 4;
      if (c.url.startsWith('https://')) score += 2;
      final reason = fav ? 'من مفضلاتك' : (history[key] ?? 0) > 0 ? 'لأنك شاهدتها سابقاً' : 'اختيار ذكي';
      ranked.add(AurenTvHomeRecommendation(channel: c, score: score, reason: reason));
    }
    ranked.sort((a,b) => b.score.compareTo(a.score));
    final seen = <String>{};
    return ranked.where((x) => seen.add(AurenTvService.channelIdentity(x.channel))).take(limit).map((x) => x.channel).toList();
  }

  Future<List<AurenTvMultiChannelGuide>> multiChannelGuide(List<AurenTvChannel> channels, {int hours = 48, int perChannel = 6, AurenTvSource? source}) async {
    final out = <AurenTvMultiChannelGuide>[];
    for (final channel in channels.take(30)) {
      try {
        final nowNext = await AurenTvService.instance.nowNextForChannel(channel, source: source);
        final schedule = await AurenTvService.instance.smartScheduleForChannel(channel, source: source, hours: hours);
        out.add(AurenTvMultiChannelGuide(
          channel: channel,
          nowNext: nowNext,
          schedule: schedule.take(perChannel).toList(),
        ));
      } catch (_) {
        out.add(AurenTvMultiChannelGuide(channel: channel, nowNext: null, schedule: const []));
      }
    }
    return out;
  }
}
