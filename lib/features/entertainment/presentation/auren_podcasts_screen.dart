import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../data/auren_podcast_catalog.dart';
import 'auren_audio_player_screen.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_podcast_video_player_screen.dart';
import '../../../services/entertainment/auren_offline_audio_cache.dart';

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
  List<Map<String, dynamic>> _recommendations = const [];
  List<Map<String, dynamic>> _personalized = const [];
  List<Map<String, dynamic>> _becauseYouListened = const [];
  List<Map<String, dynamic>> _trending = const [];
  List<Map<String, dynamic>> _newForYou = const [];
  bool _loadingPersonalized = false;
  final AurenMusicPlayerController _player = AurenMusicPlayerController.instance;
  Map<String, List<Map<String, dynamic>>> _episodes = {};
  String? _loadingFeed;
  String? _analyzingEpisode;
  final Map<String, Map<String, dynamic>> _episodeAnalysis = {};
  final Set<String> _likedEpisodes = <String>{};
  final Set<String> _savedEpisodes = <String>{};
  List<Map<String, dynamic>> _savedEpisodeItems = const [];
  final Set<String> _offlineEpisodes = <String>{};
  final Set<String> _offlineBusy = <String>{};
  int _offlineStorageBytes = 0;
  bool _loadingOfflineStorage = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedFeed();
    _loadLikedEpisodes();
    _loadOfflineStorage();
    _syncOfflineFlags();
    _loadSavedEpisodes();
  }

  Future<void> _loadSavedEpisodes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final repo = EntertainmentRepository();
      final saved = await repo.getSavedPodcastEpisodes(uid);
      if (!mounted) return;
      setState(() {
        _savedEpisodeItems = saved;
        _savedEpisodes
          ..clear()
          ..addAll(saved.map((e) => e['episodeId']?.toString() ?? e['id']?.toString() ?? '').where((e) => e.isNotEmpty));
        _offlineEpisodes
          ..clear()
          ..addAll(saved.where((e) => e['offline'] == true).map((e) => e['episodeId']?.toString() ?? e['id']?.toString() ?? '').where((e) => e.isNotEmpty));
      });
    } catch (_) {}
  }

  Future<void> _loadLikedEpisodes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final liked = await EntertainmentRepository().getLikedPodcastEpisodeIds(uid);
      if (mounted) setState(() => _likedEpisodes.addAll(liked));
    } catch (_) {}
  }

  Future<void> _recordPodcastEvent(String event, Map<String, dynamic> item) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('recordAurenPodcastEvent');
      await callable.call({'event': event, 'item': item});
    } catch (_) {}
  }

  Future<void> _loadPersonalizedFeed() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    setState(() => _loadingPersonalized = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getAurenPodcastPersonalizedFeed');
      final response = await callable.call({'limit': 12});
      final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
      List<Map<String, dynamic>> list(dynamic value) => value is List
          ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _personalized = list(data['forYou']);
          _becauseYouListened = list(data['becauseYouListened']);
          _trending = list(data['trending']);
          _newForYou = list(data['newForYou']);
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _personalized = const [];
        _becauseYouListened = const [];
        _trending = const [];
        _newForYou = const [];
      });
    } finally {
      if (mounted) setState(() => _loadingPersonalized = false);
    }
  }

  Widget _buildContinueListening() {
    final item = _player.item;
    if (item == null || item.mediaUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _player,
      builder: (context, _) {
        final duration = _player.duration;
        final position = _player.position;
        if (position <= const Duration(seconds: 10) ||
            (duration > Duration.zero && position >= duration * 0.95)) {
          return const SizedBox.shrink();
        }
        final total = duration.inMilliseconds;
        final progress = total <= 0
            ? 0.0
            : position.inMilliseconds.clamp(0, total).toDouble() / total;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  item.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(item.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
                        )
                      : const SizedBox(width: 64, height: 64, child: Icon(Icons.podcasts, size: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تابع الاستماع', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        if (duration > Duration.zero) LinearProgressIndicator(value: progress),
                        if (duration > Duration.zero) const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'استمرار',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 36),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRecentlyPlayed() {
    final items = _player.history
        .where((item) => item.type.toLowerCase() == 'podcast')
        .take(10)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('استمعت إليها مؤخراً', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final item = items[index];
              return SizedBox(
                width: 220,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          item.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(item.imageUrl, width: 52, height: 52, fit: BoxFit.cover),
                                )
                              : const SizedBox(width: 52, height: 52, child: Icon(Icons.podcasts)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSavedRail(List<AurenEntertainmentItem> items) {
    final podcasts = items.where((item) => item.type.toLowerCase() == 'podcast').take(10).toList();
    if (podcasts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('بودكاست محفوظ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: podcasts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final item = podcasts[index];
              return SizedBox(
                width: 220,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.bookmark),
                    title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: item.mediaUrl.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Future<void> _cleanupOfflineStorage() async {
    try {
      await AurenOfflineAudioCache.cleanupInvalid();
      await _loadOfflineStorage();
    } catch (_) {}
  }

  Future<void> _clearOfflineStorage() async {
    try {
      await AurenOfflineAudioCache.clearAll();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final saved = await EntertainmentRepository().getSavedPodcastEpisodes(uid);
        for (final item in saved) {
          final id = item['episodeId']?.toString() ?? item['id']?.toString() ?? '';
          if (id.isNotEmpty && item['offline'] == true) {
            await EntertainmentRepository().setPodcastEpisodeOffline(uid, id, false);
          }
        }
      }
      if (mounted) {
        setState(() => _offlineEpisodes.clear());
        await _loadOfflineStorage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف كل النسخ المحفوظة دون اتصال.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadOfflineStorage() async {
    if (mounted) setState(() => _loadingOfflineStorage = true);
    try {
      final bytes = await AurenOfflineAudioCache.totalBytes();
      if (mounted) setState(() => _offlineStorageBytes = bytes);
    } finally {
      if (mounted) setState(() => _loadingOfflineStorage = false);
    }
  }

  String _formatOfflineSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _syncOfflineFlags() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final saved = await EntertainmentRepository().getSavedPodcastEpisodes(uid);
      for (final item in saved) {
        final id = item['episodeId']?.toString() ?? item['id']?.toString() ?? '';
        if (id.isEmpty || item['offline'] != true) continue;
        if (!await AurenOfflineAudioCache.exists(id)) {
          await EntertainmentRepository().setPodcastEpisodeOffline(uid, id, false);
          _offlineEpisodes.remove(id);
        }
      }
      if (mounted) setState(() {});
      await _loadOfflineStorage();
    } catch (_) {}
  }

  Future<void> _toggleOfflineEpisode(Map<String, dynamic> episode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '';
    final url = episode['audioUrl']?.toString() ?? '';
    if (uid == null || id.isEmpty || url.isEmpty) return;
    final currentlyOffline = _offlineEpisodes.contains(id);
    setState(() => _offlineBusy.add(id));
    try {
      if (currentlyOffline) {
        await AurenOfflineAudioCache.delete(id);
        await EntertainmentRepository().setPodcastEpisodeOffline(uid, id, false);
        if (mounted) setState(() => _offlineEpisodes.remove(id));
        await _loadOfflineStorage();
      } else {
        final localPath = await AurenOfflineAudioCache.download(id, url);
        if (localPath == null || localPath.isEmpty || !await File(localPath).exists()) {
          await EntertainmentRepository().setPodcastEpisodeOffline(uid, id, false);
          throw Exception('offline download failed');
        }
        await EntertainmentRepository().setPodcastEpisodeOffline(uid, id, true);
        if (mounted) setState(() => _offlineEpisodes.add(id));
        await _loadOfflineStorage();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تجهيز الحلقة للاستخدام دون اتصال.')),
        );
      }
    } finally {
      if (mounted) setState(() => _offlineBusy.remove(id));
    }
  }

  Future<void> _openSavedEpisode(Map<String, dynamic> saved) async {
    final savedId = saved['episodeId']?.toString() ?? saved['id']?.toString() ?? '';
    var audioUrl = saved['audioUrl']?.toString() ?? '';
    var title = saved['title']?.toString() ?? 'Episode';
    var description = saved['description']?.toString() ?? '';
    var artwork = saved['artworkUrl']?.toString() ?? '';
    var language = saved['language']?.toString() ?? '';
    var country = saved['country']?.toString() ?? '';
    var podcastName = saved['podcastName']?.toString() ?? '';
    if (saved['offline'] == true) {
      final local = await AurenOfflineAudioCache.cachedPath(savedId);
      if (local != null && await File(local).exists()) {
        audioUrl = Uri.file(local).toString();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('النسخة المحلية غير متوفرة. اضغط تنزيل مرة أخرى لإتاحتها دون اتصال.')),
          );
        }
        return;
      }
    }
    if (audioUrl.isEmpty && (saved['feedUrl']?.toString() ?? '').isNotEmpty) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('fetchAurenPodcastFeed');
        final response = await callable.call({'feedUrl': saved['feedUrl']});
        final raw = response.data is Map ? response.data['episodes'] : null;
        final episodes = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
        final suffix = savedId.split('_').last;
        final match = episodes.where((e) =>
          e['id']?.toString() == suffix ||
          e['title']?.toString() == title).cast<Map<String, dynamic>?>().firstWhere((e) => e != null, orElse: () => null);
        if (match != null) {
          audioUrl = match['audioUrl']?.toString() ?? '';
          title = match['title']?.toString() ?? title;
          description = match['description']?.toString() ?? description;
          artwork = match['imageUrl']?.toString() ?? artwork;
        }
      } catch (_) {}
    }
    if (audioUrl.isEmpty || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر استعادة رابط تشغيل هذه الحلقة. افتح البرنامج من جديد لتحميل الحلقة.')));
      }
      return;
    }
    final item = AurenEntertainmentItem(
      id: savedId,
      title: title,
      type: 'Podcast',
      description: description,
      imageUrl: artwork,
      mediaUrl: audioUrl,
      mediaKind: 'audio',
      creatorId: '',
      channelId: '',
      country: country,
      language: language,
      artistName: podcastName,
    );
    await _recordPodcastEvent('play', {
      'id': savedId,
      'name': title,
      'description': description,
      'artworkUrl': artwork,
      'language': language,
      'country': country,
      'artist': podcastName,
    });
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)));
  }

  Widget _buildSavedEpisodesRail() {
    final storageLabel = _loadingOfflineStorage ? '...' : _formatOfflineSize(_offlineStorageBytes);
    final episodes = _savedEpisodeItems.take(20).toList();
    if (episodes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('حلقاتي المحفوظة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Offline: $storageLabel', style: Theme.of(context).textTheme.bodySmall),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'cleanup') {
                    await _cleanupOfflineStorage();
                    return;
                  }
                  if (value == 'clear' && mounted) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('حذف كل النسخ Offline؟'),
                        content: const Text('سيتم حذف الملفات المحلية فقط، ويمكن تنزيل الحلقات مرة أخرى لاحقاً.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('حذف الكل'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await _clearOfflineStorage();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cleanup', child: Text('تنظيف الملفات التالفة')),
                  PopupMenuItem(value: 'clear', child: Text('حذف كل النسخ Offline')),
                ],
              ),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final episode = episodes[index];
              final audioUrl = episode['audioUrl']?.toString() ?? '';
              final title = episode['title']?.toString() ?? 'Episode';
              final artwork = episode['artworkUrl']?.toString() ?? '';
              return SizedBox(
                width: 240,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: artwork.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(artwork, width: 52, height: 52, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.bookmark),
                    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      episode['podcastName']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: _offlineEpisodes.contains(episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '')
                          ? 'إزالة النسخة دون اتصال'
                          : 'حفظ دون اتصال',
                      onPressed: _offlineBusy.contains(episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '')
                          ? null
                          : () => _toggleOfflineEpisode(episode),
                      icon: _offlineBusy.contains(episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '')
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_offlineEpisodes.contains(episode['episodeId']?.toString() ?? episode['id']?.toString() ?? '')
                              ? Icons.download_done_rounded
                              : Icons.download_for_offline_outlined),
                    ),
                    onTap: () => _openSavedEpisode(episode),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildPodcastRail(String title, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final item = items[index];
              return SizedBox(
                width: 220,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _recordPodcastEvent('open', item);
                      _loadEpisodes(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            item['artworkUrl']?.toString().isNotEmpty == true
                                ? CircleAvatar(backgroundImage: NetworkImage(item['artworkUrl'].toString()))
                                : const CircleAvatar(child: Icon(Icons.podcasts)),
                            const SizedBox(width: 9),
                            Expanded(child: Text(item['name']?.toString() ?? 'Podcast', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                          ]),
                          const Spacer(),
                          Text(item['genre']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (item['matchedInterests'] is List && (item['matchedInterests'] as List).isNotEmpty)
                            Text((item['matchedInterests'] as List).take(2).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  List<String> get _categories => [
        'الكل',
        ...aurenPodcastCatalog.map((e) => e.category).toSet(),
      ];

  Future<void> _discoverPodcasts() async {
    final query = _query.trim();
    if (query.isEmpty) return;
    setState(() => _discovering = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('searchAurenPodcastsSmart');
      final response = await callable.call({
        'query': query,
        'countries': ['US', 'GB', 'CA', 'AU', 'AE', 'EG', 'SA', 'TR'],
      });
      final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
      final raw = data['results'];
      final recs = data['recommendations'];
      final results = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final recommendations = recs is List
          ? recs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _remoteResults = results;
          _recommendations = recommendations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تشغيل البحث الذكي: ' + e.toString())),
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
        ? value.map((e) => '• ${e.toString()}').join('\\n')
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
              if (_loadingPersonalized)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              _buildContinueListening(),
              const SizedBox(height: 8),
              _buildRecentlyPlayed(),
              _buildSavedEpisodesRail(),
              if (uid != null)
                StreamBuilder<List<AurenEntertainmentItem>>(
                  stream: repo.watchSavedItems(uid),
                  builder: (context, savedSnapshot) =>
                      _buildSavedRail(savedSnapshot.data ?? const <AurenEntertainmentItem>[]),
                ),
              _buildPodcastRail('For You — AUREN', _personalized),
              _buildPodcastRail('لأنك استمعت إلى', _becauseYouListened),
              _buildPodcastRail('الأكثر رواجاً عالمياً', _trending),
              _buildPodcastRail('جديد ومناسب لك', _newForYou),
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
              Text('نتائج البحث: ${_remoteResults.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
              if (_recommendations.isNotEmpty) ...[
                const Text(
                  'اقتراحات AUREN لك',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 178,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendations.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final item = _recommendations[index];
                      return SizedBox(
                        width: 230,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              _recordPodcastEvent('open', item);
                              _loadEpisodes(item);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      item['artworkUrl']?.toString().isNotEmpty == true
                                          ? CircleAvatar(backgroundImage: NetworkImage(item['artworkUrl'].toString()))
                                          : const CircleAvatar(child: Icon(Icons.podcasts)),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(item['name']?.toString() ?? 'Podcast',
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item['genre']?.toString() ?? '',
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  Text(
                                    (item['matchedInterests'] is List && (item['matchedInterests'] as List).isNotEmpty)
                                        ? 'متوافق مع اهتماماتك'
                                        : 'مقترح من بحثك',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
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
                    onTap: () {
                      _recordPodcastEvent('open', item);
                      _loadEpisodes(item);
                    },
                  ),
                )),
                ...(_episodes[item['id']?.toString()] ?? const <Map<String, dynamic>>[]).map((episode) => Card(
                  margin: const EdgeInsetsDirectional.only(start: 22, top: 4),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(episode['title']?.toString() ?? 'Episode', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(episode['publishedAt']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        Builder(
                          builder: (context) {
                            final episodeItem = _episodeItem(item, episode);
                            final liked = _likedEpisodes.contains(episodeItem.id);
                            return IconButton(
                              tooltip: liked ? 'تم الإعجاب' : 'إعجاب',
                              icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                              onPressed: () async {
                                if (liked) return;
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) return;
                                try {
                                  await EntertainmentRepository().togglePodcastLike(uid, episodeItem.id, true, title: episodeItem.title, podcastId: item['id']?.toString());
                                  if (!mounted) return;
                                  setState(() => _likedEpisodes.add(episodeItem.id));
                                  await _recordPodcastEvent('like', {
                                  ...item,
                                  'id': episodeItem.id,
                                  'name': episodeItem.title,
                                  'description': episodeItem.description,
                                  'artworkUrl': episodeItem.imageUrl,
                                  'language': episodeItem.language,
                                  'country': episodeItem.country,
                                  });
                                } catch (_) {}
                              },
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final episodeItem = _episodeItem(item, episode);
                            final saved = _savedEpisodes.contains(episodeItem.id);
                            return IconButton(
                              tooltip: saved ? 'تم الحفظ' : 'حفظ',
                              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                              onPressed: () async {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) return;
                                try {
                                  final next = !saved;
                                  await EntertainmentRepository().togglePodcastEpisodeSave(
                                    uid,
                                    episodeItem.id,
                                    next,
                                    title: episodeItem.title,
                                    podcastId: item['id']?.toString(),
                                    podcastName: item['name']?.toString() ?? item['artist']?.toString(),
                                    feedUrl: item['feedUrl']?.toString(),
                                    description: episodeItem.description,
                                    artworkUrl: episodeItem.imageUrl,
                                    audioUrl: episodeItem.mediaUrl,
                                    publishedAt: episode['publishedAt']?.toString(),
                                    language: episodeItem.language,
                                    country: episodeItem.country,
                                    isVideo: episode['isVideo'] == true,
                                  );
                                  if (!next) {
                                    await AurenOfflineAudioCache.delete(episodeItem.id);
                                  }
                                  if (!mounted) return;
                                  setState(() {
                                    if (next) {
                                      _savedEpisodes.add(episodeItem.id);
                                      _savedEpisodeItems = [
                                        {
                                          'id': episodeItem.id,
                                          'episodeId': episodeItem.id,
                                          'title': episodeItem.title,
                                          'podcastId': item['id']?.toString() ?? '',
                                          'podcastName': item['name']?.toString() ?? item['artist']?.toString() ?? '',
                                          'feedUrl': item['feedUrl']?.toString() ?? '',
                                          'description': episodeItem.description,
                                          'artworkUrl': episodeItem.imageUrl,
                                          'audioUrl': episodeItem.mediaUrl,
                                          'publishedAt': episode['publishedAt']?.toString() ?? '',
                                          'language': episodeItem.language,
                                          'country': episodeItem.country,
                                          'isVideo': episode['isVideo'] == true,
                                        },
                                        ..._savedEpisodeItems.where((e) =>
                                            (e['episodeId']?.toString() ?? e['id']?.toString() ?? '') != episodeItem.id),
                                      ].take(50).toList();
                                    } else {
                                      _savedEpisodes.remove(episodeItem.id);
                                      _savedEpisodeItems = _savedEpisodeItems.where((e) =>
                                          (e['episodeId']?.toString() ?? e['id']?.toString() ?? '') != episodeItem.id).toList();
                                    }
                                  });
                                  await _recordPodcastEvent(next ? 'save' : 'unsave', {
                                    ...item,
                                    'id': episodeItem.id,
                                    'name': episodeItem.title,
                                    'description': episodeItem.description,
                                    'artworkUrl': episodeItem.imageUrl,
                                    'language': episodeItem.language,
                                    'country': episodeItem.country,
                                  });
                                } catch (_) {}
                              },
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'مشاركة',
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () async {
                            final title = episode['title']?.toString() ?? 'Podcast episode';
                            final url = episode['link']?.toString() ?? '';
                            await Share.share(url.isEmpty ? title : title + '\n' + url)
                            await _recordPodcastEvent('share', {
                              ...item,
                              'id': _episodeItem(item, episode).id,
                              'name': title,
                            });
                          },
                        ),
                        if (_analyzingEpisode == '${item['id']}_${episode['id']}')
                          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          IconButton(
                            tooltip: 'AI Summary',
                            icon: const Icon(Icons.auto_awesome_outlined),
                            onPressed: () => _analyzeEpisode(item, episode),
                          ),
                      ],
                    ),
                    onTap: episode['audioUrl']?.toString().isEmpty != false
                        ? null
                        : () {
                            _recordPodcastEvent('play', {'id': episodeItem.id, 'name': episodeItem.title});
                            Navigator.push(context, MaterialPageRoute(builder: (_) => episode['isVideo'] == true
                            ? AurenPodcastVideoPlayerScreen(
                                title: episode['title']?.toString() ?? 'Video Podcast',
                                videoUrl: episode['audioUrl']?.toString() ?? '',
                                description: episode['description']?.toString() ?? '',
                                imageUrl: episode['imageUrl']?.toString() ?? episodeItem.imageUrl,
                              )
                            : AurenAudioPlayerScreen(item: episodeItem))),
                            );
                          },
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
                              onPressed: () async {
                                await repo.save(uid, item.id);
                                _recordPodcastEvent('save', {
                                  'id': item.id,
                                  'name': item.title,
                                  'description': item.description,
                                  'artworkUrl': item.imageUrl,
                                  'genre': item.type,
                                  'language': item.language,
                                  'country': item.country,
                                });
                              },
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
