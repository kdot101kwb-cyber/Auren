import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_audio_player_screen.dart';

class AurenSmartMusicScreen extends StatefulWidget {
  const AurenSmartMusicScreen({super.key});

  @override
  State<AurenSmartMusicScreen> createState() => _AurenSmartMusicScreenState();
}

class _AurenSmartMusicScreenState extends State<AurenSmartMusicScreen> {
  final repo = EntertainmentRepository();
  final search = TextEditingController();
  String mood = 'الكل';

  static const moods = ['الكل', 'هادئ', 'حماس', 'تركيز', 'سفر', 'تسلية'];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<AurenEntertainmentItem> _smart(List<AurenEntertainmentItem> source) {
    final query = search.text.trim().toLowerCase();
    final filtered = source.where((item) {
      if (query.isEmpty) return true;
      final text = (item.title + ' ' + item.description).toLowerCase();
      return text.contains(query);
    }).toList();

    if (mood != 'الكل') {
      final moodMatches = filtered.where((item) {
        final text = (item.title + ' ' + item.description).toLowerCase();
        return text.contains(mood.toLowerCase());
      }).toList();
      if (moodMatches.isNotEmpty) return moodMatches;
    }

    // Keep the recommendation deterministic: richer metadata first, then title.
    filtered.sort((a, b) {
      final aScore = a.description.length + a.title.length;
      final bScore = b.description.length + b.title.length;
      final score = bScore.compareTo(aScore);
      return score != 0 ? score : a.title.compareTo(b.title);
    });
    return filtered;
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
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Mix queue',
            onPressed: _mix,
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Music'),
        builder: (context, snapshot) {
          final smart = _smart(
            snapshot.data ?? const <AurenEntertainmentItem>[],
          );

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
      ),
    );
  }
}
