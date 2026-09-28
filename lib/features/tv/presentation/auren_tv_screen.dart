import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/tv/auren_tv_service.dart';

class AurenTvScreen extends StatefulWidget {
  const AurenTvScreen({super.key});
  @override State<AurenTvScreen> createState() => _AurenTvScreenState();
}

class _AurenTvScreenState extends State<AurenTvScreen> {
  final _search = TextEditingController();
  String country = '', category = '', query = '', continent = '';
  String tvMode = 'world';
  String newsRegion = 'all';
  String sportCategory = 'all';
  String entertainmentCategory = 'all';
  String countryLabel = 'الدول';
  String quickRegion = '';
  bool lowData = false, onlyFavorites = false, loading = false;
  bool autoLowData = true;
  ConnectivityResult _connectionType = ConnectivityResult.wifi;
  bool _networkAvailable = true;
  DateTime? _lastRecoveryAt;
  int _bufferEvents = 0;
  Duration _totalBuffering = Duration.zero;
  List<AurenTvSource> sources = const [];
  AurenTvSource? activeSource;
  Set<String> favorites = {};
  VideoPlayerController? player;
  AurenTvChannel? playing;
  Timer? _recoveryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _bufferingSince;
  DateTime? _lastProgressAt;
  Duration? _lastPosition;
  bool _recovering = false;
  int _playerGeneration = 0;
  int _failoverAttempts = 0;
  static const int _maxFailoverAttempts = 3;

  static const regions = <String, List<String>>{
    'Africa': ['AF','DZ','AO','BJ','BW','BF','BI','CV','CM','CF','TD','KM','CD','CG','CI','DJ','EG','GQ','ER','SZ','ET','GA','GM','GH','GN','GW','KE','LS','LR','LY','MG','MW','ML','MR','MU','MA','MZ','NA','NE','NG','RW','ST','SN','SC','SL','SO','ZA','SS','SD','TZ','TG','TN','UG','ZM','ZW'],
    'Asia': ['AS','AF','BD','BT','BN','KH','CN','HK','IN','ID','IR','IQ','IL','JP','JO','KZ','KW','KG','LA','LB','MY','MV','MN','MM','NP','KP','PK','PS','PH','QA','SA','SG','KR','LK','SY','TW','TJ','TH','TR','TM','AE','UZ','VN','YE'],
    'Europe': ['AL','AD','AM','AT','AZ','BY','BE','BA','BG','HR','CY','CZ','DK','EE','FI','FR','GE','DE','GR','HU','IS','IE','IT','XK','LV','LI','LT','LU','MT','MD','MC','ME','NL','MK','NO','PL','PT','RO','RU','SM','RS','SK','SI','ES','SE','CH','UA','GB','VA'],
    'Americas': ['AG','AR','BS','BB','BZ','BO','BR','CA','CL','CO','CR','CU','DM','DO','EC','SV','GD','GT','GY','HT','HN','JM','MX','NI','PA','PY','PE','KN','LC','VC','SR','TT','US','UY','VE'],
    'Oceania': ['AU','FJ','KI','MH','FM','NR','NZ','PW','PG','WS','SB','TO','TV','VU'],
  };

  @override void initState() {
    super.initState();
    AurenTvService.instance.favorites().then((v) { if (mounted) setState(() => favorites = v); });
    AurenTvService.instance.autoRefreshSources(limit: 150).catchError((_) {});
    _recoveryTimer = Timer.periodic(const Duration(seconds: 3), (_) => _monitorPlayback());
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      final type = results.isEmpty ? ConnectivityResult.none : results.first;
      setState(() { _connectionType = type; if (autoLowData && (type == ConnectivityResult.mobile || type == ConnectivityResult.none)) lowData = true; });
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final available = results.any((r) => r != ConnectivityResult.none);
      final type = results.isEmpty ? ConnectivityResult.none : results.first;
      setState(() {
        _networkAvailable = available;
        _connectionType = type;
        if (autoLowData && (type == ConnectivityResult.mobile || type == ConnectivityResult.none)) lowData = true;
        if (autoLowData && type == ConnectivityResult.wifi) lowData = false;
      });
      if (available && player?.value.isInitialized == true && player!.value.isBuffering && !_recovering) {
        _recoverPlayback(reason: 'عاد الاتصال بالإنترنت');
      }
    });
    AurenTvService.instance.sources().then((v) async {
      final defaultId = await AurenTvService.instance.defaultSourceId();
      if (!mounted) return;
      setState(() {
        sources = v;
        final matches = v.where((x) => x.id == defaultId && x.enabled).toList();
        activeSource = matches.isEmpty ? null : matches.first;
      });
    });
  }

  void _smartSearch(String value) {
    final normalized = _normalizeSearch(value);
    setState(() => query = normalized);
  }

  @override void dispose() {
    _search.dispose();
    _recoveryTimer?.cancel();
    _connectivitySubscription?.cancel();
    player?.dispose();
    super.dispose();
  }

  String _favoriteKey(AurenTvChannel c) {
    final clean = (String value) => value.toLowerCase()
        .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^a-z0-9\\u0600-\\u06ff]+'), '');
    final tvg = clean(c.tvgId);
    return tvg.isNotEmpty ? 'tvg:$tvg' : 'name:${clean(c.name)}|country:${clean(c.country)}';
  }

  Future<void> toggleFavorite(AurenTvChannel c) async {
    final key = _favoriteKey(c);
    final value = !favorites.contains(c.id) && !favorites.contains(key);
    await AurenTvService.instance.setChannelFavorite(c, value);
    if (mounted) setState(() {
      if (value) { favorites.add(key); favorites.remove(c.id); }
      else { favorites.remove(key); favorites.remove(c.id); }
    });
  }

  Future<void> play(AurenTvChannel c) async {
    _failoverAttempts = 0;
    _bufferingSince = null;
    _lastPosition = null;
    _lastProgressAt = DateTime.now();
    final generation = ++_playerGeneration;
    if (mounted) setState(() { loading = true; });
    final resolved = await AurenTvService.instance.bestAvailableChannel(c);
    if (!mounted || generation != _playerGeneration) return;
    final channel = resolved ?? c;
    if (lowData) {
      // Low Data mode avoids automatic playback and keeps the player from
      // starting until the user explicitly taps Play.
      if (mounted) setState(() => loading = false);
    }
    await player?.dispose();
    if (!mounted || generation != _playerGeneration) return;
    final p = VideoPlayerController.networkUrl(Uri.parse(channel.url));
    player = p;
    playing = channel;
    p.addListener(_onPlayerValueChanged);
    try {
      await p.initialize();
      if (!mounted || generation != _playerGeneration) {
        await p.dispose();
        return;
      }
      if (_bufferingSince != null) {
        _totalBuffering += DateTime.now().difference(_bufferingSince!);
        _bufferEvents++;
      }
      _bufferingSince = null;
      _lastPosition = p.value.position;
      _lastProgressAt = DateTime.now();
      setState(() { loading = false; });
      if (!lowData) await p.play();
    } catch (_) {
      if (!mounted || generation != _playerGeneration) return;
      setState(() { loading = false; });
      await _recoverPlayback(reason: 'تعذر تشغيل البث');
    }
  }

  void _onPlayerValueChanged() {
    final p = player;
    if (!mounted || p == null || !p.value.isInitialized) return;
    final value = p.value;
    if (value.hasError) {
      _recoverPlayback(reason: 'انقطع البث');
      return;
    }
    if (!value.isBuffering) {
      _bufferingSince = null;
      if (_lastPosition == null || value.position != _lastPosition) {
        _lastPosition = value.position;
        _lastProgressAt = DateTime.now();
      }
    } else {
      _bufferingSince ??= DateTime.now();
    }
  }

  void _monitorPlayback() {
    final p = player;
    if (!mounted || p == null || !p.value.isInitialized || _recovering) return;
    if (!_networkAvailable) return;
    final value = p.value;
    if (value.hasError) {
      _recoverPlayback(reason: 'انقطع البث');
      return;
    }
    if (value.isBuffering) {
      _bufferingSince ??= DateTime.now();
      final bufferingFor = DateTime.now().difference(_bufferingSince!);
      // Adaptive buffering: tolerate short mobile-network stalls, then recover.
      final threshold = lowData ? const Duration(seconds: 12) : const Duration(seconds: 8);
      if (bufferingFor >= threshold && DateTime.now().difference(_lastRecoveryAt ?? DateTime.fromMillisecondsSinceEpoch(0)) >= const Duration(seconds: 15)) {
        _recoverPlayback(reason: 'البث متوقف مؤقتاً');
      }
      return;
    }
    if (value.isPlaying) {
      _lastPosition ??= value.position;
      _lastProgressAt ??= DateTime.now();
      if (value.position != _lastPosition) {
        _lastPosition = value.position;
        _lastProgressAt = DateTime.now();
      } else if (DateTime.now().difference(_lastProgressAt!) >= const Duration(seconds: 12)) {
        _recoverPlayback(reason: 'البث لا يتقدم');
      }
    }
  }

  Future<List<AurenTvChannel>> _recoveryCandidates(AurenTvChannel current) async {
    final identity = AurenTvService.channelIdentity(current);
    final result = <AurenTvChannel>[];
    final seen = <String>{};
    for (final source in (await AurenTvService.instance.sources()).where((x) => x.enabled)) {
      try {
        final channels = await AurenTvService.instance.loadSource(source, limit: 500);
        for (final candidate in channels) {
          if (AurenTvService.channelIdentity(candidate) != identity) continue;
          if (candidate.url == current.url) continue;
          if (!seen.add(candidate.url)) continue;
          result.add(candidate);
        }
      } catch (_) {}
    }
    result.sort((a, b) {
      int score(AurenTvChannel c) =>
          (c.url.startsWith('https://') ? 2 : 0) +
          (c.tvgId.isNotEmpty ? 2 : 0) +
          (c.logo.isNotEmpty ? 1 : 0);
      return score(b).compareTo(score(a));
    });
    return result;
  }

  Future<void> _recoverPlayback({required String reason}) async {
    if (!mounted || _recovering || playing == null) return;
    if (_failoverAttempts >= _maxFailoverAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر استعادة البث تلقائياً. يمكنك اختيار القناة مرة أخرى.')),
      );
      return;
    }
    _recovering = true;
    _lastRecoveryAt = DateTime.now();
    _failoverAttempts++;
    final generation = ++_playerGeneration;
    final current = playing!;
    _bufferingSince = null;
    _lastPosition = null;
    _lastProgressAt = DateTime.now();
    try {
      final candidates = await _recoveryCandidates(current);
      if (!mounted || generation != _playerGeneration) return;
      final ranked = <AurenTvChannel>[];
      for (final candidate in candidates) {
        final health = await AurenTvService.instance.checkChannelHealth(
          candidate,
          timeout: const Duration(seconds: 4),
        );
        if (health.status == 'online') ranked.add(candidate);
      }
      if (ranked.isEmpty) ranked.addAll(candidates);
      for (final candidate in ranked) {
        if (!mounted || generation != _playerGeneration) return;
        final old = player;
        player = null;
        await old?.dispose();
        final next = VideoPlayerController.networkUrl(Uri.parse(candidate.url));
        player = next;
        playing = candidate;
        next.addListener(_onPlayerValueChanged);
        try {
          await next.initialize();
          if (!mounted || generation != _playerGeneration) {
            await next.dispose();
            return;
          }
          if (_bufferingSince != null) {
            _totalBuffering += DateTime.now().difference(_bufferingSince!);
            _bufferEvents++;
          }
          _bufferingSince = null;
          _lastPosition = next.value.position;
          _lastProgressAt = DateTime.now();
          setState(() { loading = false; });
          if (!lowData) await next.play();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استعادة البث تلقائياً عبر مصدر بديل.')),
          );
          return;
        } catch (_) {
          await next.dispose();
        }
      }
      if (mounted) {
        setState(() { loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$reason؛ لم يتوفر مصدر بديل صالح حالياً.')),
        );
      }
    } finally {
      _recovering = false;
    }
  }
  Future<void> _pickCountry() async {
    final countries = <String, String>{
      'SD': 'السودان 🇸🇩', 'EG': 'مصر 🇪🇬', 'SA': 'السعودية 🇸🇦', 'AE': 'الإمارات 🇦🇪',
      'QA': 'قطر 🇶🇦', 'KW': 'الكويت 🇰🇼', 'BH': 'البحرين 🇧🇭', 'OM': 'عُمان 🇴🇲',
      'JO': 'الأردن 🇯🇴', 'IQ': 'العراق 🇮🇶', 'LB': 'لبنان 🇱🇧', 'MA': 'المغرب 🇲🇦',
      'DZ': 'الجزائر 🇩🇿', 'TN': 'تونس 🇹🇳', 'TR': 'تركيا 🇹🇷', 'ZA': 'جنوب أفريقيا 🇿🇦',
      'NG': 'نيجيريا 🇳🇬', 'KE': 'كينيا 🇰🇪', 'IN': 'الهند 🇮🇳', 'CN': 'الصين 🇨🇳',
      'JP': 'اليابان 🇯🇵', 'KR': 'كوريا الجنوبية 🇰🇷', 'GB': 'بريطانيا 🇬🇧', 'FR': 'فرنسا 🇫🇷',
      'DE': 'ألمانيا 🇩🇪', 'IT': 'إيطاليا 🇮🇹', 'ES': 'إسبانيا 🇪🇸', 'US': 'الولايات المتحدة 🇺🇸',
      'CA': 'كندا 🇨🇦', 'BR': 'البرازيل 🇧🇷', 'AU': 'أستراليا 🇦🇺',
    };
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('اختر دولة', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('يمكنك أيضاً استخدام البحث لاسم قناة أو لغة أو فئة.'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('كل الدول'),
              selected: country.isEmpty && continent.isEmpty && quickRegion.isEmpty,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...countries.entries.map((entry) => ListTile(
              leading: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              title: Text(entry.value),
              selected: country == entry.key,
              onTap: () => Navigator.pop(ctx, entry.key),
            )),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      country = picked;
      countryLabel = picked.isEmpty ? 'الدول' : (countries[picked] ?? picked);
      continent = '';
      quickRegion = '';
    });
  }

  Future<void> _showSchedule(AurenTvChannel channel) async {
    final items = activeSource != null
        ? await AurenTvService.instance.scheduleForSourceChannel(activeSource!, channel, hours: 24)
        : await AurenTvService.instance.scheduleForChannel(channel, hours: 24);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * .72,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              if (channel.logo.isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(channel.logo)),
              const SizedBox(width: 10),
              Expanded(child: Text(channel.name + ' • EPG', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            ])),
            const Divider(height: 1),
            if (items.isEmpty) const Expanded(child: Center(child: Text('دليل البرامج غير متاح لهذه القناة حالياً.')))
            else Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(12), itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final x = items[i];
                final start = DateTime.tryParse(x['startIso'] ?? '')?.toLocal();
                final stop = DateTime.tryParse(x['stopIso'] ?? '')?.toLocal();
                final time = start == null || stop == null ? '' : '${TimeOfDay.fromDateTime(start).format(ctx)} — ${TimeOfDay.fromDateTime(stop).format(ctx)}';
                final isNow = x['state'] == 'now';
                return Card(child: ListTile(leading: CircleAvatar(child: Icon(isNow ? Icons.play_arrow : Icons.schedule)), title: Text(x['title'] ?? 'برنامج'), subtitle: Text(time), trailing: isNow ? const Chip(label: Text('الآن')) : null));
              },
            )),
          ]),
        ),
      ),
    );
  }


  Future<void> _checkChannel(AurenTvChannel channel) async {
    final health = await AurenTvService.instance.checkChannelHealth(channel);
    if (!mounted) return;
    final detail = health.latencyMs == null ? health.status : '${health.status} • ${health.latencyMs}ms';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حالة ${channel.name}: $detail')));
  }

  Future<void> _testSource(AurenTvSource source) async {
    try {
      final count = await AurenTvService.instance.testSource(source);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الاتصال ناجح • $count قناة متاحة')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل اختبار الاتصال: $e')));
    }
  }

  Future<void> _toggleSource(AurenTvSource source) async {
    final enabled = !source.enabled;
    await AurenTvService.instance.setSourceEnabled(source.id, enabled);
    if (!mounted) return;
    final updated = AurenTvSource(id: source.id, name: source.name, type: source.type, url: source.url, epgUrl: source.epgUrl, username: source.username, password: source.password, enabled: enabled);
    setState(() {
      sources = sources.map((x) => x.id == source.id ? updated : x).toList();
      if (!enabled && activeSource?.id == source.id) activeSource = null;
    });
  }

  Future<void> _makeDefault(AurenTvSource source) async {
    await AurenTvService.instance.setDefaultSource(source.id);
    if (!mounted) return;
    setState(() => activeSource = source);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيين المصدر الافتراضي.')));
  }

  Future<void> _showSources() async {
    final choice = await showModalBottomSheet<String>(
      context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const ListTile(title: Text('مصادر IPTV الخاصة بي', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('أضف M3U أو Xtream من اشتراك تملكه أو لديك حق استخدامه.')),
          ListTile(leading: const Icon(Icons.add_link), title: const Text('إضافة مصدر'), onTap: () => Navigator.pop(ctx, '__add__')),
          ...sources.map((source) => ListTile(
            leading: Icon(source.type == 'xtream' ? Icons.cloud : Icons.link),
            title: Text(source.name),
            subtitle: Text('${source.type == 'xtream' ? 'Xtream' : 'M3U'} • ${source.enabled ? 'مفعّل' : 'متوقف'}${activeSource?.id == source.id ? ' • نشط' : ''}'),
            trailing: Wrap(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'اختبار الاتصال', icon: const Icon(Icons.network_check), onPressed: source.enabled ? () => _testSource(source) : null),
              IconButton(tooltip: source.enabled ? 'تعطيل المصدر' : 'تفعيل المصدر', icon: Icon(source.enabled ? Icons.toggle_on : Icons.toggle_off), onPressed: () => _toggleSource(source)),
              IconButton(tooltip: 'جعله افتراضي', icon: const Icon(Icons.star_border), onPressed: source.enabled ? () => _makeDefault(source) : null),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
                await AurenTvService.instance.deleteSource(source.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {
                  sources = sources.where((x) => x.id != source.id).toList();
                  if (activeSource?.id == source.id) activeSource = null;
                });
              }),
            ]),
            onTap: source.enabled ? () => Navigator.pop(ctx, source.id) : null,
          )),
        ],
      )),
    );
    if (!mounted || choice == null) return;
    if (choice == '__add__') { await _addSource(); return; }
    final matches = sources.where((x) => x.id == choice).toList();
    final selected = matches.isEmpty ? null : matches.first;
    if (selected == null || !selected.enabled) return;
    setState(() { activeSource = selected; tvMode = 'world'; country = ''; continent = ''; quickRegion = ''; });
  }

  Future<void> _addSource() async {
    String type = 'm3u';
    final name = TextEditingController(text: 'IPTV الخاص بي');
    final url = TextEditingController();
    final epg = TextEditingController();
    final user = TextEditingController();
    final pass = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const Text('إضافة مصدر IPTV'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'النوع'), items: const [DropdownMenuItem(value: 'm3u', child: Text('M3U URL')), DropdownMenuItem(value: 'xtream', child: Text('Xtream API'))], onChanged: (v) => setLocal(() => type = v ?? 'm3u')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المصدر')),
        TextField(controller: url, decoration: InputDecoration(labelText: type == 'xtream' ? 'رابط السيرفر / Base URL' : 'رابط M3U'), keyboardType: TextInputType.url),
        if (type == 'xtream') ...[TextField(controller: user, decoration: const InputDecoration(labelText: 'Username')), TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true)],
        TextField(controller: epg, decoration: const InputDecoration(labelText: 'EPG URL (اختياري)'), keyboardType: TextInputType.url),
        const SizedBox(height: 8), const Text('بيانات الدخول تُحفظ محلياً في التخزين الآمن للجهاز.', style: TextStyle(fontSize: 12)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
    )));
    if (ok != true) { name.dispose(); url.dispose(); epg.dispose(); user.dispose(); pass.dispose(); return; }
    final source = AurenTvSource(id: 'src-${DateTime.now().microsecondsSinceEpoch}', name: name.text.trim().isEmpty ? 'IPTV الخاص بي' : name.text.trim(), type: type, url: url.text.trim(), epgUrl: epg.text.trim(), username: user.text.trim(), password: pass.text);
    await AurenTvService.instance.saveSource(source);
    await AurenTvService.instance.setDefaultSource(source.id);
    if (mounted) setState(() { sources = [...sources, source]; activeSource = source; });
    name.dispose(); url.dispose(); epg.dispose(); user.dispose(); pass.dispose();
  }
  String _normalizeSearch(String value) {
    return value.toLowerCase()
        .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه').replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '')
        .replaceAll(RegExp(r'[^a-z0-9A-Za-z0-9\u0600-\u06ff ]+'), ' ')
        .trim();
  }

  String _regionLabel(AurenTvChannel c) {
    final code = c.country.toUpperCase();
    for (final entry in regions.entries) { if (entry.value.contains(code)) return entry.key; }
    return 'Other';
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN TV'), actions: [
      IconButton(tooltip: 'مصادر IPTV الخاصة بي', onPressed: _showSources, icon: const Icon(Icons.link)),
      if (activeSource != null)
        IconButton(
          tooltip: 'تحديث مصدر IPTV',
          onPressed: () async {
            try {
              await AurenTvService.instance.refreshSource(activeSource!, limit: lowData ? 150 : 500);
              if (mounted) setState(() {});
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر تحديث مصدر IPTV حالياً.')),
              );
            }
          },
          icon: const Icon(Icons.refresh),
        ),
    ]),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(segments: const [
        ButtonSegment(value: 'world', label: Text('العالم'), icon: Icon(Icons.public)),
        ButtonSegment(value: 'entertainment', label: Text('ترفيه'), icon: Icon(Icons.movie_outlined)),
        ButtonSegment(value: 'sports', label: Text('رياضة'), icon: Icon(Icons.sports_soccer)),
        ButtonSegment(value: 'news', label: Text('أخبار'), icon: Icon(Icons.newspaper)),
        ButtonSegment(value: 'movies', label: Text('أفلام'), icon: Icon(Icons.local_movies_outlined)),
        ButtonSegment(value: 'music', label: Text('موسيقى'), icon: Icon(Icons.music_note)),
        ButtonSegment(value: 'kids', label: Text('أطفال'), icon: Icon(Icons.child_care)),
        ButtonSegment(value: 'animation', label: Text('أنمي/كرتون'), icon: Icon(Icons.animation)),
        ButtonSegment(value: 'documentary', label: Text('وثائقي'), icon: Icon(Icons.menu_book_outlined)),
        ButtonSegment(value: 'series', label: Text('مسلسلات'), icon: Icon(Icons.tv_outlined)),
      ], selected: {tvMode}, onSelectionChanged: (v) => setState(() { tvMode = v.first; country = ''; continent = ''; quickRegion = ''; category = ''; newsRegion = 'all'; sportCategory = 'all'; entertainmentCategory = 'all'; })),
          ),
        ),
      ),
      if (activeSource != null) Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: Align(alignment: AlignmentDirectional.centerStart, child: Chip(
          avatar: Icon(activeSource!.type == 'xtream' ? Icons.cloud : Icons.link, size: 18),
          label: Text('المصدر: ' + activeSource!.name),
          onDeleted: () => setState(() => activeSource = null),
        )),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'ابحث بذكاء: قناة، دولة، لغة أو فئة',
            suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.clear)),
          ),
          onChanged: (v) => setState(() { query = _normalizeSearch(v); }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _pickCountry, icon: const Icon(Icons.public), label: Text(countryLabel), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
          const SizedBox(width: 8),
          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'الفئة'), onChanged: (v) => setState(() => category = v))),
        ]),
      ),
      if (tvMode == 'sports' || tvMode == 'entertainment')
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final item in (tvMode == 'sports'
                  ? const [['all', 'كل الرياضات'], ['football', '⚽ كرة القدم'], ['basketball', '🏀 كرة السلة'], ['tennis', '🎾 التنس'], ['motorsport', '🏎️ سباقات'], ['combat', '🥊 قتال'], ['golf', '🏌️ غولف'], ['other', '🏆 أخرى']]
                  : const [['all', 'كل الترفيه'], ['movies', '🎬 أفلام'], ['series', '📺 مسلسلات'], ['comedy', '😂 كوميديا'], ['music', '🎵 موسيقى'], ['kids', '👶 أطفال'], ['animation', '🎨 أنمي/كرتون'], ['culture', '🌍 ثقافة'], ['documentary', '📚 وثائقي']]))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(item[1]),
                    selected: (tvMode == 'sports' ? sportCategory : entertainmentCategory) == item[0],
                    onSelected: (_) => setState(() {
                      if (tvMode == 'sports') { sportCategory = item[0]; } else { entertainmentCategory = item[0]; }
                      category = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
      if (tvMode == 'news')
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final item in const [
                ['all', 'كل الأخبار'],
                ['SD', '🇸🇩 السودان'],
                ['Arab', '🌙 عربي'],
                ['Africa', '🌍 أفريقيا'],
                ['World', '🌐 عالمي'],
                ['Business', '💼 اقتصاد'],
                ['Sports', '⚽ أخبار الرياضة'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(item[1]),
                    selected: newsRegion == item[0],
                    onSelected: (_) => setState(() {
                      newsRegion = item[0];
                      country = '';
                      continent = '';
                      quickRegion = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
      SizedBox(height: 42, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: const Text('🇸🇩 السودان'), selected: quickRegion == 'Sudan', onSelected: (_) => setState(() { quickRegion = quickRegion == 'Sudan' ? '' : 'Sudan'; country = quickRegion == 'Sudan' ? 'SD' : ''; continent = ''; }))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: const Text('🌍 عربي'), selected: quickRegion == 'Arab', onSelected: (_) => setState(() { quickRegion = quickRegion == 'Arab' ? '' : 'Arab'; country = ''; continent = ''; }))),
          for (final region in regions.keys)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(region), selected: continent == region, onSelected: (_) => setState(() { continent = continent == region ? '' : region; country = ''; quickRegion = ''; }))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilterChip(
            label: const Text('المفضلة'), selected: onlyFavorites, onSelected: (v) => setState(() => onlyFavorites = v),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: FilterChip(
            label: const Text('Low Data'), selected: lowData, onSelected: (v) => setState(() => lowData = v),
          )),
        ],
      )),
      if (playing != null && _bufferEvents > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Align(alignment: AlignmentDirectional.centerStart, child: Text('Smart Buffer • $_bufferEvents توقف • ${_totalBuffering.inSeconds}s', style: const TextStyle(fontSize: 11))),
        ),
      if (lowData) Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          const Icon(Icons.data_saver_on, size: 16), const SizedBox(width: 6),
          Expanded(child: Text(autoLowData ? 'Low Data تلقائي • ${_connectionType == ConnectivityResult.mobile ? 'بيانات الهاتف' : 'اتصال محدود'} • التشغيل يبدأ عند الطلب' : 'Low Data • التشغيل يبدأ عند الطلب', style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: () => setState(() => autoLowData = !autoLowData), child: Text(autoLowData ? 'يدوي' : 'تلقائي')),
        ]),
      ),
      if (!_networkAvailable)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [Icon(Icons.wifi_off, size: 16), SizedBox(width: 6), Text('لا يوجد اتصال بالإنترنت حالياً.')]),
        ),
      if (loading) const LinearProgressIndicator(),
      if (player?.value.isInitialized == true)
        Column(children: [
          AspectRatio(aspectRatio: player!.value.aspectRatio, child: VideoPlayer(player!)),
          Row(children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(playing?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis))),
            IconButton(onPressed: () async {
              if (player!.value.isPlaying) { await player!.pause(); }
              else { await player!.play(); }
              if (mounted) setState(() {});
            }, icon: Icon(player!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
          ]),
          if (playing != null)
            FutureBuilder<Map<String, String>?>(
              future: AurenTvService.instance.nowNextForChannel(playing!, source: activeSource),
              builder: (context, snapshot) {
                final guide = snapshot.data;
                if (guide == null) return const Padding(padding: EdgeInsets.all(6), child: Text('دليل البرامج غير متاح لهذه القناة حالياً.'));
                return Card(margin: const EdgeInsets.fromLTRB(12, 2, 12, 8), child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('دليل البرامج • EPG', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الآن: ${(guide['current'] ?? '').isEmpty ? 'غير متاح' : guide['current']}'),
                    Text('القادم: ${(guide['next'] ?? '').isEmpty ? 'غير متاح' : guide['next']}'),
                    if ((guide['currentStart'] ?? '').isNotEmpty && (guide['currentStop'] ?? '').isNotEmpty) Builder(builder: (_) {
                      final start = DateTime.tryParse(guide['currentStart']!)?.toLocal();
                      final stop = DateTime.tryParse(guide['currentStop']!)?.toLocal();
                      if (start == null || stop == null || !stop.isAfter(start)) return const SizedBox.shrink();
                      final now = DateTime.now();
                      final progress = now.isBefore(start) ? 0.0 : now.isAfter(stop) ? 1.0 : now.difference(start).inMilliseconds / stop.difference(start).inMilliseconds;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0))),
                      );
                    }),
                  ]),
                ));
              },
            ),
        ]),
      Expanded(child: FutureBuilder<List<AurenTvChannel>>(
        future: activeSource != null ? AurenTvService.instance.loadSource(activeSource!, limit: lowData ? 150 : 500) : tvMode == 'entertainment' ? AurenTvService.instance.loadEntertainment(limit: lowData ? 150 : 500) : tvMode == 'sports' ? AurenTvService.instance.loadSports(limit: lowData ? 150 : 500) : tvMode == 'news' ? AurenTvService.instance.loadNews(limit: lowData ? 150 : 500) : tvMode == 'movies' ? AurenTvService.instance.loadMovies(limit: lowData ? 150 : 500) : tvMode == 'music' ? AurenTvService.instance.loadMusic(limit: lowData ? 150 : 500) : tvMode == 'kids' ? AurenTvService.instance.loadKids(limit: lowData ? 150 : 500) : tvMode == 'animation' ? AurenTvService.instance.loadAnimation(limit: lowData ? 150 : 500) : tvMode == 'documentary' ? AurenTvService.instance.loadDocumentary(limit: lowData ? 150 : 500) : tvMode == 'series' ? AurenTvService.instance.loadSeries(limit: lowData ? 150 : 500) : continent.isNotEmpty ? AurenTvService.instance.loadFeaturedByCountries(regions[continent]!.toSet(), limit: 20) : AurenTvService.instance.load(country: country, category: category),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل القنوات: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final arabCountries = {'DZ','BH','KM','DJ','EG','IQ','JO','KW','LB','LY','MR','MA','OM','PS','QA','SA','SO','SD','SY','TN','AE','YE'};
          final maxChannels = lowData ? 150 : 500;
          final channels = snapshot.data!.where((c) {
            final searchable = _normalizeSearch('${c.name} ${c.country} ${c.language} ${c.category}');
            final searchableTokens = searchable.split(RegExp(r'\\s+')).where((x) => x.isNotEmpty).toList();
            final matchesQuery = query.isEmpty || searchable.contains(query) || query.split(RegExp(r'\\s+')).every((q) => searchableTokens.any((token) => token.contains(q) || q.contains(token)));
            final matchesRegion = continent.isEmpty || _regionLabel(c) == continent;
            final n = '${c.name} ${c.category} ${c.language} ${c.country}'.toLowerCase();
            final matchesNewsRegion = tvMode != 'news' || newsRegion == 'all' || (newsRegion == 'SD' && c.country.toUpperCase() == 'SD') || (newsRegion == 'Arab' && arabCountries.contains(c.country.toUpperCase())) || (newsRegion == 'Africa' && _regionLabel(c) == 'Africa') || (newsRegion == 'World' && _regionLabel(c) != 'Africa' && !arabCountries.contains(c.country.toUpperCase())) || (newsRegion == 'Business' && RegExp(r'business|finance|economy|market|money', caseSensitive: false).hasMatch(n)) || (newsRegion == 'Sports' && RegExp(r'sport|football|soccer|basketball|tennis|espn', caseSensitive: false).hasMatch(n));
            final matchesQuick = quickRegion == 'Sudan' ? c.country.toUpperCase() == 'SD' : quickRegion == 'Arab' ? arabCountries.contains(c.country.toUpperCase()) : true;
            final sportText = n;
            final matchesSportCategory = tvMode != 'sports' || sportCategory == 'all' ||
              (sportCategory == 'football' && RegExp(r'football|soccer|fifa|uefa|premier|league|cup', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'basketball' && RegExp(r'basketball|nba|fiba', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'tennis' && RegExp(r'tennis|atp|wta', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'motorsport' && RegExp(r'formula|f1|motorsport|nascar|racing|motogp', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'combat' && RegExp(r'boxing|mma|ufc|wrestling|fight', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'golf' && RegExp(r'golf', caseSensitive: false).hasMatch(sportText)) ||
              (sportCategory == 'other' && !RegExp(r'football|soccer|basketball|tennis|formula|f1|motorsport|nascar|racing|motogp|boxing|mma|ufc|wrestling|fight|golf', caseSensitive: false).hasMatch(sportText));
            final matchesEntertainmentCategory = tvMode != 'entertainment' || entertainmentCategory == 'all' ||
              (entertainmentCategory == 'movies' && RegExp(r'movie|film|cinema', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'series' && RegExp(r'series|serial|drama|soap', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'comedy' && RegExp(r'comedy|humor|funny', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'music' && RegExp(r'music|musical|mtv|vh1', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'kids' && RegExp(r'kids|children|nickelodeon|cartoon', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'animation' && RegExp(r'anime|animation|cartoon', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'culture' && RegExp(r'culture|cultural|travel', caseSensitive: false).hasMatch(n)) ||
              (entertainmentCategory == 'documentary' && RegExp(r'documentary|documentaries', caseSensitive: false).hasMatch(n));
            return matchesQuery && matchesRegion && matchesQuick && matchesNewsRegion && matchesSportCategory && matchesEntertainmentCategory && (!onlyFavorites || favorites.contains(c.id) || favorites.contains(_favoriteKey(c)));
          }).toList();
          if (channels.isEmpty) return const Center(child: Text('ما لقينا قنوات مطابقة. جرّب تغيير البحث أو الدولة.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: channels.take(maxChannels).length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final c = channels[i];
              return Card(child: ListTile(
                leading: c.logo.isEmpty ? const CircleAvatar(child: Icon(Icons.tv)) : CircleAvatar(backgroundImage: NetworkImage(c.logo)),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${c.country} • ${c.language} • ${c.category}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Wrap(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'جدول البرامج', onPressed: () => _showSchedule(c), icon: const Icon(Icons.calendar_month_outlined)),
                  IconButton(tooltip: (favorites.contains(c.id) || favorites.contains(_favoriteKey(c))) ? 'إزالة من المفضلة' : 'أضف للمفضلة', onPressed: () => toggleFavorite(c), icon: Icon((favorites.contains(c.id) || favorites.contains(_favoriteKey(c))) ? Icons.star : Icons.star_border)),
                ]),
                onTap: () => play(c),
              ));
            },
          );
        },
      )),
    ]),
  );
}
