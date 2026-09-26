import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_audio_player_screen.dart';

class AurenSmartMusicScreen extends StatelessWidget {
  const AurenSmartMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Smart Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Mix',
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Music'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const Center(child: Text('أضف موسيقى أولاً ليبني AUREN قائمة ذكية.'));
          }

          final smart = [...items]
            ..sort((a, b) {
              final am = a.description.length + a.title.length;
              final bm = b.description.length + b.title.length;
              return bm.compareTo(am);
            });

          return ListView(
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 38),
                    SizedBox(height: 8),
                    Text('Your Smart Mix',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('AUREN يرتب محتواك ويقترح تجربة استماع حسب ما لديك ووقت الاستخدام.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Recommended for you',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...smart.map((item) => Card(
                    child: ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(child: Icon(Icons.music_note))
                          : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                      title: Text(item.title),
                      subtitle: Text(item.type),
                      onTap: item.mediaUrl.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AurenAudioPlayerScreen(item: item),
                                ),
                              ),
                      trailing: IconButton(
                        tooltip: 'Add to Queue',
                        icon: const Icon(Icons.queue_music_rounded),
                        onPressed: item.mediaUrl.isEmpty
                            ? null
                            : () => AurenMusicPlayerController.instance.addToQueue(item),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
