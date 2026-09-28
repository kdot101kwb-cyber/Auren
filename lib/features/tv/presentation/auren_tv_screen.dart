import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  bool sourceRefreshing = false;
  List<AurenTvSource> sources = const [];
  AurenTvSource? activeSource;
  Set<String> favorites = {};
  VideoPlayerController? player;
  AurenTvChannel? playing;

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
    AurenTvService.instance.sources().then((v) { if (mounted) setState(() => sources = v); });
  }

  @override void dispose() {
    _search.dispose();
    player?.dispose();
    super.dispose();
  }

  Future<void> toggleFavorite(AurenTvChannel c) async {
    final value = !favorites.contains(c.id);
    await AurenTvService.instance.setFavorite(c.id, value);
    if (mounted) setState(() { if (value) { favorites.add(c.id); } else { favorites.remove(c.id); } });
  }

  Future<void> play(AurenTvChannel c) async {
    setState(() { loading = true; });
    await player?.dispose();
    final p = VideoPlayerController.networkUrl(Uri.parse(c.url));
    player = p;
    playing = c;
    try {
      await p.initialize();
      if (!mounted) return;
      setState(() { loading = false; });
      if (!lowData) await p.play();
    } catch (_) {
      if (mounted) {
        setState(() { loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل القناة؛ قد تكون غير متاحة أو محجوبة جغرافياً.')));
      }
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
    final items = await AurenTvService.instance.schedule(channel.tvgId, hours: 24);
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


  Future<void> _showSources() async {
    final choice = await showModalBottomSheet<String>(
      context: context, showDragHandle: true,
      builder: (ctx) => SafeArea(child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const ListTile(title: Text('مصادر IPTV الخاصة بي', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('أضف M3U أو Xtream من اشتراك تملكه أو لديك حق استخدامه.')),
          ListTile(leading: const Icon(Icons.add_link), title: const Text('إضافة مصدر'), onTap: () => Navigator.pop(ctx, '__add__')),
          ...sources.map((source) => ListTile(leading: Icon(source.type == 'xtream' ? Icons.cloud : Icons.link), title: Text(source.name), subtitle: Text(source.type == 'xtream' ? 'Xtream' : 'M3U'), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await AurenTvService.instance.deleteSource(source.id); if (ctx.mounted) Navigator.pop(ctx); if (mounted) setState(() => sources = sources.where((x) => x.id != source.id).toList()); } ), onTap: () => Navigator.pop(ctx, source.id))),
        ],
      )),
    );
    if (!mounted || choice == null) return;
    if (choice == '__add__') { await _addSource(); return; }
    final matches = sources.where((x) => x.id == choice).toList();
    final selected = matches.isEmpty ? null : matches.first;
    if (selected == null) return;
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

  Future<void> _refreshActiveSource() async {
    final source = activeSource;
    if (source == null || sourceRefreshing) return;
    setState(() => sourceRefreshing = true);
    try {
      await AurenTvService.instance.refreshSource(source);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث مصدر IPTV.')));
    } finally {
      if (mounted) setState(() => sourceRefreshing = false);
    }
  }
  String _regionLabel(AurenTvChannel c) {
    final code = c.country.toUpperCase();
    for (final entry in regions.entries) { if (entry.value.contains(code)) return entry.key; }
    return 'Other';
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN TV'), actions: [
      if (activeSource != null) IconButton(tooltip: 'تحديث المصدر الحالي', onPressed: sourceRefreshing ? null : _refreshActiveSource, icon: sourceRefreshing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh)),
      IconButton(tooltip: 'مصادر IPTV الخاصة بي', onPressed: _showSources, icon: const Icon(Icons.link)),
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
      if (playing != null && !lowData) const SizedBox.shrink(),
      if (lowData) const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text('وضع توفير البيانات: لا يبدأ التشغيل تلقائياً. جودة البث تعتمد على رابط القناة.', style: TextStyle(fontSize: 12)),
      ),
      if (loading) const LinearProgressIndicator(),
      if (player?.value.isInitialized == true)
        Column(children: [
          AspectRatio(aspectRatio: player!.value.aspectRatio, child: VideoPlayer(player!)),
          Row(children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(playing?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis))),
            IconButton(onPressed: () => setState(() => player!.value.isPlaying ? player!.pause() : player!.play()), icon: Icon(player!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
          ]),
          if (playing != null)
            FutureBuilder<Map<String, String>?>(
              future: AurenTvService.instance.nowNext(playing!.tvgId),
              builder: (context, snapshot) {
                final guide = snapshot.data;
                if (guide == null) return const Padding(padding: EdgeInsets.all(6), child: Text('دليل البرامج غير متاح لهذه القناة حالياً.'));
                return Card(margin: const EdgeInsets.fromLTRB(12, 2, 12, 8), child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('دليل البرامج • EPG', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الآن: ${(guide['current'] ?? '').isEmpty ? 'غير متاح' : guide['current']}'),
                    Text('القادم: ${(guide['next'] ?? '').isEmpty ? 'غير متاح' : guide['next']}'),
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
            final matchesQuery = query.isEmpty || searchable.contains(query);
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
            return matchesQuery && matchesRegion && matchesQuick && matchesNewsRegion && matchesSportCategory && matchesEntertainmentCategory && (!onlyFavorites || favorites.contains(c.id));
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
                  IconButton(tooltip: favorites.contains(c.id) ? 'إزالة من المفضلة' : 'أضف للمفضلة', onPressed: () => toggleFavorite(c), icon: Icon(favorites.contains(c.id) ? Icons.star : Icons.star_border)),
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
