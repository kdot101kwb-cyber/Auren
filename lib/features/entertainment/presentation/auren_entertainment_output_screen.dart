import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

import '../../../services/entertainment/entertainment_repository.dart';

class AurenEntertainmentOutputScreen extends StatefulWidget {
  final Map<String, dynamic> output;
  final String? title;
  final String? episodeLabel;
  final VoidCallback? onNextEpisode;
  final String? nextEpisodeLabel;
  final String? nextPreviewUrl;
  final int nextCountdownSeconds;
  final List<Map<String, dynamic>> episodes;
  final ValueChanged<int>? onSelectEpisode;
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
    this.nextEpisodeLabel,
    this.nextPreviewUrl,
    this.nextCountdownSeconds = 10,
    this.episodes = const [],
    this.onSelectEpisode,
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
  double _playbackSpeed = 1.0;
  Duration _savedPosition = Duration.zero;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _progressLoaded = false;
  bool _didAutoAdvance = false;
  bool _showNextCountdown = false;
  int _nextCountdown = 10;
  Timer? _nextTimer;
  Timer? _controlsTimer;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _lastPlayingState = false;
  static const _speedPreferenceKey = 'auren_entertainment_playback_speed';
  static const _qualityPreferenceKey = 'auren_entertainment_quality';
  static const _lowDataPreferenceKey = 'auren_entertainment_low_data';
  String _quality = 'auto';
  bool _lowData = false;
  bool _switchingQuality = false;
  bool _isBuffering = false;
  bool _didBufferError = false;
  String _currentUrl = '';
  bool _completionHandling = false;
  int _recoveryAttempts = 0;
  bool _recoveringPlayback = false;
  String _subtitleLanguage = 'off';
  final Map<String, List<Map<String, dynamic>>> _subtitleCues = {};
  String _activeSubtitle = '';
  String _audioTrack = 'default';

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (!mounted) return;
    setState(() => _showControls = true);
    final controller = _controller;
    if (controller?.value.isPlaying == true) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller?.value.isPlaying == true) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  Future<void> _loadPlaybackPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _quality = prefs.getString(_qualityPreferenceKey) ?? 'auto';
      _lowData = prefs.getBool(_lowDataPreferenceKey) ?? false;
    });
  }

  Future<void> _saveQualityPreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityPreferenceKey, value);
  }

  Future<void> _saveLowDataPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowDataPreferenceKey, value);
  }

  Map<String, String> get _qualityUrls {
    final raw = widget.output['qualityUrls'];
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  String get _effectiveQuality {
    if (_lowData && _qualityUrls.containsKey('480p')) return '480p';
    return _quality;
  }

  Map<String, String> get _audioTrackUrls {
    final raw = widget.output['audioTrackUrls'];
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Map<String, String> get _subtitleUrls {
    final raw = widget.output['subtitleUrls'];
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> _loadSubtitle(String language) async {
    if (language == 'off') {
      if (mounted) setState(() { _subtitleLanguage = 'off'; _activeSubtitle = ''; });
      return;
    }
    final url = _subtitleUrls[language];
    if (url == null || url.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('subtitle');
      final cues = _parseVtt(response.body);
      if (!mounted) return;
      setState(() {
        _subtitleCues[language] = cues;
        _subtitleLanguage = language;
      });
      _updateSubtitle();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الترجمة.')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseVtt(String source) {
    final lines = const LineSplitter().convert(source.replaceAll('\r', ''));
    final cues = <Map<String, dynamic>>[];
    Duration? start;
    Duration? end;
    final text = <String>[];
    Duration? parseTime(String value) {
      final parts = value.trim().split(':');
      if (parts.length < 2) return null;
      final secondsPart = parts.last.replaceFirst(',', '.');
      final seconds = double.tryParse(secondsPart);
      if (seconds == null) return null;
      final minutes = int.tryParse(parts[parts.length - 2]) ?? 0;
      final hours = parts.length == 3 ? (int.tryParse(parts[0]) ?? 0) : 0;
      return Duration(milliseconds: ((hours * 3600 + minutes * 60 + seconds) * 1000).round());
    }
    void flush() {
      if (start != null && end != null && text.isNotEmpty) {
        cues.add({'start': start!, 'end': end!, 'text': text.join('\n')});
      }
      start = null; end = null; text.clear();
    }
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) { flush(); continue; }
      if (trimmed.contains('-->')) {
        final parts = trimmed.split('-->');
        if (parts.length >= 2) {
          start = parseTime(parts[0].trim().split(' ').first);
          end = parseTime(parts[1].trim().split(' ').first);
        }
      } else if (start != null) {
        if (!RegExp(r'^\d+$').hasMatch(trimmed) && trimmed != 'WEBVTT') text.add(trimmed);
      }
    }
    flush();
    return cues;
  }

  void _updateSubtitle() {
    final controller = _controller;
    if (!mounted || controller == null || _subtitleLanguage == 'off') return;
    final cues = _subtitleCues[_subtitleLanguage] ?? const [];
    final position = controller.value.position;
    String active = '';
    for (final cue in cues) {
      final start = cue['start'] as Duration;
      final end = cue['end'] as Duration;
      if (position >= start && position <= end) {
        active = cue['text']?.toString() ?? '';
        break;
      }
    }
    if (active != _activeSubtitle) setState(() => _activeSubtitle = active);
  }

  Future<void> _changeSubtitle() async {
    const preferredLanguages = ['ar', 'en', 'fr', 'es', 'pt', 'de', 'it', 'tr', 'zh', 'ja', 'ko', 'hi'];
    final ordered = preferredLanguages.where(_subtitleUrls.containsKey).toList();
    final extras = _subtitleUrls.keys.where((key) => !preferredLanguages.contains(key));
    final options = ['off', ...ordered, ...extras];
    if (options.length <= 1) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((lang) => ListTile(
            title: Text(lang == 'off' ? 'بدون ترجمة' : _subtitleLanguageName(lang)),
            trailing: lang == _subtitleLanguage ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.pop(sheetContext, lang),
          )).toList(),
        ),
      ),
    );
    if (selected != null) await _loadSubtitle(selected);
  }

  String _subtitleLanguageName(String code) {
    const names = {
      'ar': 'العربية',
      'en': 'English',
      'fr': 'Français',
      'es': 'Español',
      'pt': 'Português',
      'de': 'Deutsch',
      'it': 'Italiano',
      'tr': 'Türkçe',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'hi': 'हिन्दी',
    };
    return names[code] ?? code.toUpperCase();
  }

  Future<void> _changeAudioTrack() async {
    final tracks = _audioTrackUrls;
    if (tracks.isEmpty || _switchingQuality) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('المسار الافتراضي'),
              trailing: _audioTrack == 'default' ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(sheetContext, 'default'),
            ),
            ...tracks.keys.map((lang) => ListTile(
              title: Text(lang.toUpperCase()),
              trailing: lang == _audioTrack ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(sheetContext, lang),
            )),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final target = selected == 'default'
        ? widget.output['url']?.toString() ?? ''
        : tracks[selected] ?? '';
    if (target.isEmpty || target == _url) {
      if (mounted) setState(() => _audioTrack = selected);
      return;
    }
    await _switchVideoQuality(target);
    if (mounted) setState(() => _audioTrack = selected);
  }

  Future<void> _changeQuality() async {
    final urls = _qualityUrls;
    if (urls.isEmpty || _switchingQuality) return;
    final values = ['auto', '1080p', '720p', '480p', '360p']
        .where((q) => q == 'auto' || urls.containsKey(q))
        .toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...values.map((q) => ListTile(
              title: Text(q == 'auto' ? 'تلقائي' : q),
              trailing: q == _quality ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(sheetContext, q),
            )),
            SwitchListTile(
              title: const Text('وضع Low Data'),
              subtitle: const Text('يفضل 480p عند توفره لتقليل استهلاك البيانات'),
              value: _lowData,
              onChanged: (v) async {
                await _saveLowDataPreference(v);
                if (mounted) setState(() => _lowData = v);
                Navigator.pop(sheetContext);
                if (v && urls.containsKey('480p') && urls['480p'] != _url) {
                  await _switchVideoQuality(urls['480p']!);
                }
              },
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _saveQualityPreference(selected);
    if (mounted) setState(() => _quality = selected);
    final target = selected == 'auto'
        ? (_lowData && urls.containsKey('480p') ? '480p' : null)
        : urls[selected];
    if (target != null && target.isNotEmpty && target != _url) {
      await _switchVideoQuality(target);
    }
  }

  Future<void> _recoverPlayback() async {
    final url = _currentUrl.isNotEmpty ? _currentUrl : (widget.output['url']?.toString() ?? '');
    final old = _controller;
    if (url.isEmpty || old == null || _recoveringPlayback || !mounted) return;
    if (_recoveryAttempts >= 3) {
      if (_quality == 'auto' && !_lowData) {
        final fallback = _qualityUrls['720p'] ?? _qualityUrls['480p'] ?? _qualityUrls['360p'];
        if (fallback != null && fallback.isNotEmpty && fallback != _currentUrl) {
          _recoveryAttempts = 0;
          await _switchVideoQuality(fallback);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم خفض الجودة تلقائياً لتحسين التشغيل.')),
            );
          }
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر استعادة التشغيل. جرّب إعادة المحاولة لاحقاً.')),
      );
      return;
    }
    _recoveringPlayback = true;
    _recoveryAttempts++;
    final position = old.value.position;
    final wasPlaying = old.value.isPlaying;
    final volume = old.value.volume;
    if (mounted) setState(() => _switchingQuality = true);
    try {
      final next = VideoPlayerController.networkUrl(Uri.parse(url));
      await next.initialize();
      await next.setPlaybackSpeed(_playbackSpeed);
      await next.setVolume(volume);
      if (next.value.duration > Duration.zero) {
        await next.seekTo(position <= next.value.duration ? position : next.value.duration);
      }
      if (wasPlaying) await next.play();
      next.addListener(_onVideoProgress);
      next.addListener(() {
        if (!mounted) return;
        if (next.value.isBuffering != _isBuffering) {
          setState(() => _isBuffering = next.value.isBuffering);
        }
        if (next.value.hasError && !_didBufferError) {
          _didBufferError = true;
        }
      });
      _controller = next;
      _didBufferError = false;
      await old.pause();
      await old.dispose();
      if (mounted) {
        setState(() {
          _switchingQuality = false;
          _recoveringPlayback = false;
        });
        _resetControlsTimer();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _switchingQuality = false;
          _recoveringPlayback = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاسترداد ($_recoveryAttempts/3).')),
        );
      }
    }
  }

  Future<void> _switchVideoQuality(String targetUrl) async {
    final old = _controller;
    if (old == null || !mounted) return;
    setState(() => _switchingQuality = true);
    final wasPlaying = old.value.isPlaying;
    final position = old.value.position;
    final volume = old.value.volume;
    try {
      final next = VideoPlayerController.networkUrl(Uri.parse(targetUrl));
      await next.initialize();
      await next.setPlaybackSpeed(_playbackSpeed);
      await next.setVolume(volume);
      if (next.value.duration > Duration.zero) {
        await next.seekTo(position <= next.value.duration ? position : next.value.duration);
      }
      if (wasPlaying) await next.play();
      next.addListener(_onVideoProgress);
      next.addListener(() {
        if (!mounted) return;
        setState(() => _isBuffering = next.value.isBuffering);
      });
      _controller = next;
      _currentUrl = targetUrl;
      _didBufferError = false;
      await old.pause();
      await old.dispose();
      if (mounted) {
        setState(() => _switchingQuality = false);
        _resetControlsTimer();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _switchingQuality = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تغيير جودة الفيديو.')),
        );
      }
    }
  }

  Future<void> _loadPlaybackSpeed(VideoPlayerController controller) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_speedPreferenceKey);
    final allowed = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final speed = saved != null && allowed.contains(saved) ? saved : 1.0;
    await controller.setPlaybackSpeed(speed);
    if (mounted) setState(() => _playbackSpeed = speed);
  }

  Future<void> _savePlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedPreferenceKey, speed);
  }

  Future<void> _toggleFullscreen() async {
    final entering = !_isFullscreen;
    if (entering) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    if (mounted) setState(() => _isFullscreen = entering);
    _resetControlsTimer();
  }

  Future<void> _exitFullscreenIfNeeded() async {
    if (!_isFullscreen) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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

  Future<void> _handleVideoCompleted() async {
    if (_completionHandling) return;
    _completionHandling = true;
    try {
      await _saveWatchProgress(completed: true, force: true);
      if (!mounted || _didAutoAdvance || widget.onNextEpisode == null) return;
      _didAutoAdvance = true;
      _startNextCountdown();
    } finally {
      _completionHandling = false;
    }
  }

  void _onVideoProgress() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    _updateSubtitle();
    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      _handleVideoCompleted();
    } else if (!controller.value.isPlaying) {
      _saveWatchProgress(force: true);
    } else {
      _saveWatchProgress();
    }
  }

  void _startNextCountdown() {
    if (!mounted || widget.onNextEpisode == null) return;
    _nextTimer?.cancel();
    setState(() {
      _showNextCountdown = true;
      _nextCountdown = widget.nextCountdownSeconds.clamp(3, 30);
    });
    _nextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_nextCountdown <= 1) {
        timer.cancel();
        setState(() => _showNextCountdown = false);
        widget.onNextEpisode!();
        return;
      }
      setState(() => _nextCountdown--);
    });
  }

  void _cancelNextEpisode() {
    _nextTimer?.cancel();
    if (mounted) setState(() => _showNextCountdown = false);
  }

  String get _type => widget.output['type']?.toString() ?? 'output';
  String get _url => _currentUrl.isNotEmpty ? _currentUrl : (widget.output['url']?.toString() ?? '');
  String get _text => widget.output['text']?.toString() ?? '';
  String get _mime => widget.output['mimeType']?.toString() ?? '';

  bool get _isVideo => _type == 'video' || _mime.startsWith('video/');
  bool get _isAudio => _type == 'audio' || _mime.startsWith('audio/');

  @override
  void initState() {
    super.initState();
    _loadPlaybackPreferences();
    if (_isVideo && _url.isNotEmpty) {
      _currentUrl = _url;
      final controller = VideoPlayerController.networkUrl(Uri.parse(_currentUrl));
      _controller = controller;
      controller.addListener(() {
        final playing = controller.value.isPlaying;
        final buffering = controller.value.isBuffering;
        if (buffering != _isBuffering && mounted) {
          setState(() => _isBuffering = buffering);
        }
        if (controller.value.hasError && !_didBufferError && mounted) {
          _didBufferError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.value.errorDescription ?? 'حدث خطأ أثناء تشغيل الفيديو.'),
              action: SnackBarAction(label: 'إعادة المحاولة', onPressed: _recoverPlayback),
            ),
          );
        }
        if (playing != _lastPlayingState) {
          _lastPlayingState = playing;
          _resetControlsTimer();
        }
      });
      controller.addListener(_onVideoProgress);
      _initializeFuture = controller.initialize().then((_) async {
        await _loadPlaybackSpeed(controller);
        await _loadWatchProgress(controller);
      });
    } else if (_isAudio && _url.isNotEmpty) {
      _audioPlayer = AudioPlayer();
      _initializeFuture = _audioPlayer!.setUrl(_url).then((_) {});
    }
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _controlsTimer?.cancel();
    _saveWatchProgress(force: true);
    _controlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

  Future<void> _skipBy(int seconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    var target = controller.value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > controller.value.duration) target = controller.value.duration;
    await controller.seekTo(target);
  }

  Future<void> _showEpisodes() async {
    if (widget.episodes.isEmpty || widget.onSelectEpisode == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true, itemCount: widget.episodes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final e = widget.episodes[index];
            final n = e['episodeNumber']?.toString() ?? 'episode';
            final label = e['label']?.toString() ?? 'الحلقة $n';
            final active = e['episodeNumber']?.toString() == widget.watchEpisodeNumber?.toString();
            return ListTile(
              leading: CircleAvatar(child: Text(n)),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: active ? const Icon(Icons.play_arrow_rounded) : null,
              onTap: () {
                Navigator.pop(sheetContext);
                final number = int.tryParse(n);
                if (number != null && number != widget.watchEpisodeNumber) widget.onSelectEpisode!(number);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _changeSpeed() async {
    final speed = await showModalBottomSheet<double>(
      context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((value) => ListTile(
          title: Text('${value}x'),
          trailing: value == _playbackSpeed ? const Icon(Icons.check_rounded) : null,
          onTap: () => Navigator.pop(sheetContext, value),
        )).toList()),
      ),
    );
    if (speed != null && _controller != null) {
      await _controller!.setPlaybackSpeed(speed);
      await _savePlaybackSpeed(speed);
      if (mounted) setState(() => _playbackSpeed = speed);
    }
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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _resetControlsTimer,
          child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 9 / 16
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              if (_showControls)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showControls)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: _isFullscreen ? 'خروج من ملء الشاشة' : 'ملء الشاشة',
                    onPressed: _toggleFullscreen,
                    icon: Icon(_isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                  ),
                ),
              if (_activeSubtitle.isNotEmpty)
                Positioned(
                  bottom: 54,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Text(
                            _activeSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_switchingQuality || _isBuffering)
                Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(
                            _switchingQuality ? 'تغيير الجودة…' : 'جاري تحميل الفيديو…',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showControls)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _skipBy(-10),
                        icon: const Icon(Icons.replay_10_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          if (controller.value.isPlaying) {
                            await controller.pause();
                          } else {
                            await controller.play();
                          }
                          _resetControlsTimer();
                        },
                        icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => _skipBy(30),
                        icon: const Icon(Icons.forward_30_rounded),
                      ),
                    ],
                  ),
                ),
                ],
              ),
              if (_showNextCountdown && widget.onNextEpisode != null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.nextPreviewUrl?.isNotEmpty == true)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            widget.nextPreviewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.skip_next_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('التالي', style: TextStyle(fontSize: 12)),
                                  Text(
                                    widget.nextEpisodeLabel ?? 'الحلقة التالية',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'تبدأ تلقائياً خلال $_nextCountdown ثوانٍ',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _cancelNextEpisode,
                              child: const Text('إلغاء'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                            if (_didBufferError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: _recoveringPlayback ? null : _recoverPlayback,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_recoveringPlayback ? 'جارٍ الاستعادة…' : 'إعادة تشغيل'),
                  ),
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
                IconButton(onPressed: () => _skipBy(-10), icon: const Icon(Icons.replay_10_rounded)),
                IconButton(onPressed: () => _skipBy(30), icon: const Icon(Icons.forward_30_rounded)),
                IconButton(onPressed: _changeSpeed, icon: const Icon(Icons.speed_rounded)),
                if (_qualityUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _lowData ? 'Low Data' : (_quality == 'auto' ? 'Auto' : _quality),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_subtitleUrls.isNotEmpty)
                  IconButton(
                    tooltip: 'الترجمة',
                    onPressed: _changeSubtitle,
                    icon: const Icon(Icons.closed_caption_rounded),
                  ),
                if (_audioTrackUrls.isNotEmpty)
                  IconButton(
                    tooltip: 'مسار الصوت',
                    onPressed: _changeAudioTrack,
                    icon: const Icon(Icons.audiotrack_rounded),
                  ),
                if (_qualityUrls.isNotEmpty)
                  IconButton(
                    tooltip: 'الجودة والبيانات',
                    onPressed: _changeQuality,
                    icon: Icon(_lowData ? Icons.data_saver_on_rounded : Icons.hd_rounded),
                  ),
                if (widget.episodes.isNotEmpty && widget.onSelectEpisode != null)
                  IconButton(onPressed: _showEpisodes, icon: const Icon(Icons.list_alt_rounded)),
              ]),
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
