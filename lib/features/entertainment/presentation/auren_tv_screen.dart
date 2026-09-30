import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/auren_tv_channel_catalog.dart';
import 'entertainment_detail_screen.dart';

/// AUREN TV / IPTV hub.
/// TV channels reuse the existing public entertainment_items media infrastructure.
class AurenTvScreen extends StatefulWidget {
  const AurenTvScreen({super.key});

  @override
  State<AurenTvScreen> createState() => _AurenTvScreenState();
}

class _AurenTvScreenState extends State<AurenTvScreen> {
  final _db = FirebaseFirestore.instance;
  String _region = 'الكل';
  String _query = '';
  String _language = 'الكل';
  String _audience = 'الكل';
  bool _liveOnly = false;
  bool _showEpg = false;

  static const _regions = ['الكل', 'Africa', 'Middle East', 'Europe', 'Asia', 'Americas'];
  static const _audiences = ['الكل', 'Kids', 'Cartoon', 'Anime'];

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _channels() {
    return _db
        .collection('entertainment_items')
        .where('visibility', isEqualTo: 'public')
        .limit(200)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.where((doc) {
        final data = doc.data();
        final type = (data['type'] ?? '').toString().toLowerCase();
        return type == 'tv' || type == 'tv channel' || type == 'iptv' || type == 'channel';
      }).toList();

      items.sort((a, b) {
        final aLive = a.data()['isLive'] == true ? 0 : 1;
        final bLive = b.data()['isLive'] == true ? 0 : 1;
        return aLive.compareTo(bLive);
      });
      return items;
    });
  }

  List<String> _languages(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final values = <String>{};
    for (final doc in docs) {
      final value = (doc.data()['language'] ?? '').toString().trim();
      if (value.isNotEmpty) values.add(value);
    }
    return ['الكل', ...values.toList()..sort()];
  }

  bool _matches(Map<String, dynamic> data) {
    final q = _query.trim().toLowerCase();
    final region = (data['region'] ?? data['countryRegion'] ?? '').toString();
    final hay = '${data['title'] ?? ''} ${data['description'] ?? ''} ${data['country'] ?? ''}'.toLowerCase();

    final language = (data['language'] ?? '').toString();
    final audience = '${data['audience'] ?? ''} ${data['category'] ?? ''} ${data['genre'] ?? ''} ${data['tags'] ?? ''}'.toLowerCase();
    if (_region != 'الكل' && region != _region) return false;
    if (_language != 'الكل' && language != _language) return false;
    if (_audience != 'الكل' && !audience.contains(_audience.toLowerCase())) return false;
    if (_liveOnly && data['isLive'] != true) return false;
    if (q.isNotEmpty && !hay.contains(q)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN TV'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _channels(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل قنوات TV: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allChannels = snapshot.data ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final channels = allChannels.where((d) => _matches(d.data())).toList();
          final languages = _languages(allChannels);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _hero(context),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'ابحث عن قناة أو برنامج...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _regions.map((region) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(region),
                      selected: _region == region,
                      onSelected: (_) => setState(() => _region = region),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: languages.map((language) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(language),
                      selected: _language == language,
                      onSelected: (_) => setState(() => _language = language),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _audiences.map((audience) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(audience == 'Kids' ? 'أطفال' : audience == 'Cartoon' ? 'كرتون' : audience == 'Anime' ? 'أنمي' : 'الكل'),
                      selected: _audience == audience,
                      onSelected: (_) => setState(() => _audience = audience),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    avatar: const Icon(Icons.live_tv_rounded, size: 18),
                    label: const Text('Live فقط'),
                    selected: _liveOnly,
                    onSelected: (value) => setState(() => _liveOnly = value),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('EPG'),
                    selected: _showEpg,
                    onSelected: (value) => setState(() => _showEpg = value),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text('القنوات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  Text('${channels.length} قناة'),
                ],
              ),
              const SizedBox(height: 10),
              if (channels.isEmpty) _emptyState()
              else ...channels.map(_channelCard),
              const SizedBox(height: 20),
              _catalogExamples(),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tv_rounded, size: 38),
          SizedBox(height: 10),
          Text('TV + IPTV + Kids + Cartoon + Anime', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 7),
          Text('قنوات مباشرة ومحتوى تلفزيوني من داخل AUREN، مع مساحات للأطفال والكرتون والأنمي وبحث واكتشاف موحّد.'),
        ],
      ),
    );
  }

  Widget _channelCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] ?? 'TV Channel').toString();
    final description = (data['description'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final language = (data['language'] ?? '').toString();
    final isLive = data['isLive'] == true;
    final epg = data['epg'];
    final nextProgram = epg is List && epg.isNotEmpty && epg.first is Map
        ? (epg.first as Map)['title']?.toString()
        : null;
    final epgItems = epg is List
        ? epg.whereType<Map>().take(3).map((item) {
            final title = item['title']?.toString() ?? 'برنامج';
            final start = item['start']?.toString() ?? item['startTime']?.toString();
            return start == null ? title : '$start • $title';
          }).toList()
        : const <String>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: doc.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 64,
                  child: imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.tv_rounded, size: 34),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.black12,
                            child: Icon(Icons.tv_rounded, size: 34),
                          )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLive) ...[
                          const Icon(Icons.circle, size: 9),
                          const SizedBox(width: 5),
                          const Text('LIVE', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (country.isNotEmpty || language.isNotEmpty)
                      Text([country, language].where((v) => v.isNotEmpty).join(' • '),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (nextProgram != null)
                      Text('التالي: $nextProgram',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (_showEpg && epgItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: epgItems.map((line) => Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )).toList(),
                        ),
                      ),
                    if (description.isNotEmpty)
                      Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, size: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catalogExamples() {
    final examples = aurenTvCatalogExamples.where((item) {
      final q = _query.trim().toLowerCase();
      if (_region != 'الكل' && item.region != _region) return false;
      if (_audience != 'الكل' && item.category.toLowerCase() != _audience.toLowerCase()) return false;
      if (_language != 'الكل' && item.language != _language) return false;
      if (q.isNotEmpty && !'${item.name} ${item.description} ${item.category}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    if (examples.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('أمثلة القنوات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('دليل أسماء فقط — لا نضيف روابط بث غير مرخّصة.'),
        const SizedBox(height: 10),
        ...examples.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.tv_rounded)),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${item.category} • ${item.region} • ${item.language}'),
            trailing: const Icon(Icons.verified_outlined),
          ),
        )),
      ],
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(Icons.tv_off_rounded, size: 48),
            SizedBox(height: 10),
            Text('لا توجد قنوات TV متاحة حالياً.', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'عند إضافة قناة عامة من نوع TV / TV Channel / IPTV ستظهر هنا تلقائياً.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
