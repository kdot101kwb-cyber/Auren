import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'watch_together_screen.dart';

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

  Future<void> _toggleSave(String uid, String itemId, bool saved) async {
    if (saved) {
      await EntertainmentRepository().unsave(uid, itemId);
    } else {
      await EntertainmentRepository().save(uid, itemId);
    }
  }

  Future<void> _showCommentComposer(String uid, String itemId) async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Row(children: [
          Expanded(child: TextField(controller: controller, autofocus: true, maxLength: 1000,
            decoration: const InputDecoration(hintText: 'اكتب تعليقك…', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: () => Navigator.pop(context, controller.text.trim()), icon: const Icon(Icons.send_rounded)),
        ]),
      ),
    );
    controller.dispose();
    if (text != null && text.isNotEmpty) {
      await EntertainmentRepository().addShortComment(uid, itemId, text);
    }
  }

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
    final uri = Uri.tryParse(url);
    final isWebMedia = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    if (!isWebMedia || _starting) return;
    setState(() => _starting = true);
    try {
      await _controller?.dispose();
      final controller = VideoPlayerController.networkUrl(uri);
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
          final isCatalogOnly = item.isCatalogOnly;
          final hasPlayableMedia = item.hasPlayableMedia;
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
              if (hasPlayableMedia && (_controller == null || !_controller!.value.isInitialized)) ...[
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
              if (item.type == 'Movie' || item.type == 'Global Series') ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (item.country.isNotEmpty) Chip(label: Text(item.country)),
                  if (item.language.isNotEmpty) Chip(label: Text(item.language)),
                  if (item.year.isNotEmpty) Chip(label: Text(item.year)),
                  if (item.type == 'Global Series' && item.seasons > 0) Chip(label: Text('${item.seasons} موسم')),
                  if (item.type == 'Global Series' && item.episodes > 0) Chip(label: Text('${item.episodes} حلقة')),
                  ...item.genres.map((g) => Chip(label: Text(g))),
                ]),
              ],
              const SizedBox(height: 6),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
              if (item.type == 'Global Series' && (item.source.isNotEmpty || item.isCatalogOnly || item.licenseNote.isNotEmpty || item.sourceUrl.isNotEmpty)) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 8),
                          Text('معلومات الكتالوج', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        if (isCatalogOnly && !hasPlayableMedia)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Expanded(child: Text('بيانات كتالوج فقط — لا يتم استضافة الحلقات هنا.')),
                              ],
                            ),
                          ),
                        if (item.mediaUrl.isEmpty) const SizedBox(height: 8),
                        if (isCatalogOnly || item.source.isNotEmpty) Text('المصدر: ${item.source}'),
                        if (item.licenseNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item.licenseNote, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (item.hasExternalSource) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.tryParse(item.sourceUrl);
                              final isWebSource = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
                              if (isWebSource && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('رابط المصدر غير صالح حالياً.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('فتح المصدر'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (item.type == 'Movie' && item.trailerUrl.isNotEmpty && item.trailerUrl != item.mediaUrl) ...[
                OutlinedButton.icon(
                  onPressed: _starting ? null : () => _openPlayer(item.trailerUrl, item),
                  icon: const Icon(Icons.movie_filter_outlined),
                  label: const Text('شاهد الـ Trailer'),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              Row(children: [
                StreamBuilder<bool>(
                  stream: uid == null ? const Stream<bool>.empty() : repo.watchLiked(uid, item.id),
                  builder: (context, likeSnapshot) {
                    final liked = likeSnapshot.data ?? false;
                    return IconButton.filledTonal(
                      tooltip: liked ? 'إلغاء الإعجاب' : 'إعجاب',
                      onPressed: uid == null ? null : () => repo.toggleLike(uid, item.id, !liked),
                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (uid != null)
                  StreamBuilder<Set<String>>(
                    stream: repo.watchSavedIds(uid),
                    builder: (context, savedSnapshot) {
                      final saved = savedSnapshot.data?.contains(item.id) ?? false;
                      return IconButton.filledTonal(
                        tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ',
                        onPressed: () => _toggleSave(uid, item.id, saved),
                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                      );
                    },
                  ),
                const SizedBox(width: 8),
                if (uid != null)
                  OutlinedButton.icon(onPressed: () => _showCommentComposer(uid, item.id), icon: const Icon(Icons.comment_outlined), label: const Text('تعليق')),
              ]),
              const SizedBox(height: 16),
              if (item.creatorId.isNotEmpty) ...[
                Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: const Text('منشئ المحتوى'),
                  subtitle: Text(item.creatorId, maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              const Text('التعليقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: repo.watchShortComments(item.id),
                builder: (context, commentSnapshot) {
                  if (commentSnapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                  final comments = commentSnapshot.data ?? const [];
                  if (comments.isEmpty) return const Text('لسه ما في تعليقات. كن أول من يعلّق.');
                  return Column(children: comments.take(20).map<Widget>((comment) {
                    final data = comment.data() as Map<String, dynamic>;
                    return Card(child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(data['uid']?.toString() ?? 'مستخدم'),
                      subtitle: Text(data['text']?.toString() ?? ''),
                    ));
                  }).toList());
                },
              ),
              if (item.type == 'Movie') ...[
                const SizedBox(height: 22),
                const Text('أفلام مشابهة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                StreamBuilder<List<AurenEntertainmentItem>>(
                  stream: repo.watchItems(type: 'Movie'),
                  builder: (context, recSnapshot) {
                    final sourceGenres = item.genres.map((g) => g.toLowerCase()).toSet();
                    final recommendations = (recSnapshot.data ?? const <AurenEntertainmentItem>[])
                        .where((x) => x.id != item.id)
                        .map((x) => MapEntry(x, x.genres.map((g) => g.toLowerCase()).toSet().intersection(sourceGenres).length))
                        .where((x) => sourceGenres.isEmpty || x.value > 0)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    return Column(children: recommendations.take(6).map((entry) {
                      final x = entry.key;
                      return Card(child: ListTile(
                        leading: x.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.movie)) : CircleAvatar(backgroundImage: NetworkImage(x.imageUrl)),
                        title: Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text([x.year, x.country].where((v) => v.isNotEmpty).join(' • ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: x.id))),
                      ));
                    }).toList());
                  },
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'أريد معرفة المزيد عن ' + item.title + '، واقترح لي محتوى مشابهًا له.'))),
                icon: const Icon(Icons.auto_awesome), label: const Text('اسأل AUREN عنه'),
              ),
              if (hasPlayableMedia) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenWatchTogetherScreen(title: item.title, mediaUrl: item.mediaUrl, mediaId: item.id))),
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('شاهد مع الأصدقاء'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}