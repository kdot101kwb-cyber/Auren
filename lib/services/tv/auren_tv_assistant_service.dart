import 'auren_tv_service.dart';

class AurenTvAssistantResult {
  final String intent;
  final String message;
  final List<AurenTvChannel> channels;
  final List<AurenTvEpgSearchResult> programs;
  const AurenTvAssistantResult({required this.intent, required this.message, this.channels = const [], this.programs = const []});
}

class AurenTvAssistantService {
  AurenTvAssistantService._();
  static final instance = AurenTvAssistantService._();

  Future<AurenTvAssistantResult> ask(String prompt, {AurenTvSource? source}) async {
    final q = _normalize(prompt);
    if (q.isEmpty) return const AurenTvAssistantResult(intent: 'help', message: 'اكتب مثلاً: قنوات السودان، أخبار، رياضة، أو ابحث عن برنامج معين.');
    if (_hasAny(q, ['تذكير','ذكرني','remind','reminder'])) return const AurenTvAssistantResult(intent: 'reminder', message: 'ابحث عن البرنامج في EPG ثم استخدم زر التذكير لتحديد 5 أو 10 أو 15 أو 30 أو 60 دقيقة قبل البداية.');
    final epg = await AurenTvService.instance.searchEpg(q, source: source, hours: 48);
    final channels = await _channelsFor(q, source);
    if (epg.isNotEmpty) return AurenTvAssistantResult(intent: 'epg', message: 'لقيت ${epg.length} نتيجة في دليل البرامج خلال 48 ساعة.', programs: epg, channels: channels);
    if (channels.isNotEmpty) return AurenTvAssistantResult(intent: 'channel', message: 'لقيت ${channels.length} قناة مطابقة لطلبك.', channels: channels);
    return AurenTvAssistantResult(intent: 'search', message: _intentHint(q));
  }

  Future<List<AurenTvChannel>> _channelsFor(String q, AurenTvSource? source) async {
    List<AurenTvChannel> base;
    if (_hasAny(q, ['سودان','السودان','sudan'])) base = await AurenTvService.instance.load(country: 'SD');
    else if (_hasAny(q, ['رياضة','sports','sport','كرة','football','soccer'])) base = await AurenTvService.instance.loadSports(limit: 100);
    else if (_hasAny(q, ['أخبار','اخبار','news'])) base = await AurenTvService.instance.loadNews(limit: 100);
    else if (_hasAny(q, ['أفلام','افلام','movies','movie','film'])) base = await AurenTvService.instance.loadMovies(limit: 100);
    else if (_hasAny(q, ['موسيقى','music'])) base = await AurenTvService.instance.loadMusic(limit: 100);
    else if (_hasAny(q, ['أطفال','اطفال','kids','children'])) base = await AurenTvService.instance.loadKids(limit: 100);
    else if (_hasAny(q, ['أنمي','انمي','animation','anime','cartoon'])) base = await AurenTvService.instance.loadAnimation(limit: 100);
    else if (source != null) base = await AurenTvService.instance.loadSource(source, limit: 150);
    else base = (await AurenTvService.instance.load()).take(250).toList();
    final tokens = _tokens(q);
    final scored = <MapEntry<AurenTvChannel, int>>[];
    for (final c in base) {
      final text = _normalize('${c.name} ${c.country} ${c.language} ${c.category}');
      final score = tokens.fold<int>(0, (sum, token) => text.contains(token) ? sum + (text == token ? 8 : 2) : sum);
      if (score > 0) scored.add(MapEntry(c, score));
    }
    scored.sort((a,b) => b.value.compareTo(a.value));
    return scored.take(30).map((x) => x.key).toList();
  }

  String _intentHint(String q) => _hasAny(q, ['tv','تلفزيون','قناة','قنوات']) ? 'ما لقيت نتيجة مباشرة. جرّب اسم القناة أو الدولة أو الفئة، مثلاً: CNN، السودان، رياضة، أفلام.' : 'ما لقيت نتيجة مباشرة. جرّب اسم قناة أو برنامج أو دولة، وسأبحث في القنوات وEPG.';
  Set<String> _tokens(String value) => _normalize(value).split(RegExp(r'\\s+')).where((x) => x.length >= 2 && !_stop.contains(x)).toSet();
  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[؟?!.,:;()\\[\\]{}]'), ' ').replaceAll(RegExp(r'\\s+'), ' ').trim();
  bool _hasAny(String value, List<String> values) => values.any((x) => value.contains(_normalize(x)));
  static const _stop = {'the','and','for','with','channel','قناة','قنوات','عايز','اريد','أريد','في','من','عن','show','tv'};
}