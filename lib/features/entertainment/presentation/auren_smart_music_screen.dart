import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_audio_player_screen.dart';
import 'auren_music_concierge_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class _OriginalMusicCreationScreen extends StatefulWidget {
  @override
  State<_OriginalMusicCreationScreen> createState() => _OriginalMusicCreationScreenState();
}

class _OriginalMusicCreationScreenState extends State<_OriginalMusicCreationScreen> {
  final idea = TextEditingController();
  String genre = 'Afrobeat';
  String mood = 'حماس';
  String language = 'العربية';

  static const genres = ['Afrobeat', 'Pop', 'Hip Hop', 'R&B', 'Rock', 'Classical', 'Chill'];
  static const moods = ['هادئ', 'حماس', 'تركيز', 'رومانسي', 'حزين', 'تسلية'];
  static const languages = ['العربية', 'English', 'Français', 'Español'];

  @override
  void dispose() {
    idea.dispose();
    super.dispose();
  }

  void createBrief() {
    final text = idea.text.trim().isEmpty ? 'أغنية أصلية عن الأمل وبداية جديدة' : idea.text.trim();
    final prompt = 'أريد إنشاء أغنية أصلية بالكامل داخل AUREN Music AI. الفكرة: $text. '
        'النوع: $genre. المزاج: $mood. اللغة: $language. '
        'أنشئ لي أولاً Creative Brief يتضمن العنوان المقترح، الفكرة، بنية الأغنية، كلمات أصلية، وصف التوزيع والموسيقى والمؤثرات، '
        'مع التأكيد على عدم تقليد صوت أو أسلوب فنان حقيقي وعدم استخدام مادة محمية دون ترخيص.';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MessengerScreen(initialPrompt: prompt),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Original Music AI')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome_rounded, size: 38),
            SizedBox(height: 8),
            Text('Create. Compose. Own.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('نبدأ من فكرة أصلية ثم نحوّلها إلى Creative Brief قابل للإنتاج.'),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: idea,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'فكرة الأغنية',
            hintText: 'مثلاً: أغنية عن السودان، الأمل، والصداقة بين الشعوب',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        const Text('النوع', style: TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 8, children: genres.map((v) => ChoiceChip(label: Text(v), selected: genre == v, onSelected: (_) => setState(() => genre = v))).toList()),
        const SizedBox(height: 14),
        const Text('المزاج', style: TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 8, children: moods.map((v) => ChoiceChip(label: Text(v), selected: mood == v, onSelected: (_) => setState(() => mood = v))).toList()),
        const SizedBox(height: 14),
        const Text('اللغة', style: TextStyle(fontWeight: FontWeight.w700)),
        Wrap(spacing: 8, children: languages.map((v) => ChoiceChip(label: Text(v), selected: language == v, onSelected: (_) => setState(() => language = v))).toList()),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: createBrief,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('ابدأ إنشاء الأغنية'),
        ),
        const SizedBox(height: 10),
        const Text('حقوق آمنة: المحتوى المقترح أصلي، ولا يُفترض تقليد أصوات فنانين حقيقيين أو استخدام مواد محمية بلا ترخيص.',
          style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class AurenSmartMusicScreen extends StatefulWidget {
  const AurenSmartMusicScreen({super.key});

  @override
  State<AurenSmartMusicScreen> createState() => _AurenSmartMusicScreenState();
}

class _AurenSmartMusicScreenState extends State<AurenSmartMusicScreen> {
  final repo = EntertainmentRepository();
  final search = TextEditingController();
  String mood = 'الكل';
  String context = 'تلقائي';
  String activity = 'تلقائي';
  List<AurenEntertainmentItem> _latestSource = const <AurenEntertainmentItem>[];

  static const moods = ['الكل', 'هادئ', 'حماس', 'تركيز', 'سفر', 'تسلية'];
  static const contexts = ['تلقائي', 'صباح', 'ليل', 'عمل', 'رحلة', 'استرخاء'];
  static const activities = ['تلقائي', 'تمرين', 'دراسة', 'سفر', 'نوم', 'استرخاء', 'حفلة'];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<AurenEntertainmentItem> _smart(
    List<AurenEntertainmentItem> source, {
    Map<String, Map<String, dynamic>> signals = const {},
  }) {
    final query = search.text.trim().toLowerCase();
    final filtered = source.where((item) {
      if (query.isEmpty) return true;
      final text = (item.title + ' ' + item.description).toLowerCase();
      return text.contains(query);
    }).toList();

    if (activity != 'تلقائي') {
      final matches = filtered.where((item) {
        final text = (item.title + ' ' + item.description).toLowerCase();
        const map = <String, List<String>>{
          'تمرين': ['workout', 'gym', 'exercise', 'تمرين', 'رياضة'],
          'دراسة': ['study', 'focus', 'دراسة', 'تركيز'],
          'سفر': ['travel', 'trip', 'سفر', 'رحلة'],
          'نوم': ['sleep', 'night', 'نوم', 'ليل'],
          'استرخاء': ['relax', 'calm', 'chill', 'استرخاء', 'هادئ'],
          'حفلة': ['party', 'dance', 'حفلة', 'رقص'],
        };
        return (map[activity] ?? const <String>[]).any(text.contains);
      }).toList();
      if (matches.isNotEmpty) return matches;
    }

    if (mood != 'الكل') {
      final moodMatches = filtered.where((item) {
        final text = (item.title + ' ' + item.description).toLowerCase();
        return text.contains(mood.toLowerCase());
      }).toList();
      if (moodMatches.isNotEmpty) return moodMatches;
    }

    final now = DateTime.now();
    final hour = now.hour;
    final effectiveContext = context == 'تلقائي'
        ? (hour >= 6 && hour < 12 ? 'صباح' : hour >= 21 || hour < 6 ? 'ليل' : 'عمل')
        : context;
    final historyIds = AurenMusicPlayerController.instance.history
        .map((item) => item.id)
        .toSet();

    // Context-aware local ranking: recent listening, matching metadata, and
    // the user's selected context influence order without changing the library.
    filtered.sort((a, b) {
      double score(AurenEntertainmentItem item) {
        final text = (item.title + ' ' + item.description).toLowerCase();
        var value = (item.description.length + item.title.length) / 10;
        if (historyIds.contains(item.id)) value += 4;
        final signal = signals[item.id];
        if (signal != null) {
          final watchSeconds = (signal['watchSeconds'] as num?)?.toDouble() ?? 0;
          final likes = (signal['likes'] as num?)?.toDouble() ?? 0;
          final saves = (signal['saves'] as num?)?.toDouble() ?? 0;
          final completions = (signal['completions'] as num?)?.toDouble() ?? 0;
          final skips = (signal['skips'] as num?)?.toDouble() ?? 0;
          value += watchSeconds * 0.02;
          value += likes * 5;
          value += saves * 3;
          value += completions * 2;
          value -= skips * 2;
        }
        if (mood != 'الكل' && text.contains(mood.toLowerCase())) value += 8;
        if (effectiveContext != 'تلقائي' && text.contains(effectiveContext.toLowerCase())) value += 6;
        if (effectiveContext == 'ليل' && text.contains('هادئ')) value += 3;
        if (effectiveContext == 'عمل' && text.contains('تركيز')) value += 3;
        if (effectiveContext == 'رحلة' && text.contains('سفر')) value += 3;
        if (effectiveContext == 'استرخاء' && text.contains('هادئ')) value += 3;
        const activityHints = <String, List<String>>{
          'تمرين': ['workout', 'gym', 'exercise', 'تمرين', 'رياضة'],
          'دراسة': ['study', 'focus', 'دراسة', 'تركيز'],
          'سفر': ['travel', 'trip', 'سفر', 'رحلة'],
          'نوم': ['sleep', 'night', 'نوم', 'ليل'],
          'استرخاء': ['relax', 'calm', 'chill', 'استرخاء', 'هادئ'],
          'حفلة': ['party', 'dance', 'حفلة', 'رقص'],
        };
        if (activity != 'تلقائي' && (activityHints[activity] ?? const <String>[]).any(text.contains)) value += 10;
        return value;
      }
      return score(b).compareTo(score(a));
    });
    return filtered;
  }

  void _generateSmartPlaylist(List<AurenEntertainmentItem> source) {
    final items = _smart(source).where((item) => item.mediaUrl.isNotEmpty).take(10).toList();
    final controller = AurenMusicPlayerController.instance;
    for (final item in items) {
      if (!controller.queue.any((queued) => queued.id == item.id)) {
        controller.addToQueue(item);
      }
    }
    if (items.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء Smart Playlist من ${items.length} مقاطع 🎵')),
      );
    }
  }
  void _concierge(List<AurenEntertainmentItem> source) {
    final controller = AurenMusicPlayerController.instance;
    final items = _smart(source).where((item) => item.mediaUrl.isNotEmpty).take(12).toList();
    for (final item in items) {
      if (!controller.queue.any((queued) => queued.id == item.id)) {
        controller.addToQueue(item);
      }
    }
    if (!mounted) return;
    final label = mood == 'الكل' && context == 'تلقائي' ? 'ذكي تلقائي' : '$mood • $context';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AUREN جهّز لك قائمة: $label (' + items.length.toString() + ' مقاطع)')),
    );
  }
  void _mix() {
    final controller = AurenMusicPlayerController.instance;
    final queue = controller.queue;
    if (queue.length < 2) return;
    final rotated = [...queue.skip(1), queue.first];
    for (final item in rotated) {
      controller.removeFromQueue(item);
    }
    for (final item in rotated) {
      controller.addToQueue(item);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Smart Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Music Concierge',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenMusicConciergeScreen(source: _latestSource))),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Music'),
        builder: (context, snapshot) {
          final source = snapshot.data ?? const <AurenEntertainmentItem>[];
          _latestSource = source;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: uid == null ? Future.value(const <String, Map<String, dynamic>>{}) : repo.getMusicSignals(uid),
            builder: (context, signalSnapshot) {
              final smart = _smart(source, signals: signalSnapshot.data ?? const <String, Map<String, dynamic>>{});
                  if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
          }
              if (snapshot.hasError) {
                return Center(
                  child: Text('تعذر تحميل الموسيقى: ' + snapshot.error.toString()),
                );
              }
              if (smart.isEmpty) {
                return const Center(child: Text('لا توجد موسيقى مطابقة حاليًا.'));
              }

              return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                    Icon(Icons.auto_awesome_rounded, size: 38),
                    SizedBox(height: 8),
                    Text(
                      'Your Smart Mix',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'AUREN يرتب الموسيقى المتاحة حسب السياق والبيانات الموجودة، بدون تغيير ذوقك أو وضعك الأساسي.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'ابحث في الموسيقى...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: moods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ChoiceChip(
                    label: Text(moods[index]),
                    selected: mood == moods[index],
                    onSelected: (_) => setState(() => mood = moods[index]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: contexts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ChoiceChip(
                    label: Text(contexts[index]),
                    selected: context == contexts[index],
                    onSelected: (_) => setState(() => context = contexts[index]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ChoiceChip(
                    label: Text(activities[index]),
                    selected: activity == activities[index],
                    onSelected: (_) => setState(() => activity = activities[index]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenMusicConciergeScreen(source: source))),
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('افعلها لي — أنشئ قائمة ذكية'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recommended for you',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...smart.map(
                (item) => Card(
                  child: ListTile(
                    leading: item.imageUrl.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.music_note))
                        : CircleAvatar(
                            backgroundImage: NetworkImage(item.imageUrl),
                          ),
                    title: Text(item.title),
                    subtitle: Text(
                      item.description.isEmpty ? item.type : item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    trailing: IconButton(
                      tooltip: 'Add to Queue',
                      icon: const Icon(Icons.queue_music_rounded),
                      onPressed: item.mediaUrl.isEmpty
                          ? null
                          : () => AurenMusicPlayerController.instance
                              .addToQueue(item),
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
    );
  }
}
