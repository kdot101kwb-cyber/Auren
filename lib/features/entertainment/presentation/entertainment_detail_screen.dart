import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenEntertainmentDetailScreen extends StatefulWidget {
  final String itemId;
  const AurenEntertainmentDetailScreen({super.key, required this.itemId});
  @override State<AurenEntertainmentDetailScreen> createState() => _AurenEntertainmentDetailState();
}

class _AurenEntertainmentDetailState extends State<AurenEntertainmentDetailScreen> {
  VideoPlayerController? _controller;
  bool _starting = false;
  AurenEntertainmentItem? _activeItem;
  String? _uid;
  Duration _lastSavedPosition = Duration.zero;

  @override
  void dispose() { _saveProgress(); _controller?.dispose(); super.dispose(); }

  Future<void> _saveProgress() async {
    final item = _activeItem;
    final uid = _uid;
    final controller = _controller;
    if (item == null || uid == null || controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    if ((position - _lastSavedPosition).abs() < const Duration(seconds: 5) && position != controller.value.duration) return;
    _lastSavedPosition = position;
    final duration = controller.value.duration;
    final completed = duration > Duration.zero &&
        position >= Duration(milliseconds: (duration.inMilliseconds * 0.95).round());
    final repo = EntertainmentRepository();
    await repo.saveWatchProgress(uid, item, position, duration);
    await repo.recordWatchProgress(
      uid,
      item,
      seconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
      completed: completed,
    );
  }

  Future<void> _openPlayer(String url, AurenEntertainmentItem item, {Duration? resume}) async {
    if (url.isEmpty || _starting) return;
    setState(() => _starting = true);
    try {
      await _controller?.dispose();
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) { await controller.dispose(); return; }
      _activeItem = item;
      if (resume != null && resume > Duration.zero) await controller.seekTo(resume);
      final uid = _uid;
      if (uid != null) {
        await EntertainmentRepository().recordWatchStarted(uid, item);
      }
      setState(() { _controller = controller; _starting = false; _lastSavedPosition = Duration.zero; });
      controller.addListener(() { if (mounted) _saveProgress(); });
      await controller.play();
    } catch (_) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تشغيل هذا المحتوى حالياً.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _uid = uid;
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Entertainment')),
      body: StreamBuilder<AurenEntertainmentItem?>(
        stream: repo.watchItem(widget.itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final item = snapshot.data;
          if (item == null) return const Center(child: Text('هذا المحتوى غير متاح حالياً.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),
                      IconButton.filled(onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()),
                        icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 34)),
                    ],
                  )),
                )
              else if (item.imageUrl.isNotEmpty)
                ClipRRect(borderRadius: BorderRadius.circular(20), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(item.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Center(child: Icon(Icons.broken_image_outlined, size: 48)))) )
              else
                Container(height: 210, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xff4527a0), Color(0xff1565c0), Color(0xffad1457)])), child: const Center(child: Icon(Icons.play_circle_outline, size: 72))),
              if (item.isVideo && item.mediaUrl.isNotEmpty && (_controller == null || !_controller!.value.isInitialized)) ...[
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: uid == null ? Future.value(null) : repo.getWatchProgress(uid, item.id),
                  builder: (context, progressSnapshot) {
                    final data = progressSnapshot.data;
                    final seconds = (data?['positionSeconds'] as num?)?.toInt() ?? 0;
                    final progress = ((data?['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
                    final hasResume = seconds >= 5 && progress > 0 && progress < 1;
                    final resume = Duration(seconds: seconds);
                    return FilledButton.icon(
                      onPressed: _starting ? null : () => _openPlayer(item.mediaUrl, item, resume: hasResume ? resume : null),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_starting
                          ? 'جاري التحميل…'
                          : hasResume ? 'متابعة من ${(progress * 100).round()}%' : 'تشغيل'),
                    );
                  },
                ),
              ],
              if (_controller != null && _controller!.value.isInitialized)
                VideoProgressIndicator(_controller!, allowScrubbing: true, padding: const EdgeInsets.symmetric(vertical: 10)),
              const SizedBox(height: 18),
              Text(item.type.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'أريد معرفة المزيد عن ' + item.title + '، واقترح لي محتوى مشابهًا له.'))),
                icon: const Icon(Icons.auto_awesome), label: const Text('اسأل AUREN عنه'),
              ),
              if (uid != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => repo.save(uid, item.id), icon: const Icon(Icons.bookmark_add_outlined), label: const Text('حفظ للمشاهدة لاحقاً')),
              ],
            ],
          );
        },
      ),
    );
  }
}