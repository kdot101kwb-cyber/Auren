import 'package:flutter/material.dart';

import '../../../services/entertainment/auren_music_player_controller.dart';
import 'auren_audio_player_screen.dart';

class AurenMiniPlayer extends StatelessWidget {
  const AurenMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AurenMusicPlayerController.instance,
      builder: (context, _) {
        final controller = AurenMusicPlayerController.instance;
        final item = controller.item;
        if (item == null) return const SizedBox.shrink();
        return Material(
          elevation: 8,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenAudioPlayerScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    item.imageUrl.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.music_note))
                        : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                    IconButton(
                      tooltip: controller.playing ? 'إيقاف' : 'تشغيل',
                      icon: Icon(controller.playing ? Icons.pause : Icons.play_arrow),
                      onPressed: controller.toggle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
