import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class AurenEntertainmentOutputScreen extends StatefulWidget {
  final Map<String, dynamic> output;

  const AurenEntertainmentOutputScreen({
    super.key,
    required this.output,
  });

  @override
  State<AurenEntertainmentOutputScreen> createState() =>
      _AurenEntertainmentOutputScreenState();
}

class _AurenEntertainmentOutputScreenState
    extends State<AurenEntertainmentOutputScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  String get _type => widget.output['type']?.toString() ?? 'output';
  String get _url => widget.output['url']?.toString() ?? '';
  String get _text => widget.output['text']?.toString() ?? '';
  String get _mime => widget.output['mimeType']?.toString() ?? '';

  bool get _isVideo => _type == 'video' || _mime.startsWith('video/');

  @override
  void initState() {
    super.initState();
    if (_isVideo && _url.isNotEmpty) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(_url));
      _controller = controller;
      _initializeFuture = controller.initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isVideo
        ? 'فيديو AUREN'
        : _type == 'image'
            ? 'صورة AUREN'
            : 'ناتج AUREN';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _url.isEmpty && _text.isEmpty
          ? const Center(child: Text('لا يوجد ناتج قابل للعرض.'))
          : _isVideo
              ? _videoBody()
              : _type == 'image'
                  ? _imageBody()
                  : _textBody(),
    );
  }

  Widget _videoBody() {
    final controller = _controller;
    final future = _initializeFuture;
    if (controller == null || future == null) {
      return const Center(child: Text('تعذر تجهيز الفيديو.'));
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !controller.value.isInitialized) {
          return const Center(child: Text('تعذر تشغيل الفيديو. قد يكون الرابط المؤقت انتهت صلاحيته.'));
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 9 / 16
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }
                  if (mounted) setState(() {});
                },
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  controller.value.isPlaying ? 'إيقاف' : 'تشغيل',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: 'شاهد ناتج AUREN: ' + _url),
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('مشاركة'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageBody() {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.network(
                _url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text('تعذر عرض الصورة. قد يكون الرابط المؤقت انتهت صلاحيته.'),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: OutlinedButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: 'شاهد ناتج AUREN: ' + _url),
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('مشاركة'),
          ),
        ),
      ],
    );
  }

  Widget _textBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(
              _text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: OutlinedButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: _text),
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('مشاركة النص'),
          ),
        ),
      ],
    );
  }
}
