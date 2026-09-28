import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

import '../../../services/entertainment/entertainment_repository.dart';

class AurenEntertainmentOutputScreen extends StatefulWidget {
  final Map<String, dynamic> output;
  final String? title;
  final String? episodeLabel;
  final VoidCallback? onNextEpisode;
  final String? watchUid;
  final String? watchJobId;
  final int? watchEpisodeNumber;
  final String? watchTitle;

  const AurenEntertainmentOutputScreen({
    super.key,
    required this.output,
    this.title,
    this.episodeLabel,
    this.onNextEpisode,
    this.watchUid,
    this.watchJobId,
    this.watchEpisodeNumber,
    this.watchTitle,
  });

  @override
  State<AurenEntertainmentOutputScreen> createState() =>
      _AurenEntertainmentOutputScreenState();
}

class _AurenEntertainmentOutputScreenState
    extends State<AurenEntertainmentOutputScreen> {
  VideoPlayerController? _controller;
  AudioPlayer? _audioPlayer;
  Future<void>? _initializeFuture;
  bool _muted = false;
  Duration _savedPosition = Duration.zero;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _progressLoaded = false;

  bool get _canSaveWatchProgress => widget.watchUid?.isNotEmpty == true &&
      widget.watchJobId?.isNotEmpty == true &&
      (widget.watchEpisodeNumber ?? 0) > 0;

  Future<void> _loadWatchProgress(VideoPlayerController controller) async {
    if (!_canSaveWatchProgress || _progressLoaded) return;
    _progressLoaded = true;
    final saved = await EntertainmentRepository().getSeriesWatchProgress(
      widget.watchUid!, widget.watchJobId!, widget.watchEpisodeNumber!,
    );
    if (!mounted || !controller.value.isInitialized || saved == null) return;
    final seconds = (saved['positionSeconds'] as num?)?.toInt() ?? 0;
    final duration = controller.value.duration.inSeconds;
    if (seconds <= 5 || (duration > 0 && seconds >= duration - 5)) return;
    _savedPosition = Duration(seconds: seconds.clamp(0, duration > 0 ? duration - 1 : seconds));
    await controller.seekTo(_savedPosition);
  }

  Future<void> _saveWatchProgress({bool completed = false, bool force = false}) async {
    final controller = _controller;
    if (!_canSaveWatchProgress || controller == null || !controller.value.isInitialized) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastProgressSave) < const Duration(seconds: 5)) return;
    _lastProgressSave = now;
    final position = controller.value.position;
    final duration = controller.value.duration;
    await EntertainmentRepository().saveSeriesWatchProgress(
      widget.watchUid!, widget.watchJobId!, widget.watchEpisodeNumber!,
      positionSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
      title: widget.watchTitle ?? widget.title,
      videoUrl: _url,
      completed: completed,
    );
  }

  void _onVideoProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.position >= controller.value.duration && controller.value.duration > Duration.zero) {
      _saveWatchProgress(completed: true, force: true);
    } else if (!controller.value.isPlaying) {
      _saveWatchProgress(force: true);
    } else {
      _saveWatchProgress();
    }
  }

  String get _type => widget.output['type']?.toString() ?? 'output';
  String get _url => widget.output['url']?.toString() ?? '';
  String get _text => widget.output['text']?.toString() ?? '';
  String get _mime => widget.output['mimeType']?.toString() ?? '';

  bool get _isVideo => _type == 'video' || _mime.startsWith('video/');
  bool get _isAudio => _type == 'audio' || _mime.startsWith('audio/');

  @override
  void initState() {
    super.initState();
    if (_isVideo && _url.isNotEmpty) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(_url));
      _controller = controller;
      controller.addListener(_onVideoProgress);
      _initializeFuture = controller.initialize().then((_) => _loadWatchProgress(controller));
    } else if (_isAudio && _url.isNotEmpty) {
      _audioPlayer = AudioPlayer();
      _initializeFuture = _audioPlayer!.setUrl(_url).then((_) {});
    }
  }

  @override
  void dispose() {
    _saveWatchProgress(force: true);
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title?.isNotEmpty == true
        ? widget.title!
        : _isVideo
            ? 'فيديو AUREN'
        : _isAudio
            ? 'موسيقى AUREN'
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
                  : _isAudio
                      ? _audioBody()
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
              if (widget.episodeLabel != null)
                Text(widget.episodeLabel!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (_savedPosition > Duration.zero)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('استئناف من ${_formatDuration(_savedPosition)}', style: Theme.of(context).textTheme.bodySmall),
                ),
              if (_canSaveWatchProgress)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 6)),
                ),
              FilledButton.icon(
                onPressed: () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }
                  if (mounted) setState(() {});
                },
                icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(controller.value.isPlaying ? 'إيقاف' : 'تشغيل'),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
                  onPressed: () {
                    setState(() {
                      _muted = !_muted;
                      controller.setVolume(_muted ? 0 : 1);
                    });
                  },
                  icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                ),
                if (widget.onNextEpisode != null)
                  IconButton(
                    tooltip: 'الحلقة التالية',
                    onPressed: widget.onNextEpisode,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
              ]),
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

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  Widget _audioBody() {
    final player = _audioPlayer;
    final future = _initializeFuture;
    if (player == null || future == null) {
      return const Center(child: Text('تعذر تجهيز الصوت.'));
    }
    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تشغيل الصوت.'));
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, size: 96),
              const SizedBox(height: 18),
              Text(
                'ناتج موسيقي تم إنشاؤه بواسطة AUREN',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? player.playing;
                  return FilledButton.icon(
                    onPressed: () async {
                      if (playing) {
                        await player.pause();
                      } else {
                        await player.play();
                      }
                      if (mounted) setState(() {});
                    },
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(playing ? 'إيقاف' : 'تشغيل'),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: 'استمع إلى ناتج AUREN: ' + _url),
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
