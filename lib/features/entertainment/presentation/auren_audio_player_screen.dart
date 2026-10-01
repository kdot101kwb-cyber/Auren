import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/auren_music_player_controller.dart';

class AurenAudioPlayerScreen extends StatefulWidget {
  final AurenEntertainmentItem? item;
  const AurenAudioPlayerScreen({super.key, this.item});

  @override
  State<AurenAudioPlayerScreen> createState() => _AurenAudioPlayerScreenState();
}

class _AurenAudioPlayerScreenState extends State<AurenAudioPlayerScreen> {
  final controller = AurenMusicPlayerController.instance;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.item != null) {
        await controller.playItem(widget.item!);
      } else {
        await controller.restorePlayback();
      }
      if (mounted) setState(() => _restored = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Music'), actions: [IconButton(tooltip: 'استعادة التشغيل', icon: const Icon(Icons.restore_rounded), onPressed: () async { await controller.restorePlayback(); if (mounted) setState(() => _restored = true); })]),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final item = controller.item;
          if (item == null) {
            return const Center(child: Text('اختر موسيقى أو بودكاست لبدء التشغيل.'));
          }
          final position = controller.position;
          final duration = controller.duration;
          final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
          final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.tertiaryContainer,
                  ]),
                ),
                child: item.imageUrl.isEmpty
                    ? const Icon(Icons.music_note_rounded, size: 90)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(item.imageUrl, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 24),
              Text(item.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(item.description),
              const SizedBox(height: 24),
              Slider(
                value: value,
                max: max,
                onChanged: duration == Duration.zero
                    ? null
                    : (v) => controller.seek(Duration(milliseconds: v.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_time(position), _time(duration)],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () => controller.skip(-10),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: controller.loading ? null : controller.toggle,
                    child: Icon(
                      controller.loading
                          ? Icons.hourglass_top_rounded
                          : controller.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () => controller.skip(10),
                  ),
                ],
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 20),
                Text(controller.error!, textAlign: TextAlign.center),
              ],
              if (!_restored && controller.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: LinearProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _time(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return Text('$minutes:${seconds.toString().padLeft(2, '0')}');
  }
}
