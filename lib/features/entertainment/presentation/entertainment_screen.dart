import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:flutter/material.dart';

import '../../search/presentation/global_search_screen.dart';
import 'entertainment_detail_screen.dart';
import 'entertainment_shorts_screen.dart';
import 'auren_music_hub_screen.dart';
import 'auren_movies_hub_screen.dart';
import 'auren_watch_concierge_screen.dart';
import 'continue_watching_screen.dart';
import 'watch_history_screen.dart';
import 'watch_together_screen.dart';
import 'auren_gaming_screen.dart';
import 'auren_radio_screen.dart';
import 'auren_entertainment_create_screen.dart';
import 'auren_ai_series_studio_screen.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../core/models/entertainment.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEntertainmentScreen extends StatefulWidget {
  const AurenAURENEntertainmentScreen({super.key});

  @override
  State<AurenAURENEntertainmentScreen> createState() =>
      _EntertainmentState();
}

class _EntertainmentState extends State<AurenAURENEntertainmentScreen> {
  final repo = EntertainmentRepository();
  String query = '';
  String? type;
  String _mood = 'الكل';

  static const _quickActions = <_EntertainmentAction>[
    _EntertainmentAction(Icons.movie_filter_rounded, 'Movies', 'Global movies with smart discovery'),
    _EntertainmentAction(Icons.groups_rounded, 'Watch Together', 'Watch with friends in one room'),
    _EntertainmentAction(Icons.music_note_rounded, 'Music', 'Songs, playlists & AI music'),
    _EntertainmentAction(Icons.live_tv_rounded, 'Live', 'Channels, live events & radio'),
    _EntertainmentAction(Icons.sports_esports_rounded, 'Gaming', 'Games, challenges & social play'),
    _EntertainmentAction(Icons.auto_awesome_rounded, 'Create', 'Create music, stories & shows'),
    _EntertainmentAction(Icons.tv_rounded, 'AI Series', 'Build an original season with AI'),
    _EntertainmentAction(Icons.public_rounded, 'AUREN World', 'Explore interactive worlds'),
    _EntertainmentAction(Icons.download_rounded, 'Offline', 'Save entertainment for low-data use'),
  ];

  void _setMood(String mood, String prompt) => setState(() { _mood = mood; query = prompt; });

  void _openAI() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MessengerScreen(
          initialPrompt:
              'أنت AUREN Entertainment AI. ساعدني في اختيار أو إنشاء تجربة ترفيهية مناسبة لوقتي ومزاجي وبيانات الإنترنت. اقترح مشاهدة أو موسيقى أو لعبة أو تجربة داخل AUREN World، واسأل فقط عند الحاجة.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Entertainment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library_outlined),
            tooltip: 'Shorts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AurenEntertainmentShortsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AurenGlobalSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Entertainment AI',
            onPressed: _openAI,
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: type),
        builder: (context, s) {
          if (s.hasError) {
            return Center(child: Text('تعذر تحميل المحتوى: ${s.error}'));
          }
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = s.data ?? const <AurenEntertainmentItem>[];

          return StreamBuilder<Set<String>>(
            stream: uid == null
                ? const Stream<Set<String>>.empty()
                : repo.watchSavedIds(uid),
            builder: (context, ss) {
              final saved = ss.data ?? <String>{};
              final q = query.toLowerCase();

              final filtered = items.where((i) {
                final haystack =
                    '${i.title} ${i.description} ${i.type}'.toLowerCase();
                return q.isEmpty || haystack.contains(q);
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (uid != null) ...[
                    AurenAdaptiveProfileSurface(
                      uid: uid,
                      context: AurenProfileContext.content,
                      intent: query.isEmpty ? 'الترفيه والمحتوى الذي أريده الآن' : query,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    AurenAdaptiveActionRail(
                      uid: uid,
                      context: AurenProfileContext.content,
                      intent: query.isEmpty ? 'اختيار تجربة ترفيهية مناسبة' : query,
                      onPrompt: (prompt) => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildHero(context),
                  if (uid != null) ...[
                    const SizedBox(height: 14),
                    _buildContinueWatching(context, uid),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AurenWatchHistoryScreen()),
                        ),
                        icon: const Icon(Icons.history),
                        label: const Text('سجل المشاهدة'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildMoodBar(),
                  const SizedBox(height: 14),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'ابحث عن فيلم، مسلسل، أنمي، بودكاست...',
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => query = ''),
                            ),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        null,
                        'Global Series',
                        'Anime',
                        'Podcast',
                        'Book',
                      ].map((x) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(x ?? 'All'),
                            selected: type == x,
                            onSelected: (_) => setState(() => type = x),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    _emptyState(context)
                  else
                    ...filtered.map(
                      (item) => Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: item.imageUrl.isEmpty
                              ? const CircleAvatar(
                                  child: Icon(Icons.play_arrow_rounded),
                                )
                              : CircleAvatar(
                                  backgroundImage: NetworkImage(item.imageUrl),
                                ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.type} • ${item.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: uid == null
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    saved.contains(item.id)
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                  ),
                                  onPressed: () => saved.contains(item.id)
                                      ? repo.unsave(uid, item.id)
                                      : repo.save(uid, item.id),
                                ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AurenEntertainmentDetailScreen(
                                itemId: item.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAI,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AUREN AI'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entertainment, your way.',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Watch • Listen • Play • Create • Explore',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openAI,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('ماذا تريد أن تفعل الآن؟'),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatching(BuildContext context, String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.watchContinueWatching(uid),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <Map<String, dynamic>>[];
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Continue Watching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(height: 145, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final e = entries[i];
              final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
              return SizedBox(width: 210, child: Card(child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AurenEntertainmentDetailScreen(itemId: e['id'].toString()))),
                child: Padding(padding: const EdgeInsets.all(10), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title']?.toString() ?? 'محتوى', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 6),
                    Text('${(progress * 100).round()}% مكتمل', style: Theme.of(context).textTheme.bodySmall),
                  ],
                )),
              )));
            },
          )),
        ]);
      },
    );
  }

  Widget _buildMoodBar() {
    const moods = <String, String>{
      'خفيف': 'شيء خفيف وسريع للترفيه',
      'هدوء': 'موسيقى هادئة أو بودكاست مريح',
      'حماس': 'شيء حماسي وممتع',
      'اكتشاف': 'اكتشف شيئاً جديداً ومختلفاً',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختار الإحساس', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: moods.entries.map((entry) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: _mood == entry.key,
                onSelected: (_) => _setMood(entry.key, entry.value),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final action = _quickActions[index];
          return SizedBox(
            width: 118,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (action.title == 'Gaming') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenGamingScreen()));
                  } else if (action.title == 'Watch Together') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenWatchTogetherScreen()));
                  } else if (action.title == 'Movies') {\n                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMoviesHubScreen()));\n                  } else if (action.title == 'Watch AI') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenWatchConciergeScreen()));
                  } else if (action.title == 'Music') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenMusicHubScreen()));
                  } else if (action.title == 'Live') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRadioScreen()));
                  } else if (action.title == 'Create') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenEntertainmentCreateScreen()));
                  } else if (action.title == 'AI Series') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAiSeriesStudioScreen()));
                  } else {
                    _openAI();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(action.icon, size: 27),
                      const Spacer(),
                      Text(
                        action.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _emptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.explore_outlined, size: 44),
            const SizedBox(height: 10),
            const Text(
              'ما لقيت الشيء المطلوب؟',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'خلّي AUREN AI يختار لك تجربة مناسبة أو يساعدك في إنشاء تجربة جديدة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openAI,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('اسأل AUREN AI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntertainmentAction {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EntertainmentAction(this.icon, this.title, this.subtitle);
}
