import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_audio_player_screen.dart';

class AurenMusicQueueScreen extends StatelessWidget {
  const AurenMusicQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AurenMusicPlayerController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Playlist & Queue')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final queue = controller.queue;
          final history = controller.history;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Up Next', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (queue.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('أضف موسيقى إلى Queue من المحتوى لتجهيز قائمة التشغيل.'),
                ))
              else
                ...queue.map((item) => _tile(context, item, controller, canRemove: true)),
              const SizedBox(height: 22),
              const Text('Recently Played', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('ستظهر هنا آخر المقاطع التي استمعت إليها.'),
                ))
              else
                ...history.map((item) => _tile(context, item, controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, AurenEntertainmentItem item,
      AurenMusicPlayerController controller, {bool canRemove = false}) {
    return Card(
      child: ListTile(
        leading: item.imageUrl.isEmpty
            ? const CircleAvatar(child: Icon(Icons.music_note))
            : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.type),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item))),
        trailing: canRemove
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => controller.removeFromQueue(item),
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () => controller.playItem(item),
              ),
      ),
    );
  }
}
