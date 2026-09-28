import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import 'auren_audio_player_screen.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';

class AurenMusicCollectionScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AurenEntertainmentItem> items;
  final bool album;

  const AurenMusicCollectionScreen({
    super.key,
    required this.title,
    required this.items,
    this.subtitle = '',
    this.album = false,
  });

  @override
  Widget build(BuildContext context) {
    final playable = items.where((x) => x.mediaUrl.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(radius: 42, child: Icon(album ? Icons.album_rounded : Icons.person_rounded, size: 42)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          if (playable.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                final controller = AurenMusicPlayerController.instance;
                for (final item in playable) {
                  if (!controller.queue.any((q) => q.id == item.id)) controller.addToQueue(item);
                }
                controller.playItem(playable.first);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(album ? 'تشغيل الألبوم' : 'تشغيل الفنان'),
            ),
          const SizedBox(height: 12),
          ...items.map((item) => Card(
            child: ListTile(
              leading: item.imageUrl.isEmpty
                  ? const CircleAvatar(child: Icon(Icons.music_note))
                  : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
              title: Text(item.title),
              subtitle: Text(item.albumName.isNotEmpty ? item.albumName : (item.description.isEmpty ? item.type : item.description),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: item.mediaUrl.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AurenAudioPlayerScreen(item: item),
              )),
              trailing: IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: item.mediaUrl.isEmpty ? null : () => AurenMusicPlayerController.instance.addToQueue(item),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
