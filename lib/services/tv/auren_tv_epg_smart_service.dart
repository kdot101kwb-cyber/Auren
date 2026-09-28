import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'auren_tv_service.dart';

class AurenTvEpgSmartService {
  AurenTvEpgSmartService._();
  static final instance = AurenTvEpgSmartService._();
  static const _historyKey = 'auren_tv_epg_channel_history_v1';
  static const _smartKey = 'auren_tv_epg_smart_notifications_v1';
  static const _enabledKey = 'auren_tv_epg_smart_enabled_v1';
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _initNotifications() async {
    if (_ready) return;
    tz.initializeTimeZones();
    const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await _notifications.initialize(settings);
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _ready = true;
  }

  Future<bool> smartNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setSmartNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) await _notifications.cancelAll();
  }

  Future<void> cancelSmartNotification(AurenTvEpgSearchResult item) async {
    await _initNotifications();
    final id = 'smart_start_${item.channelId}_${item.startIso}'.hashCode & 0x7fffffff;
    await _notifications.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_smartKey) ?? <String>[];
    saved.remove('${item.channelId}|${item.title}|${item.startIso}');
    await prefs.setStringList(_smartKey, saved);
  }

  Future<void> recordChannelOpen(AurenTvChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    final key = AurenTvService.channelIdentity(channel);
    await prefs.setStringList(_historyKey, <String>[key, ...raw.where((x) => x != key)].take(100).toList());
  }

  Future<List<AurenTvChannel>> personalizeChannels(List<AurenTvChannel> channels, {int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? <String>[];
    final favorites = await AurenTvService.instance.favorites();
    final ranked = channels.map((c) {
      var score = 0;
      final identity = AurenTvService.channelIdentity(c);
      final index = history.indexOf(identity);
      if (index >= 0) score += 100 - (index > 90 ? 90 : index);
      if (favorites.contains(c.id) || favorites.contains(_favoriteKey(c))) score += 80;
      if (c.tvgId.isNotEmpty) score += 3;
      if (c.logo.isNotEmpty) score += 2;
      return MapEntry(c, score);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));
    return ranked.take(limit).map((e) => e.key).toList();
  }

  String _favoriteKey(AurenTvChannel c) {
    final clean = (String value) => value.toLowerCase()
      .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^a-z0-9\\u0600-\\u06ff]+'), '');
    final tvg = clean(c.tvgId);
    return tvg.isNotEmpty ? 'tvg:$tvg' : 'name:${clean(c.name)}|country:${clean(c.country)}';
  }

  Future<bool> scheduleSmartStart(AurenTvEpgSearchResult item) async {
    final start = DateTime.tryParse(item.startIso);
    if (start == null || !start.isAfter(DateTime.now().toUtc())) return false;
    if (!await smartNotificationsEnabled()) return false;
    await _initNotifications();
    final id = 'smart_start_${item.channelId}_${item.startIso}'.hashCode & 0x7fffffff;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_smartKey) ?? <String>[];
    final key = '${item.channelId}|${item.title}|${item.startIso}';
    if (!saved.contains(key)) {
      saved.add(key);
      await prefs.setStringList(_smartKey, saved.take(100).toList());
    }
    await _notifications.zonedSchedule(
      id,
      'AUREN TV • بدأ البرنامج',
      '${item.title} بدأ الآن',
      tz.TZDateTime.from(start, tz.UTC),
      const NotificationDetails(android: AndroidNotificationDetails('auren_tv_epg_smart', 'AUREN TV Smart EPG', channelDescription: 'تنبيهات ذكية لبدء برامج EPG')),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  Future<int> cleanupSmartNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_smartKey) ?? <String>[];
    final now = DateTime.now().toUtc();
    final keep = <String>[];
    var removed = 0;
    for (final key in saved) {
      final parts = key.split('|');
      final start = parts.length >= 3 ? DateTime.tryParse(parts[2]) : null;
      if (start == null || start.isBefore(now.subtract(const Duration(hours: 2)))) removed++; else keep.add(key);
    }
    if (removed > 0) await prefs.setStringList(_smartKey, keep);
    return removed;
  }

  Future<List<AurenTvEpgSearchResult>> aiEpgSearch(String prompt, {AurenTvSource? source}) async {
    final normalized = _normalize(prompt);
    final terms = normalized.split(RegExp(r'\\s+')).where((x) => x.length >= 2 && !_stopWords.contains(x)).take(8).join(' ');
    if (terms.isEmpty) return const [];
    return AurenTvService.instance.searchEpg(terms, source: source, hours: 48, limit: 50);
  }

  String _normalize(String value) => value.toLowerCase()
    .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
    .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '')
    .replaceAll(RegExp(r'[^a-z0-9\\u0600-\\u06ff ]+'), ' ').trim();

  static const _stopWords = <String>{
    'اريد','ابحث','بحث','عن','لي','في','على','اليوم','غدا','الان','ماذا','ما','هو','هي',
    'برنامج','برامج','قناه','قناة','القناه','القناة','الساعة','ساعه','مساء','صباح','بعد','قبل',
    'الي','التي','الذي','today','tomorrow','now','find','search','for','the','on','at',
  };
}
