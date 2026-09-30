import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AurenPodcastVideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String description;
  final String imageUrl;

  const AurenPodcastVideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.description = '',
    this.imageUrl = '',
  });

  @override
  State<AurenPodcastVideoPlayerScreen> createState() => _AurenPodcastVideoPlayerScreenState();
}

class _AurenPodcastVideoPlayerScreenState extends State<AurenPodcastVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _loading = false;
      });
      await c.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر تشغيل فيديو الحلقة.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Video Podcast')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: Text(_error!)),
            )
          else if (c != null && c.value.isInitialized)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio,
                    child: VideoPlayer(c),
                  ),
                ),
                VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(c.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                      iconSize: 52,
                      onPressed: () => setState(() {
                        c.value.isPlaying ? c.pause() : c.play();
                      }),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 18),
          Text(widget.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          if (widget.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.description),
          ],
        ],
      ),
    );
  }
}
