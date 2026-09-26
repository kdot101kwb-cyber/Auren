import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/entertainment.dart';

class AurenAudioPlayerScreen extends StatefulWidget {
  final AurenEntertainmentItem item;
  const AurenAudioPlayerScreen({super.key, required this.item});

  @override
  State<AurenAudioPlayerScreen> createState() => _AurenAudioPlayerScreenState();
}

class _AurenAudioPlayerScreenState extends State<AurenAudioPlayerScreen> {
  late final AudioPlayer _player;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    if (widget.item.mediaUrl.isEmpty) {
      setState(() => _error = 'لا يوجد رابط صوت لهذا المحتوى.');
      return;
    }
    try {
      await _player.setUrl(widget.item.mediaUrl);
      await _player.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تشغيل الصوت.');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Music')),
      body: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final playing = state?.playing ?? false;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.tertiaryContainer,
                    ],
                  ),
                ),
                child: widget.item.imageUrl.isEmpty
                    ? const Icon(Icons.music_note_rounded, size: 90)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(widget.item.imageUrl, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 24),
              Text(widget.item.title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(widget.item.description),
              const SizedBox(height: 24),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (_, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = _player.duration ?? Duration.zero;
                  final max = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                  return Column(
                    children: [
                      Slider(
                        value: position.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                        max: max,
                        onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [_time(position), _time(duration)],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () => _player.seek(Duration(seconds: (_player.position.inSeconds - 10).clamp(0, 999999))),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                    onPressed: () => playing ? _player.pause() : _player.play(),
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 38),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () => _player.seek(_player.position + const Duration(seconds: 10)),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, textAlign: TextAlign.center),
              ],
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
