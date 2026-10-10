import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// First local-only video capture step for Music & Performance Lab.
/// The platform camera UI handles recording; clips are copied into app storage.
class AurenMusicVideoCaptureScreen extends StatefulWidget {
  const AurenMusicVideoCaptureScreen({super.key});

  @override
  State<AurenMusicVideoCaptureScreen> createState() =>
      _AurenMusicVideoCaptureScreenState();
}

class _AurenMusicVideoCaptureScreenState
    extends State<AurenMusicVideoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _player;
  String? _savedPath;
  String? _error;
  bool _capturing = false;
  bool _saving = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _captureVideo() async {
    if (_capturing || _saving) return;
    setState(() {
      _capturing = true;
      _error = null;
    });

    try {
      final captured = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      if (captured == null) return;

      setState(() => _saving = true);
      final directory = await getApplicationDocumentsDirectory();
      final destination = File(
        '${directory.path}/auren_performance_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await File(captured.path).copy(destination.path);

      await _player?.dispose();
      final player = VideoPlayerController.file(destination);
      await player.initialize();
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _savedPath = destination.path;
        _player = player;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تسجيل الفيديو أو حفظه. تحقّق من إذن الكاميرا والمساحة المتاحة ثم حاول مجددًا.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteVideo() async {
    final path = _savedPath;
    await _player?.dispose();
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'تعذّر حذف الملف المحلي.');
          return;
        }
      }
    }
    if (mounted) {
      setState(() {
        _player = null;
        _savedPath = null;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final ready = player != null && player.value.isInitialized;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الأداء بالفيديو')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.videocam_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'سجّل الغناء أو العزف وراجع المقطع قبل أن تختار مشاركته.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _capturing || _saving ? null : _captureVideo,
            icon: const Icon(Icons.fiber_manual_record),
            label: Text(
              _capturing
                  ? 'بانتظار الكاميرا…'
                  : _saving
                      ? 'جارٍ حفظ الفيديو…'
                      : _savedPath == null
                          ? 'تسجيل فيديو جديد'
                          : 'إعادة التسجيل',
            ),
          ),
          if (_capturing || _saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (ready) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio,
                child: VideoPlayer(player),
              ),
            ),
            const SizedBox(height: 8),
            VideoProgressIndicator(player, allowScrubbing: true),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                IconButton.filledTonal(
                  tooltip: player.value.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                  onPressed: () async {
                    if (player.value.isPlaying) {
                      await player.pause();
                    } else {
                      await player.play();
                    }
                    if (mounted) setState(() {});
                  },
                  icon: Icon(
                    player.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _deleteVideo,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف المقطع'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'المقطع محفوظ داخل التطبيق على هذا الجهاز فقط. لا يتم رفعه أو نشره تلقائيًا.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
