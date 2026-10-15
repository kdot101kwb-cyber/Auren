import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../talent/presentation/talent_screen.dart';
import '../../../services/social/follow_repository.dart';
import '../../../services/social/safety_repository.dart';
import '../../../services/users/user_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../social/presentation/safety_actions_sheet.dart';

/// Entertainment-first Shorts: users can simply relax, with AUREN intelligence optional.
class AurenEntertainmentShortsScreen extends StatefulWidget {
  const AurenEntertainmentShortsScreen({super.key});
  @override
  State<AurenEntertainmentShortsScreen> createState() => _AurenEntertainmentShortsState();
}

class _AurenEntertainmentShortsState extends State<AurenEntertainmentShortsScreen> {
  final repo = EntertainmentRepository();
  final controllers = <String, VideoPlayerController>{};
  final Set<String> _preparing = {};
  final Set<String> _retainedControllerIds = {};
  String? _activeItemId;
  int active = 0;
  String? uid;
  String mood = 'تسلية';
  String shortCategory = 'الكل';
  bool pureEntertainment = true;
  bool _dataSaverMode = false;
  final Map<String, String> _qualityUrls = {};
  final Map<String, int> _playbackGeneration = {};
  final Map<String, AurenEntertainmentItem> _itemsById = {};
  final Map<String, DateTime> _startedAt = {};
  final follows = FollowRepository();
  final Set<String> _tracked = {};
  Stream<Set<String>>? _savedStream;

  static const moods = <String>['تسلية', 'ضحك', 'موسيقى', 'أفلام', 'Gaming', 'اكتشاف'];
  static const shortCategories = <String>['حسب مزاجي', 'الكل', 'كرتون', 'كوميديا', 'فلوقات', 'موسيقى', 'ألعاب'];

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _savedStream = repo.watchSavedIds(uid!);
  }

  String _effectiveVideoUrl(AurenEntertainmentItem item) {
    final lowUrl = item.mediaUrlLow.trim();
    if (_dataSaverMode && lowUrl.isNotEmpty) return lowUrl;
    return _qualityUrls[item.id] ?? item.mediaUrl;
  }

  Future<void> _prepare(AurenEntertainmentItem item) async {
    final selectedUrl = _effectiveVideoUrl(item);
    if (controllers.containsKey(item.id) ||
        _preparing.contains(item.id) ||
        selectedUrl.trim().isEmpty) {
      return;
    }
    _preparing.add(item.id);
    final generation = _playbackGeneration[item.id] ?? 0;
    final c = VideoPlayerController.networkUrl(Uri.parse(selectedUrl));
    try {
      await c.initialize();
      if (!mounted || !_retainedControllerIds.contains(item.id) || generation != (_playbackGeneration[item.id] ?? 0) || selectedUrl != _effectiveVideoUrl(item)) {
        await c.dispose();
        return;
      }
      c.setLooping(true);
      controllers[item.id] = c;
      setState(() {});
      // Only the currently visible short may start playback. Prefetching the next
      // item must never start audio/video behind the active page.
      if (_activeItemId == item.id) {
        await c.play();
      }
    } catch (_) {
      await c.dispose();
    } finally {
      _preparing.remove(item.id);
    }
  }

  Future<void> _trackView(AurenEntertainmentItem item, {bool completed = false}) async {
    if (uid == null || _tracked.contains(item.id)) return;
    final started = _startedAt[item.id];
    final controller = controllers[item.id];
    final naturallyCompleted = controller != null && controller.value.isInitialized && controller.value.duration.inMilliseconds > 0 &&
        controller.value.position.inMilliseconds >= (controller.value.duration.inMilliseconds * 0.9).round();
    final seconds = started == null ? 0 : DateTime.now().difference(started).inSeconds;
    _tracked.add(item.id);
    await repo.trackShortView(uid!, item.id, seconds: seconds, completed: completed || naturallyCompleted, mood: mood);
    if (seconds < 3) {
      await repo.trackShortAction(uid!, item.id, action: 'skip', mood: mood);
    }
  }

  void _retainControllersFor(int index, List<AurenEntertainmentItem> items) {
    final keep = <String>{items[index].id};
    if (!_dataSaverMode && index + 1 < items.length) keep.add(items[index + 1].id);
    _retainedControllerIds
      ..clear()
      ..addAll(keep);

    // Keep at most the visible Short and its next item initialized. This bounds
    // decoder/memory use on lower-end Android devices while preserving prefetch.
    for (final id in controllers.keys.toList()) {
      if (keep.contains(id)) continue;
      final controller = controllers.remove(id)!;
      controller.pause();
      controller.dispose();
    }
  }

  void _onPage(int index, List<AurenEntertainmentItem> items) {
    if (active < items.length) _trackView(items[active]);
    for (final c in controllers.values) {
      c.pause();
    }
    final nextItem = items[index];
    _retainControllersFor(index, items);
    setState(() {
      active = index;
      _activeItemId = nextItem.id;
    });
    _startedAt[nextItem.id] = DateTime.now();
    _prepare(nextItem).then((_) {
      if (mounted && _activeItemId == nextItem.id) {
        controllers[nextItem.id]?.play();
      }
    });
    if (!_dataSaverMode && index + 1 < items.length) _prepare(items[index + 1]);
  }

  Future<void> _showVideoQuality(AurenEntertainmentItem item) async {
    final choices = <(String, String)>[
      ('توفير البيانات', item.mediaUrlLow), ('متوسطة', item.mediaUrlMedium),
      ('عالية', item.mediaUrlHigh), ('الأصلية', item.mediaUrl),
    ].where((choice) {
      final uri = Uri.tryParse(choice.$2.trim());
      return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    }).toList();
    if (choices.length < 2 || !mounted) return;
    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(leading: Icon(Icons.high_quality_outlined), title: Text('جودة الفيديو'), subtitle: Text('الخيارات المتاحة لهذا الفيديو')),
        for (final choice in choices) ListTile(
          leading: Icon((_qualityUrls[item.id] ?? item.mediaUrl) == choice.$2 ? Icons.radio_button_checked : Icons.radio_button_off),
          title: Text(choice.$1),
          onTap: () {
            Navigator.pop(sheetContext);
            if ((_qualityUrls[item.id] ?? item.mediaUrl) == choice.$2) return;
            _qualityUrls[item.id] = choice.$2;
            final old = controllers.remove(item.id);
            if (old != null) { old.pause(); old.dispose(); }
            _prepare(item);
          },
        ),
      ])));
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
                title: const Text('توفير البيانات'),
                subtitle: const Text('إيقاف تجهيز الشورت التالي مسبقاً لتقليل استهلاك الإنترنت والذاكرة'),
                value: _dataSaverMode,
                onChanged: (value) {
                  final keepId = _activeItemId;
                  setState(() => _dataSaverMode = value);
                  if (value) {
                    for (final id in controllers.keys.toList()) {
                      if (id == keepId) continue;
                      final controller = controllers.remove(id)!;
                      controller.pause();
                      controller.dispose();
                    }
                    _retainedControllerIds
                      ..clear()
                      ..addAll(keepId == null ? const <String>{} : <String>{keepId});
                  }
                  final activeItem = keepId == null ? null : _itemsById[keepId];
                  if (activeItem != null) {
                    final controller = controllers.remove(activeItem.id);
                    if (controller != null) {
                      controller.pause();
                      controller.dispose();
                    }
                    _prepare(activeItem);
                  }
                },
              ),
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

  void _openAi(AurenEntertainmentItem item) => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'حلّل لي هذا الـShort: '+item.title+'. '+item.description)));

  void _exploreLike(AurenEntertainmentItem item) => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenGlobalSearchScreen(initialQuery: item.title)));

  void _matchMe(AurenEntertainmentItem item) => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTalentScreen()));

  String? _creatorId(AurenEntertainmentItem item) => item.creatorId.isEmpty ? null : item.creatorId;

  Future<void> _shareItem(AurenEntertainmentItem item) async {
    if (uid != null) await repo.trackShortAction(uid!, item.id, action: 'share', mood: mood);
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.link), title: const Text('نسخ رابط المحتوى'), onTap: () async { await Clipboard.setData(ClipboardData(text: item.mediaUrl)); if (sheet.mounted) Navigator.pop(sheet); }),
      ListTile(leading: const Icon(Icons.send_outlined), title: const Text('مشاركة داخل AUREN'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'أريد مشاركة هذا المحتوى داخل AUREN: '+item.title+'\n'+item.mediaUrl))); }),
    ])));
  }

  void _showCreator(AurenEntertainmentItem item) {
    final creatorId = _creatorId(item);
    if (creatorId == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AurenProfileScreen(userId: creatorId)));
  }

  void _showComments(AurenEntertainmentItem item) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('التعليقات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: repo.watchShortComments(item.id),
                  builder: (context, snapshot) {
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) return const Center(child: Text('كن أول من يعلّق 👋'));
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final d = comments[i].data();
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(d['uid']?.toString() ?? 'AUREN User'),
                          subtitle: Text(d['text']?.toString() ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),
              if (uid != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(
                    children: [
                      Expanded(child: TextField(
                        controller: controller,
                        maxLength: 1000,
                        decoration: const InputDecoration(hintText: 'اكتب تعليقاً...', border: OutlineInputBorder()),
                      )),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          await repo.addShortComment(uid!, item.id, controller.text, mood: mood);
                          controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _showAurenActions(AurenEntertainmentItem item) {
    showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF17131F), builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.play_circle_outline), title: const Text('كمل التسلية'), onTap: () => Navigator.pop(sheetContext)),
      ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('اسأل AUREN AI'), subtitle: Text('عن "'+item.title+'"'), onTap: () { Navigator.pop(sheetContext); _openAi(item); }),
      ListTile(leading: const Icon(Icons.explore_outlined), title: const Text('استكشف مثل هذا'), subtitle: const Text('محتوى وأشخاص ومواضيع مرتبطة'), onTap: () { Navigator.pop(sheetContext); _exploreLike(item); }),
      ListTile(leading: const Icon(Icons.bolt_outlined), title: const Text('Match Me'), subtitle: const Text('اختياري — حوّل المحتوى إلى اهتمام أو فرصة'), onTap: () { Navigator.pop(sheetContext); _matchMe(item); }),
    ])));
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
      body: uid == null
          ? StreamBuilder<List<AurenEntertainmentItem>>(
              stream: repo.watchShorts(mood: mood),
              builder: (context, snapshot) => _buildShortsBody(
                context,
                snapshot.data ?? const <AurenEntertainmentItem>[],
                snapshot.connectionState,
                snapshot.hasError ? snapshot.error : null,
              ),
            )
          : StreamBuilder<Set<String>>(
              stream: AurenSafetyRepository().watchBlockedIds(uid!),
              builder: (context, blockedSnapshot) {
                final blockedIds = blockedSnapshot.data ?? const <String>{};
                return StreamBuilder<List<AurenEntertainmentItem>>(
                  stream: repo.watchPersonalizedShorts(
                    uid!,
                    mood: mood,
                    blockedCreatorIds: blockedIds,
                  ),
                  builder: (context, snapshot) => _buildShortsBody(
                    context,
                    snapshot.data ?? const <AurenEntertainmentItem>[],
                    snapshot.connectionState,
                    snapshot.hasError ? snapshot.error : null,
                  ),
                );
              },
            ),
    );
  }

  bool _matchesCategory(AurenEntertainmentItem item) {
    // The personalized stream is already ranked using the viewer's selected mood.
    // This tab intentionally avoids a fixed country/dialect category.
    if (shortCategory == 'الكل' || shortCategory == 'حسب مزاجي') return true;
    // Prefer publisher-supplied taxonomy, while keeping legacy title/description
    // matching as a fallback for older catalog entries.
    final haystack = '${item.category} ${item.tags.join(' ')} ${item.type} ${item.title} ${item.description} ${item.genres.join(' ')} ${item.language} ${item.country}'.toLowerCase();
    final keywords = switch (shortCategory) {
      'كرتون' => ['كرتون', 'رسوم متحركة', 'انيميشن', 'أنيميشن', 'animation', 'animated', 'cartoon', 'toon'],
      'كوميديا' => ['ضحك', 'كوميديا', 'مضحك', 'نكت', 'funny', 'comedy', 'humor'],
      'فلوقات' => ['فلوق', 'يومياتي', 'vlog', 'daily life'],
      'موسيقى' => ['موسيقى', 'اغنية', 'أغنية', 'music', 'song', 'singing'],
      'ألعاب' => ['ألعاب', 'لعبة', 'قيم', 'gaming', 'game', 'gameplay'],
      _ => const <String>[],
    };
    return keywords.any(haystack.contains);
  }

  void _changeShortCategory(String value) {
    if (value == shortCategory) return;
    _retainedControllerIds.clear();
    for (final controller in controllers.values) {
      controller.pause();
      controller.dispose();
    }
    controllers.clear();
    setState(() {
      shortCategory = value;
      active = 0;
      _activeItemId = null;
    });
  }

  Widget _buildShortsBody(
    BuildContext context,
    List<AurenEntertainmentItem> items,
    ConnectionState connectionState,
    Object? error,
  ) {
    if (connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Could not load Shorts: $error'));
    }
    for (final item in items) {
      _itemsById[item.id] = item;
    }
    final visibleItems = items.where(_matchesCategory).toList();

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: shortCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = shortCategories[index];
              return ChoiceChip(
                label: Text(category),
                selected: shortCategory == category,
                onSelected: (_) => _changeShortCategory(category),
              );
            },
          ),
        ),
        Expanded(
          child: visibleItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.video_library_outlined, size: 44),
                        const SizedBox(height: 12),
                        Text(shortCategory == 'الكل' || shortCategory == 'حسب مزاجي'
                            ? 'لا توجد Shorts متاحة حالياً.'
                            : 'ما لقينا شورتات في تصنيف "$shortCategory" حالياً.'),
                        const SizedBox(height: 12),
                        const Text('جرّب تصنيفاً آخر أو ارجع إلى الكل.'),
                        if (shortCategory != 'الكل')
                          TextButton.icon(
                            onPressed: () => _changeShortCategory('الكل'),
                            icon: const Icon(Icons.grid_view),
                            label: const Text('عرض كل الشورتات'),
                          ),
                      ],
                    ),
                  ),
                )
              : PageView.builder(
                  // Recreate the pager when the category changes so its internal
                  // page position cannot point at an item from the previous feed.
                  key: ValueKey<String>('shorts-$shortCategory'),
                  scrollDirection: Axis.vertical,
                  itemCount: visibleItems.length,
                  onPageChanged: (i) => _onPage(i, visibleItems),
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    if (index == active && _activeItemId == null) {
                      _activeItemId = item.id;
                    }
                    if (index == active) {
                      _retainControllersFor(index, visibleItems);
                      _prepare(item);
                    } else if (!_dataSaverMode && index == active + 1) {
                      _retainedControllerIds.add(item.id);
                      _prepare(item);
                    }
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

                  if (_creatorId(item) != null)
                    Positioned(
                      left: 16, right: 78, top: 62,
                      child: StreamBuilder(
                        stream: UserRepository().watch(_creatorId(item)!),
                        builder: (context, s) {
                          final name = s.hasData ? s.data!.displayName : 'Creator';
                          final me = uid;
                          if (me == _creatorId(item)) return const SizedBox.shrink();
                          return Row(children: [
                            InkWell(onTap: () => _showCreator(item), child: const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20))),
                            const SizedBox(width: 8),
                            Flexible(child: InkWell(onTap: () => _showCreator(item), child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)))),
                            const SizedBox(width: 10),
                            StreamBuilder<bool>(
                              stream: follows.watchFollowing(me ?? '', _creatorId(item)!),
                              builder: (context, f) => OutlinedButton.icon(
                                onPressed: me == null ? null : () => follows.toggle(me, _creatorId(item)!, f.data == true),
                                icon: Icon(f.data == true ? Icons.check : Icons.person_add, size: 16),
                                label: Text(f.data == true ? 'Following' : 'Follow'),
                              ),
                            ),
                          ]);
                        },
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
                    right: 10, top: 58,
                    child: _creatorId(item) != null && uid != null
                        ? IconButton(
                            tooltip: 'Safety',
                            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                            onPressed: () => AurenSafetyActionsSheet.show(
                              context,
                              uid: uid!,
                              targetUid: _creatorId(item)!,
                              contentId: item.id,
                              contentType: 'short',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  Positioned(
                    right: 10, bottom: 26,
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'التعليقات',
                          icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 30),
                          onPressed: () => _showComments(item),
                        ),
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
                                                          ),
                          ),
                        if (uid != null)
                          StreamBuilder<Set<String>>(
                            stream: _savedStream,
                            builder: (context, saved) {
                              final isSaved = saved.data?.contains(item.id) == true;
                              return IconButton(
                                tooltip: isSaved ? 'إزالة الحفظ' : 'حفظ',
                                icon: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: () async {
                                  if (isSaved) {
                                    await repo.unsave(uid!, item.id);
                                    await repo.trackShortAction(uid!, item.id, action: 'unsave', mood: mood);
                                  } else {
                                    await repo.save(uid!, item.id);
                                    await repo.trackShortAction(uid!, item.id, action: 'save', mood: mood);
                                  }
                                },
                              );
                            },
                          ),
                        if (!pureEntertainment)
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                            tooltip: 'AUREN',
                            onPressed: () => _showAurenActions(item),
                          ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 30),
                          onPressed: () => _shareItem(item),
                        ),
                      ],
                    ),
                  ),

                  if ([item.mediaUrlLow, item.mediaUrlMedium, item.mediaUrlHigh].where((url) => url.trim().isNotEmpty).length > 0)
                    Positioned(top: 8, right: 8, child: IconButton(
                      tooltip: 'جودة الفيديو',
                      icon: const Icon(Icons.high_quality_outlined, color: Colors.white),
                      onPressed: () => _showVideoQuality(item),
                    )),
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
          ),
        ),
      ],
    );
  }
}
