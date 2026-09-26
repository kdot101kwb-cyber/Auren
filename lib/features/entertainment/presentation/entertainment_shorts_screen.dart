import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';

/// Entertainment-first Shorts: users can simply relax, with AUREN intelligence optional.
class AurenEntertainmentShortsScreen extends StatefulWidget {
  const AurenEntertainmentShortsScreen({super.key});
  @override
  State<AurenEntertainmentShortsScreen> createState() => _AurenEntertainmentShortsState();
}

class _AurenEntertainmentShortsState extends State<AurenEntertainmentShortsScreen> {
  final repo = EntertainmentRepository();
  final controllers = <String, VideoPlayerController>{};
  int active = 0;
  String? uid;
  String mood = 'تسلية';
  bool pureEntertainment = true;
  final Map<String, DateTime> _startedAt = {};
  final Set<String> _tracked = {};

  static const moods = <String>['تسلية', 'ضحك', 'موسيقى', 'أفلام', 'Gaming', 'اكتشاف'];

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _prepare(AurenEntertainmentItem item) async {
    if (controllers.containsKey(item.id) || item.mediaUrl.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(item.mediaUrl));
    try {
      await c.initialize();
      c.setLooping(true);
      controllers[item.id] = c;
      if (mounted) {
        setState(() {});
        if (active == 0) c.play();
      }
    } catch (_) {
      await c.dispose();
    }
  }

  Future<void> _trackView(AurenEntertainmentItem item, {bool completed = false}) async {
    if (uid == null || _tracked.contains(item.id)) return;
    final started = _startedAt[item.id];
    final seconds = started == null ? 0 : DateTime.now().difference(started).inSeconds;
    _tracked.add(item.id);
    await repo.trackShortView(uid!, item.id, seconds: seconds, completed: completed, mood: mood);
  }

  void _onPage(int index, List<AurenEntertainmentItem> items) {
    if (active < items.length) _trackView(items[active]);
    for (final c in controllers.values) c.pause();
    setState(() => active = index);
    _startedAt[items[index].id] = DateTime.now();
    _prepare(items[index]).then((_) => controllers[items[index].id]?.play());
    if (index + 1 < items.length) _prepare(items[index + 1]);
  }

  void _showMoods() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17131F),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('شنو مزاجك الآن؟',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تسلية فقط'),
                subtitle: const Text('بدون اقتراحات عمل أو فرص أو AI أثناء المشاهدة'),
                value: pureEntertainment,
                onChanged: (value) => setState(() => pureEntertainment = value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moods.map((value) => ChoiceChip(
                  label: Text(value),
                  selected: value == mood,
                  onSelected: (_) {
                    setState(() => mood = value);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAurenActions(AurenEntertainmentItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17131F),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('كمل التسلية'),
              subtitle: const Text('أقفل القائمة وخليك في الـShorts'),
              onTap: () => Navigator.pop(sheetContext),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('اسأل AUREN AI'),
              subtitle: Text('عن "${item.title}"'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('AUREN AI جاهز — ربط المحادثة العامة يأتي من هنا.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('استكشف مثل هذا'),
              subtitle: const Text('محتوى وأشخاص ومواضيع مرتبطة'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('AUREN سيبني اكتشافاً مرتبطاً بهذا المحتوى.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt_outlined),
              title: const Text('Match Me'),
              subtitle: const Text('اختياري — حوّل المحتوى إلى اهتمام أو فرصة'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Match Me اختياري ولن يزعج وضع التسلية.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(pureEntertainment ? 'AUREN Shorts • تسلية' : 'AUREN Shorts'),
        actions: [
          IconButton(
            tooltip: 'مزاجي',
            icon: const Icon(Icons.tune),
            onPressed: _showMoods,
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: uid == null ? repo.watchShorts(mood: mood) : repo.watchPersonalizedShorts(uid!, mood: mood),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد Shorts متاحة حالياً.'));
          }

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
                      onTap: () => setState(() =>
                          c.value.isPlaying ? c.pause() : c.play()),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  Positioned(
                    left: 0, right: 0, bottom: 0, height: 190,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 16, right: 78, bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 10),
                        if (!pureEntertainment)
                          GestureDetector(
                          onTap: () => _showAurenActions(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white12,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 16),
                                SizedBox(width: 6),
                                Text('AUREN • المزيد'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    right: 10, bottom: 26,
                    child: Column(
                      children: [
                        if (uid != null)
                          StreamBuilder<bool>(
                            stream: repo.watchLiked(uid!, item.id),
                            builder: (context, s) => IconButton(
                              color: s.data == true ? Colors.redAccent : Colors.white,
                              iconSize: 34,
                              icon: Icon(s.data == true ? Icons.favorite : Icons.favorite_border),
                              onPressed: () async {
                                final next = !(s.data == true);
                                await repo.toggleShortLike(uid!, item.id, next);
                                await repo.trackShortAction(uid!, item.id, action: next ? 'like' : 'unlike', mood: mood);
                              },
                              /* onPressed: () => repo.toggleShortLike(
                                uid!, item.id, !(s.data == true)), */
                            ),
                          ),
                        if (uid != null)
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 32),
                            onPressed: () => repo.save(uid!, item.id),
                          ),
                        if (!pureEntertainment)
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                            tooltip: 'AUREN',
                            onPressed: () => _showAurenActions(item),
                          ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 30),
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('المشاركة العامة ستتصل بنظام AUREN Share.')),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 14, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mood, size: 15),
                          const SizedBox(width: 5),
                          Text(mood),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
