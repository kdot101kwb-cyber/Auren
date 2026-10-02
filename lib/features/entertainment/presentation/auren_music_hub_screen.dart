import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'auren_audio_player_screen.dart';
import 'auren_mini_player.dart';
import 'auren_podcasts_screen.dart';
import 'auren_radio_screen.dart';
import 'auren_music_queue_screen.dart';
import 'auren_smart_music_screen.dart';
import 'auren_saved_music_screen.dart';import 'auren_music_collection_screen.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';

class AurenMusicHubScreen extends StatefulWidget {
  const AurenMusicHubScreen({super.key});
  @override State<AurenMusicHubScreen> createState() => _AurenMusicHubState();
}

class _AurenMusicHubState extends State<AurenMusicHubScreen> {
  String _query = '';
  String _genre = 'الكل';
  static const _genres = ['الكل', 'Pop', 'Hip Hop', 'Afrobeat', 'R&B', 'Rock', 'Classical', 'Chill'];

  void _ai(BuildContext context, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded),
            tooltip: 'Saved Music',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSavedMusicScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Music AI',
            onPressed: () => _ai(
              context,
              'ساعدني كـ AUREN Music AI. اختر لي موسيقى مناسبة لمزاجي ووقتي، أو ساعدني في إنشاء فكرة أغنية أصلية بدون تقليد صوت فنان حقيقي.',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Music'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          final filtered = items.where((item) {
            final haystack = (item.title + ' ' + item.description + ' ' + item.artistName + ' ' + item.albumName + ' ' + item.genres.join(' ')).toLowerCase();
            final searchOk = _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
            final genreOk = _genre == 'الكل' || item.genres.any((g) => g.toLowerCase() == _genre.toLowerCase()) || haystack.contains(_genre.toLowerCase());
            return searchOk && genreOk;
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _hero(context),
              const SizedBox(height: 18),
              _sectionTitle('استمع بطريقتك'),
              _actions(context),
              const SizedBox(height: 20),
              TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن أغنية، فنان أو ألبوم'), onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 10),
              SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _genres.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(_genres[i]), selected: _genre == _genres[i], onSelected: (_) => setState(() => _genre = _genres[i])))),
              const SizedBox(height: 12),
              _intelligentHome(context, filtered, repo, uid),

              if (items.isNotEmpty) ...[
                const SizedBox(height: 14),
                _artistAlbumSection(context, filtered),
              ],
              _sectionTitle('Music & Podcasts'),

            ],
          );
        },
          ),
          const AurenMiniPlayer(),
        ],
      ),
    );
  }


  List<AurenEntertainmentItem> _rankForYou(List<AurenEntertainmentItem> items, Map<String, Map<String, dynamic>> signals) {
    final history = AurenMusicPlayerController.instance.history.map((x) => x.id).toSet();
    double score(AurenEntertainmentItem item) {
      final data = signals[item.id];
      if (data == null) return history.contains(item.id) ? 1.0 : 7.0;
      final seconds = (data['watchSeconds'] as num?)?.toDouble() ?? 0;
      final plays = (data['plays'] as num?)?.toDouble() ?? 0;
      final likes = (data['likes'] as num?)?.toDouble() ?? 0;
      final saves = (data['saves'] as num?)?.toDouble() ?? 0;
      final completions = (data['completions'] as num?)?.toDouble() ?? 0;
      final skips = (data['skips'] as num?)?.toDouble() ?? 0;
      var value = seconds * .02 + plays * .5 + likes * 5 + saves * 3 + completions * 2 - skips * 2;
      if (!history.contains(item.id)) value += 2.5;
      final hour = DateTime.now().hour;
      final contextText = item.title + ' ' + item.description.toLowerCase();
      final hints = hour < 12
          ? const ['morning', 'صباح', 'focus', 'تركيز']
          : hour < 18
              ? const ['work', 'عمل', 'study', 'دراسة', 'focus', 'تركيز']
              : hour < 23
                  ? const ['evening', 'مساء', 'chill', 'هادئ']
                  : const ['night', 'ليل', 'sleep', 'نوم', 'هادئ'];
      if (hints.any(contextText.contains)) value += 2;
      return value;
    }
    return [...items]..sort((a, b) => score(b).compareTo(score(a)));
  }

  List<AurenEntertainmentItem> _discover(List<AurenEntertainmentItem> items, Map<String, Map<String, dynamic>> signals) {
    final history = AurenMusicPlayerController.instance.history.map((x) => x.id).toSet();
    return [...items]
      ..removeWhere((item) => history.contains(item.id))
      ..sort((a, b) => (signals[b.id] == null ? 1 : 0).compareTo(signals[a.id] == null ? 1 : 0));
  }

  Widget _intelligentHome(BuildContext context, List<AurenEntertainmentItem> items, EntertainmentRepository repo, String? uid) {
    final future = uid == null ? Future.value(const <String, Map<String, dynamic>>{}) : repo.getMusicSignals(uid);
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final signals = snapshot.data ?? const <String, Map<String, dynamic>>{};
        final forYou = _rankForYou(items, signals).take(12).toList();
        final discover = _discover(items, signals).take(12).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _continueListening(context),
            _recentlyPlayed(context),
            if (items.isNotEmpty) ...[
              _sectionTitle('For You'),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  signals.isEmpty
                      ? 'AUREN يبدأ من ذوقك الحالي ويكتشف لك الجديد.'
                      : 'اختيارات تتعلم من استماعك وحفظك وإعجابك ووقت استخدامك.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              ...forYou.map((item) => _musicTile(context, item, repo, uid)),
              const SizedBox(height: 12),
              _sectionTitle('اكتشف جديد'),
              ...discover.map((item) => _musicTile(context, item, repo, uid)),
            ],
          ],
        );
      },
    );
  }

  Widget _continueListening(BuildContext context) => AnimatedBuilder(
        animation: AurenMusicPlayerController.instance,
        builder: (context, _) {
          final controller = AurenMusicPlayerController.instance;
          final item = controller.item;
          if (item == null || item.mediaUrl.isEmpty) return const SizedBox.shrink();
          final duration = controller.duration;
          final progress = duration.inMilliseconds > 0
              ? (controller.position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded, size: 34),
              title: const Text('Continue Listening'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                ],
              ),
              trailing: Text((progress * 100).round().toString() + '%'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAudioPlayerScreen())),
            ),
          );
        },
      );

  Widget _recentlyPlayed(BuildContext context) => AnimatedBuilder(
        animation: AurenMusicPlayerController.instance,
        builder: (context, _) {
          final history = AurenMusicPlayerController.instance.history.take(8).toList();
          if (history.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Recently Played'),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => SizedBox(
                    width: 190,
                    child: Card(
                      child: ListTile(
                        dense: true,
                        leading: history[index].imageUrl.isEmpty
                            ? const CircleAvatar(child: Icon(Icons.music_note))
                            : CircleAvatar(
                                child: ClipOval(
                                  child: Image.network(
                                    history[index].imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                                  ),
                                ),
                              ),
                        title: Text(history[index].title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => AurenMusicPlayerController.instance.playItem(history[index]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          );
        },
      );

  Widget _artistAlbumSection(BuildContext context, List<AurenEntertainmentItem> items) {
    final artists = <String, List<AurenEntertainmentItem>>{};
    final albums = <String, List<AurenEntertainmentItem>>{};
    for (final item in items) {
      if (item.artistName.trim().isNotEmpty) artists.putIfAbsent(item.artistName.trim(), () => []).add(item);
      if (item.albumName.trim().isNotEmpty) albums.putIfAbsent(item.albumName.trim(), () => []).add(item);
    }
    if (artists.isEmpty && albums.isEmpty) return const SizedBox.shrink();
    final entries = <Widget>[];
    if (artists.isNotEmpty) {
      entries.add(_sectionTitle('الفنانون'));
      entries.add(SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: artists.length.clamp(0, 8),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final name = artists.keys.elementAt(i);
            return SizedBox(width: 150, child: Card(
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  AurenMusicCollectionScreen(title: name, subtitle: artists[name]!.length.toString() + ' أغنية', items: artists[name]!))),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const Icon(Icons.person_rounded, size: 30), const SizedBox(height: 6),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)],
                )),
              ),
            ));
          },
        ),
      ));
    }
    if (albums.isNotEmpty) {
      entries.add(const SizedBox(height: 14));
      entries.add(_sectionTitle('الألبومات'));
      entries.add(SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: albums.length.clamp(0, 8),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final name = albums.keys.elementAt(i);
            final albumItems = albums[name]!;
            return SizedBox(width: 170, child: Card(
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  AurenMusicCollectionScreen(title: name, subtitle: albumItems.first.artistName, items: albumItems, album: true))),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const Icon(Icons.album_rounded, size: 30), const SizedBox(height: 6),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)],
                )),
              ),
            ));
          },
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: entries);
  }

  Widget _musicTile(BuildContext context, AurenEntertainmentItem item, EntertainmentRepository repo, String? uid) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: item.imageUrl.isEmpty
              ? const CircleAvatar(child: Icon(Icons.music_note))
              : CircleAvatar(
                  child: ClipOval(
                    child: Image.network(
                      item.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                    ),
                  ),
                ),
          title: Text(item.title),
          subtitle: Text(item.description.isEmpty ? item.type : item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: item.mediaUrl.isEmpty
              ? null
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'إضافة إلى Queue',
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: item.mediaUrl.isEmpty ? null : () => AurenMusicPlayerController.instance.addToQueue(item),
              ),
              if (uid != null)
                IconButton(
                  tooltip: 'حفظ',
                  icon: const Icon(Icons.bookmark_border_rounded),
                  onPressed: () async {
                    await repo.save(uid, item.id);
                    await repo.trackMusicAction(uid, item.id, action: 'save', contentType: item.type);
                  },
                ),
            ],
          ),
        ),
      );

  Widget _hero(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.music_note_rounded, size: 42),
            SizedBox(height: 8),
            Text('Listen. Create. Discover.',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Music • Radio • Podcasts • Original AI'),
          ],
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _actions(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _action(context, Icons.auto_awesome, 'AI Music',
              'Smart Music',
              'ساعدني في إنشاء أغنية أصلية: فكرة، كلمات، بنية وموسيقى مناسبة، بدون تقليد صوت فنان حقيقي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSmartMusicScreen()))),
          _action(context, Icons.radio, 'Radio', 'محطات واكتشاف',
              'اقترح لي تجربة Radio مناسبة لذوقي ووقتي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRadioScreen()))),
          _action(context, Icons.podcasts, 'Podcasts', 'بودكاست ذكي',
              'اقترح لي بودكاست مناسباً لموضوعي ووقتي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenPodcastsScreen()))),
          _action(context, Icons.playlist_play, 'Playlist',
              'Queue + History',
              'أنشئ لي Playlist ذكية حسب مزاجي ووقتي ونشاطي.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMusicQueueScreen()))),
        ],
      );

  Widget _action(BuildContext context, IconData icon, String title,
      String subtitle, String prompt, {VoidCallback? onTap}) {
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
          onTap: onTap ?? () => _ai(context, prompt),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
