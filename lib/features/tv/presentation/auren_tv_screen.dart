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
  String quickRegion = '';
  bool lowData = false, onlyFavorites = false, loading = false;
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

  String _regionLabel(AurenTvChannel c) {
    final code = c.country.toUpperCase();
    for (final entry in regions.entries) { if (entry.value.contains(code)) return entry.key; }
    return 'Other';
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN TV • World')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'ابحث بذكاء: قناة، دولة، لغة أو فئة',
            suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => query = ''); }, icon: const Icon(Icons.clear)),
          ),
          onChanged: (v) => setState(() { query = v.trim().toLowerCase(); }),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'الدولة أو الرمز'), onChanged: (v) => setState(() { country = v; continent = ''; }))),
          const SizedBox(width: 8),
          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'الفئة'), onChanged: (v) => setState(() => category = v))),
        ]),
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
        future: continent.isNotEmpty ? AurenTvService.instance.loadFeaturedByCountries(regions[continent]!.toSet(), limit: 20) : AurenTvService.instance.load(country: country, category: category),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل القنوات: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final arabCountries = {'DZ','BH','KM','DJ','EG','IQ','JO','KW','LB','LY','MR','MA','OM','PS','QA','SA','SO','SD','SY','TN','AE','YE'};
          final maxChannels = lowData ? 150 : 500;
          final channels = snapshot.data!.where((c) {
            final matchesQuery = query.isEmpty || '${c.name} ${c.country} ${c.language} ${c.category}'.toLowerCase().contains(query);
            final matchesRegion = continent.isEmpty || _regionLabel(c) == continent;
            final matchesQuick = quickRegion == 'Sudan' ? c.country.toUpperCase() == 'SD' : quickRegion == 'Arab' ? arabCountries.contains(c.country.toUpperCase()) : true;
            return matchesQuery && matchesRegion && matchesQuick && (!onlyFavorites || favorites.contains(c.id));
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
                trailing: IconButton(tooltip: favorites.contains(c.id) ? 'إزالة من المفضلة' : 'أضف للمفضلة', onPressed: () => toggleFavorite(c), icon: Icon(favorites.contains(c.id) ? Icons.star : Icons.star_border)),
                onTap: () => play(c),
              ));
            },
          );
        },
      )),
    ]),
  );
}
