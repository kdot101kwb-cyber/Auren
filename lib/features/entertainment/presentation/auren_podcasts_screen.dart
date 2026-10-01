import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../data/auren_podcast_catalog.dart';
import 'auren_audio_player_screen.dart';
import 'auren_podcast_video_player_screen.dart';

class AurenPodcastsScreen extends StatefulWidget {
  const AurenPodcastsScreen({super.key});

  @override
  State<AurenPodcastsScreen> createState() => _AurenPodcastsScreenState();
}

class _AurenPodcastsScreenState extends State<AurenPodcastsScreen> {
  String _category = 'الكل';
  String _query = '';
  bool _discovering = false;
  List<Map<String, dynamic>> _remoteResults = const [];
  Map<String, List<Map<String, dynamic>>> _episodes = {};
  String? _loadingFeed;
  String? _analyzingEpisode;
  final Map<String, Map<String, dynamic>> _episodeAnalysis = {};

  List<String> get _categories => [
        'الكل',
        ...aurenPodcastCatalog.map((e) => e.category).toSet(),
      ];

  Future<void> _discoverPodcasts() async {
    final query = _query.trim();
    if (query.isEmpty) return;
    setState(() => _discovering = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('searchAurenPodcasts');
      final response = await callable.call({'query': query, 'country': 'US'});
      final raw = response.data is Map ? response.data['results'] : null;
      final results = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => _remoteResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر جلب البودكاست الآن: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  Future<void> _loadEpisodes(Map<String, dynamic> podcast) async {
    final feedUrl = podcast['feedUrl']?.toString() ?? '';
    if (feedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد RSS رسمي متاح لهذا البرنامج.')));
      return;
    }
    setState(() => _loadingFeed = feedUrl);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('fetchAurenPodcastFeed');
      final response = await callable.call({'feedUrl': feedUrl});
      final raw = response.data is Map ? response.data['episodes'] : null;
      final episodes = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() => _episodes[podcast['id'].toString()] = episodes);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر قراءة حلقات RSS: ' + e.toString())));
    } finally {
      if (mounted) setState(() => _loadingFeed = null);
    }
  }

  Future<void> _analyzeEpisode(Map<String, dynamic> podcast, Map<String, dynamic> episode) async {
    final episodeId = '${podcast['id']}_${episode['id']}';
    final title = episode['title']?.toString() ?? 'Episode';
    setState(() => _analyzingEpisode = episodeId);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('analyzeAurenPodcastEpisode');
      final response = await callable.call({
        'title': title,
        'description': episode['description']?.toString() ?? '',
        'podcastName': podcast['name']?.toString() ?? podcast['artist']?.toString() ?? '',
        'publishedAt': episode['publishedAt']?.toString() ?? '',
        'language': podcast['language']?.toString() ?? '',
      });
      final raw = response.data is Map ? response.data['analysis'] : null;
      if (raw is Map && mounted) {
        final analysis = Map<String, dynamic>.from(raw);
        setState(() => _episodeAnalysis[episodeId] = analysis);
        await _showEpisodeAnalysis(title, analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحليل الحلقة بالذكاء الاصطناعي: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzingEpisode = null);
    }
  }

  Future<void> _showEpisodeAnalysis(String title, Map<String, dynamic> analysis) async {
    String listText(dynamic value) => value is List
        ? value.map((e) => '• ${e.toString()}').join('\n')
        : '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Summary', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(analysis['summary']?.toString() ?? '', style: const TextStyle(fontSize: 16, height: 1.45)),
              if ((analysis['category']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('التصنيف: ${analysis['category']}'),
              ],
              if (listText(analysis['topics']).isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('المواضيع', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(listText(analysis['topics'])),
              ],
              if (listText(analysis['keyPoints']).isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('أهم النقاط', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(listText(analysis['keyPoints'])),
              ],
              if (listText(analysis['learningPoints']).isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('ماذا نتعلم؟', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(listText(analysis['learningPoints'])),
              ],
              if (listText(analysis['actionPoints']).isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('خطوات قابلة للتطبيق', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(listText(analysis['actionPoints'])),
              ],
              if ((analysis['contentNote']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(analysis['contentNote']!.toString(), style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AurenEntertainmentItem _episodeItem(Map<String, dynamic> podcast, Map<String, dynamic> episode) {
    return AurenEntertainmentItem(
      id: 'rss_' + podcast['id'].toString() + '_' + episode['id'].toString(),
      title: episode['title']?.toString() ?? 'Episode',
      type: 'Podcast',
      description: episode['description']?.toString() ?? '',
      imageUrl: episode['imageUrl']?.toString().isNotEmpty == true ? episode['imageUrl'].toString() : (podcast['artworkUrl']?.toString() ?? ''),
      mediaUrl: episode['audioUrl']?.toString() ?? '',
      mediaKind: 'audio',
      creatorId: '', channelId: '',
      country: podcast['country']?.toString() ?? '',
      language: podcast['language']?.toString() ?? '',
      artistName: podcast['artist']?.toString() ?? '',
    );
  }
  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Podcasts'),
        actions: [
          IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Podcast'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المحتوى: ${snapshot.error}'));
          }

          final q = _query.trim().toLowerCase();
          final filteredCatalog = aurenPodcastCatalog.where((item) {
            final categoryMatch =
                _category == 'الكل' || item.category == _category;
            final text =
                '${item.name} ${item.host} ${item.category} ${item.description}'
                    .toLowerCase();
            return categoryMatch && (q.isEmpty || text.contains(q));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              _buildHero(context),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ابحث عن بودكاست، مؤثر، رائد أعمال أو موضوع...',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _discovering ? null : _discoverPodcasts,
                icon: _discovering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore),
                label: Text(_discovering ? 'جاري الاكتشاف...' : 'اكتشف بودكاست عالمي'),
              ),
              const SizedBox(height: 10),
              if (_remoteResults.isNotEmpty) ...[
                const Text(
                  'نتائج حية من دليل البودكاست',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ..._remoteResults.take(12).map((item) => Card(
                  child: ListTile(
                    leading: item['artworkUrl']?.toString().isNotEmpty == true
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(item['artworkUrl'].toString()),
                          )
                        : const CircleAvatar(child: Icon(Icons.podcasts)),
                    title: Text(item['name']?.toString() ?? 'Podcast'),
                    subtitle: Text(
                      (item['artist']?.toString() ?? '') + ' • ' + (item['genre']?.toString() ?? ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _loadingFeed == item['feedUrl']
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.library_music_outlined),
                    onTap: () => _loadEpisodes(item),
                  ),
                )),
                ...(_episodes[item['id']?.toString()] ?? const <Map<String, dynamic>>[]).map((episode) => Card(
                  margin: const EdgeInsetsDirectional.only(start: 22, top: 4),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(episode['title']?.toString() ?? 'Episode', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(episode['publishedAt']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: _analyzingEpisode == '${item['id']}_${episode['id']}'
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            tooltip: 'AI Summary',
                            icon: const Icon(Icons.auto_awesome_outlined),
                            onPressed: () => _analyzeEpisode(item, episode),
                          ),
                    onTap: episode['audioUrl']?.toString().isEmpty != false
                        ? null
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => episode['isVideo'] == true
                            ? AurenPodcastVideoPlayerScreen(
                                title: episode['title']?.toString() ?? 'Video Podcast',
                                videoUrl: episode['audioUrl']?.toString() ?? '',
                                description: episode['description']?.toString() ?? '',
                                imageUrl: episode['imageUrl']?.toString() ?? item['artworkUrl']?.toString() ?? '',
                              )
                            : AurenAudioPlayerScreen(item: _episodeItem(item, episode)))),
                  ),
                )),
                const SizedBox(height: 14),
              ],
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = _categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) =>
                          setState(() => _category = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (items.isNotEmpty) ...[
                const Text(
                  'حلقات موجودة في AUREN',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(
                              child: Icon(Icons.podcasts),
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(item.imageUrl),
                            ),
                      title: Text(item.title),
                      subtitle: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: uid == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () => repo.save(uid, item.id),
                            ),
                      onTap: item.mediaUrl.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AurenAudioPlayerScreen(item: item),
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Text(
                'بودكاست عالمي مقترح',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'كتالوج اكتشاف للأسماء والبرامج المتداولة. عند ربط مصدر رسمي، يستطيع AUREN جلب الحلقات وتشغيلها بدل تخزين روابط غير مرخصة.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (filteredCatalog.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد نتائج مطابقة.'),
                  ),
                )
              else
                ...filteredCatalog.map(_catalogCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listen. Learn. Build.',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 7),
          Text(
            'حياة • أعمال • مؤثرون • مؤسسون • أفكار • قصص',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _catalogCard(AurenPodcastCatalogItem item) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.mic_external_on_rounded),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.host} • ${item.category}\n${item.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
