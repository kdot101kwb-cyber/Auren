import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../services/social/match_everything_service.dart';

class AurenContentDetailScreen extends StatefulWidget {
  final AurenMatchItem item;
  final String intent;
  const AurenContentDetailScreen({super.key, required this.item, required this.intent});
  @override State<AurenContentDetailScreen> createState() => _AurenContentDetailScreenState();
}

class _AurenContentDetailScreenState extends State<AurenContentDetailScreen> {
  VideoPlayerController? _video;
  Future<void>? _videoInit;

  @override
  void initState() {
    super.initState();
    final url = widget.item.data['mediaUrl']?.toString() ?? '';
    final type = widget.item.data['mediaType']?.toString().toLowerCase() ?? '';
    if (url.isNotEmpty && (type.contains('video') || url.toLowerCase().endsWith('.mp4'))) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _video = controller;
      _videoInit = controller.initialize();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.item.data;
    final author = (d['authorName'] ?? d['displayName'] ?? d['creatorName'])?.toString() ?? '';
    final text = (d['text'] ?? d['description'] ?? d['caption'])?.toString() ?? '';
    final mediaUrl = d['mediaUrl']?.toString() ?? '';
    final mediaType = d['mediaType']?.toString().toLowerCase() ?? '';
    final isImage = mediaUrl.isNotEmpty && (mediaType.contains('image') || (!mediaType.contains('video') && !mediaType.contains('audio') && !mediaUrl.toLowerCase().endsWith('.mp4')));

    return Scaffold(
      appBar: AppBar(title: const Text('Content')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.play_circle_outline, size: 44),
            const SizedBox(height: 12),
            Text(widget.item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (author.isNotEmpty) ...[const SizedBox(height: 8), Text(author)],
            const SizedBox(height: 14),
            if (_video != null)
              FutureBuilder<void>(
                future: _videoInit,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()));
                  if (snapshot.hasError) return const Text('تعذر تشغيل الفيديو.');
                  return Column(children: [
                    AspectRatio(aspectRatio: _video!.value.aspectRatio == 0 ? 16 / 9 : _video!.value.aspectRatio, child: VideoPlayer(_video!)),
                    const SizedBox(height: 8),
                    Row(children: [
                      IconButton.filled(
                        onPressed: () { setState(() { _video!.value.isPlaying ? _video!.pause() : _video!.play(); }); },
                        icon: Icon(_video!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: VideoProgressIndicator(_video!, allowScrubbing: true)),
                    ]),
                  ]);
                },
              )
            else if (isImage)
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image_outlined))))))
            else
              Text(text.isEmpty ? 'لا يوجد وصف أو وسائط متاحة.' : text),
            if (_video != null || isImage) ...[
              const SizedBox(height: 14),
              if (text.isNotEmpty) Text(text),
            ],
          ]))),
          if (widget.intent.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(child: ListTile(leading: const Icon(Icons.search), title: const Text('طلبك'), subtitle: Text(widget.intent))),
          ],
          if (widget.item.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('سبب المطابقة', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...widget.item.reasons.map((x) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $x'))),
            ]))),
          ],
        ],
      ),
    );
  }
}
