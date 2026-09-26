import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';

class AurenEntertainmentShortsScreen extends StatefulWidget {
  const AurenEntertainmentShortsScreen({super.key});
  @override State<AurenEntertainmentShortsScreen> createState() => _AurenEntertainmentShortsState();
}

class _AurenEntertainmentShortsState extends State<AurenEntertainmentShortsScreen> {
  final repo = EntertainmentRepository();
  final controllers = <String, VideoPlayerController>{};
  int active = 0;
  String? uid;

  @override
  void initState() { super.initState(); uid = FirebaseAuth.instance.currentUser?.uid; }

  Future<void> _prepare(AurenEntertainmentItem item) async {
    if (controllers.containsKey(item.id)) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(item.mediaUrl));
    try {
      await c.initialize();
      c.setLooping(true);
      controllers[item.id] = c;
      if (mounted && controllers[item.id] == c) { setState(() {}); if (active == 0) c.play(); }
    } catch (_) { await c.dispose(); }
  }

  void _onPage(int index, List<AurenEntertainmentItem> items) {
    for (final c in controllers.values) { c.pause(); }
    setState(() => active = index);
    _prepare(items[index]).then((_) => controllers[items[index].id]?.play());
    if (index + 1 < items.length) _prepare(items[index + 1]);
  }

  @override
  void dispose() { for (final c in controllers.values) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('AUREN Shorts')),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchShorts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (items.isEmpty) return const Center(child: Text('لا توجد Shorts متاحة حالياً.'));
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            onPageChanged: (i) => _onPage(i, items),
            itemBuilder: (context, index) {
              final item = items[index];
              _prepare(item);
              final c = controllers[item.id];
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (c != null && c.value.isInitialized)
                    GestureDetector(
                      onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                      child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c))),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  Positioned(left: 16, right: 80, bottom: 30, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (item.description.isNotEmpty) ...[const SizedBox(height: 6), Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis)],
                  ])),
                  Positioned(right: 12, bottom: 28, child: Column(children: [
                    if (uid != null) StreamBuilder<bool>(
                      stream: repo.watchLiked(uid!, item.id),
                      builder: (context, s) => IconButton(
                        color: s.data == true ? Colors.redAccent : Colors.white,
                        iconSize: 34,
                        icon: Icon(s.data == true ? Icons.favorite : Icons.favorite_border),
                        onPressed: () => repo.toggleShortLike(uid!, item.id, !(s.data == true)),
                      ),
                    ),
                    if (uid != null) IconButton(icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 32), onPressed: () => repo.save(uid!, item.id)),
                    IconButton(icon: const Icon(Icons.share, color: Colors.white, size: 32), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مشاركة Shorts ستتصل بنظام المشاركة العام في الدفعة القادمة.')))),
                  ])),
                ],
              );
            },
          );
        },
      ),
    );
  }
}