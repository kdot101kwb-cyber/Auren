import 'dart:async';
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

class _AurenEntertainmentShortsState extends State<AurenEntertainmentShortsScreen> with WidgetsBindingObserver {
  final repo = EntertainmentRepository();
  final controllers = <String, VideoPlayerController>{};
  final Set<String> _preparing = {};
  final Set<String> _failedControllerIds = {};
  bool _resumeAfterLifecycle = false;
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
  final Set<String> _tracking = {};
  Stream<Set<String>>? _savedStream;

  static const moods = <String>['تسلية', 'ضحك', 'موسيقى', 'أفلام', 'Gaming', 'اكتشاف'];
  static const shortCategories = <String>['حسب مزاجي', 'الكل', 'كرتون', 'كوميديا', 'فلوقات', 'موسيقى', 'ألعاب'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _savedStream = repo.watchSavedIds(uid!);
  }

  bool _isHttpVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  String _effectiveVideoUrl(AurenEntertainmentItem item) {
    final lowUrl = item.mediaUrlLow.trim();
    if (_dataSaverMode && _isHttpVideoUrl(lowUrl)) return lowUrl;

    final selectedUrl = _qualityUrls[item.id]?.trim();
    if (selectedUrl != null && _isHttpVideoUrl(selectedUrl)) {
      return selectedUrl;
    }

    // Bad optional quality metadata must not prevent playback when the primary
    // media URL is valid.
    return item.mediaUrl.trim();
  }

  Future<void> _disposeControllerSafely(VideoPlayerController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // Native players can already be released after a platform error.
    }
  }

  Future<void> _pauseControllerSafely(
    VideoPlayerController controller,
  ) async {
    try {
      await controller.pause();
    } catch (_) {
      // A failed native player must not interrupt page/lifecycle changes.
    }
  }

  Future<void> _pauseAndDisposeControllerSafely(
    VideoPlayerController controller,
  ) async {
    await _pauseControllerSafely(controller);
    await _disposeControllerSafely(controller);
  }

  Future<void> _prepare(AurenEntertainmentItem item) async {
    final selectedUrl = _effectiveVideoUrl(item);
    final existingController = controllers[item.id];
    if (existingController != null) {
      // Reuse an already prepared controller and start it only when its page
      // is active. A play failure must not leave a broken controller in the map.
      if (_activeItemId == item.id &&
          existingController.value.isInitialized &&
          !existingController.value.isPlaying) {
        try {
          await existingController.play();
          _failedControllerIds.remove(item.id);
        } catch (_) {
          if (identical(controllers[item.id], existingController)) {
            controllers.remove(item.id);
          }
          _failedControllerIds.add(item.id);
          await _disposeControllerSafely(existingController);
          if (mounted) setState(() {});
        }
      }
      return;
    }
    if (_preparing.contains(item.id)) {
      return;
    }
    final parsedUrl = Uri.tryParse(selectedUrl.trim());
    if (parsedUrl == null ||
        !parsedUrl.hasAuthority ||
        parsedUrl.host.isEmpty ||
        (parsedUrl.scheme != 'https' && parsedUrl.scheme != 'http')) {
      _failedControllerIds.add(item.id);
      if (mounted) setState(() {});
      return;
    }
    _preparing.add(item.id);
    _failedControllerIds.remove(item.id);
    final generation = _playbackGeneration[item.id] ?? 0;
    final c = VideoPlayerController.networkUrl(Uri.parse(selectedUrl));
    try {
      await c.initialize();
      if (!mounted || !_retainedControllerIds.contains(item.id) || generation != (_playbackGeneration[item.id] ?? 0) || selectedUrl != _effectiveVideoUrl(item)) {
        await _disposeControllerSafely(c);
        return;
      }
      await c.setLooping(true);
      controllers[item.id] = c;
      _failedControllerIds.remove(item.id);
      setState(() {});
      // Only the currently visible short may start playback. Prefetching the next
      // item must never start audio/video behind the active page.
      if (_activeItemId == item.id) {
        await c.play();
      }
    } catch (_) {
      // Initialization or playback can fail after the controller was inserted
      // into the map. Remove only this controller so the UI cannot reuse a
      // disposed instance; a later page visit can prepare a fresh one.
      if (identical(controllers[item.id], c)) {
        controllers.remove(item.id);
      }
      _failedControllerIds.add(item.id);
      if (mounted) setState(() {});
      await _disposeControllerSafely(c);
    } finally {
      _preparing.remove(item.id);
      if (mounted &&
          _retainedControllerIds.contains(item.id) &&
          (generation != (_playbackGeneration[item.id] ?? 0) ||
              selectedUrl != _effectiveVideoUrl(item))) {
        _prepare(item);
      }
    }
  }

  Future<void> _togglePlayback(AurenEntertainmentItem item, VideoPlayerController controller) async {
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (_) {
      if (identical(controllers[item.id], controller)) {
        controllers.remove(item.id);
      }
      _failedControllerIds.add(item.id);
      await _disposeControllerSafely(controller);
      if (mounted) setState(() {});
    }
  }

  Future<void> _retryPreparation(AurenEntertainmentItem item) async {
    _playbackGeneration[item.id] = (_playbackGeneration[item.id] ?? 0) + 1;
    _failedControllerIds.remove(item.id);
    final old = controllers.remove(item.id);
    if (old != null) {
      // Cleanup errors should never prevent a retry from starting.
      await _pauseAndDisposeControllerSafely(old);
    }
    if (!mounted) return;
    setState(() {});
    await _prepare(item);
  }

  Future<void> _trackView(AurenEntertainmentItem item, {bool completed = false}) async {
    if (uid == null ||
        _tracked.contains(item.id) ||
        !_tracking.add(item.id)) {
      return;
    }
    final started = _startedAt[item.id];
    final controller = controllers[item.id];
    final viewMood = mood;
    final naturallyCompleted = controller != null && controller.value.isInitialized && controller.value.duration.inMilliseconds > 0 &&
        controller.value.position.inMilliseconds >= (controller.value.duration.inMilliseconds * 0.9).round();
    // Wall-clock time includes pauses, loading delays, and background time.
    // Only report watch duration when the player can provide its real position;
    // otherwise report zero rather than inventing engagement time.
    final seconds = controller != null && controller.value.isInitialized
        ? controller.value.position.inSeconds
        : 0;
    try {
      await repo.trackShortView(
        uid!,
        item.id,
        seconds: seconds,
        completed: completed || naturallyCompleted,
        mood: viewMood,
      );
      _tracked.add(item.id);
      _startedAt.remove(item.id);
      // Bound in-memory view history for long scrolling sessions.
      if (_tracked.length > 500) _tracked.remove(_tracked.first);
      if (seconds < 3) {
        await repo.trackShortAction(
          uid!,
          item.id,
          action: 'skip',
          mood: viewMood,
        );
      }
    } catch (_) {
      // Analytics failures must not break vertical scrolling or playback.
    } finally {
      _tracking.remove(item.id);
    }
  }

  void _retainControllersFor(int index, List<AurenEntertainmentItem> items) {
    final keep = <String>{items[index].id};
    if (!_dataSaverMode && index + 1 < items.length) keep.add(items[index + 1].id);
    _retainedControllerIds
      ..clear()
      ..addAll(keep);

    // Watch timers are only needed for the visible item and its prefetch.
    // Pruning them prevents guest/long-scroll sessions from growing forever.
    for (final id in _startedAt.keys.toList()) {
      if (!keep.contains(id)) _startedAt.remove(id);
    }

    // Keep at most the visible Short and its next item initialized. This bounds
    // decoder/memory use on lower-end Android devices while preserving prefetch.
    for (final id in controllers.keys.toList()) {
      if (keep.contains(id)) continue;
      final controller = controllers.remove(id)!;
      unawaited(_pauseAndDisposeControllerSafely(controller));
    }
  }

  void _onPage(int index, List<AurenEntertainmentItem> items) {
    // A stream refresh can invalidate a PageView callback queued for the old
    // item count. Ignore stale indices rather than indexing outside the feed.
    if (index < 0 || index >= items.length) return;
    // Feed snapshots can reorder or replace items while a page is visible.
    // Track the item that was actually active, not whichever item now occupies
    // the previous numeric index in the refreshed list.
    final previousItem = _activeItemId == null
        ? (active < items.length ? items[active] : null)
        : _itemsById[_activeItemId];
    if (previousItem != null && previousItem.id != items[index].id) {
      unawaited(_trackView(previousItem));
    }
    final nextItem = items[index];
    // Do not race a pause against playback when the next Short was prefetched.
    for (final entry in controllers.entries) {
      if (entry.key == nextItem.id) continue;
      unawaited(_pauseControllerSafely(entry.value));
    }
    _retainControllersFor(index, items);
    setState(() {
      active = index;
      _activeItemId = nextItem.id;
    });
    _startedAt[nextItem.id] = DateTime.now();
    _prepare(nextItem);
    if (!_dataSaverMode && index + 1 < items.length) _prepare(items[index + 1]);
  }

  Future<void> _showVideoQuality(AurenEntertainmentItem item) async {
    final choices = <(String, String)>[
      ('توفير البيانات', item.mediaUrlLow), ('متوسطة', item.mediaUrlMedium),
      ('عالية', item.mediaUrlHigh), ('الأصلية', item.mediaUrl),
    ].map((choice) => (choice.$1, choice.$2.trim())).where((choice) {
      final uri = Uri.tryParse(choice.$2.trim());
      return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    }).toList();
    if (choices.length < 2 || !mounted) return;
    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.high_quality_outlined),
          title: const Text('جودة الفيديو'),
          subtitle: Text(_dataSaverMode &&
                  _isHttpVideoUrl(item.mediaUrlLow)
              ? 'توفير البيانات مفعّل؛ أوقفه لاختيار جودة أعلى'
              : 'الخيارات المتاحة لهذا الفيديو'),
        ),
        for (final choice in choices) ListTile(
          leading: Icon(_effectiveVideoUrl(item) == choice.$2 ? Icons.radio_button_checked : Icons.radio_button_off),
          title: Text(choice.$1),
          enabled: !_dataSaverMode ||
              !_isHttpVideoUrl(item.mediaUrlLow) ||
              choice.$2 == item.mediaUrlLow.trim(),
          onTap: () async {
            if (_dataSaverMode &&
                _isHttpVideoUrl(item.mediaUrlLow) &&
                choice.$2 != item.mediaUrlLow.trim()) return;
            Navigator.pop(sheetContext);
            if ((_qualityUrls[item.id] ?? item.mediaUrl).trim() == choice.$2) return;
            _qualityUrls[item.id] = choice.$2;
            _playbackGeneration[item.id] = (_playbackGeneration[item.id] ?? 0) + 1;
            final old = controllers.remove(item.id);
            if (old != null) {
              try {
                await old.pause();
              } catch (_) {
                // Continue switching quality if the old player has failed.
              }
              await _disposeControllerSafely(old);
            }
            if (!mounted) return;
            await _prepare(item);
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
                onChanged: (value) async {
                  final keepId = _activeItemId;
                  if (keepId != null) {
                    _playbackGeneration[keepId] = (_playbackGeneration[keepId] ?? 0) + 1;
                  }
                  setState(() => _dataSaverMode = value);
                  if (value) {
                    for (final id in controllers.keys.toList()) {
                      if (id == keepId) continue;
                      final controller = controllers.remove(id)!;
                      unawaited(
                        _pauseAndDisposeControllerSafely(controller),
                      );
                    }
                    _retainedControllerIds
                      ..clear()
                      ..addAll(keepId == null ? const <String>{} : <String>{keepId});
                  }
                  final activeItem = keepId == null ? null : _itemsById[keepId];
                  if (activeItem != null) {
                    final controller = controllers.remove(activeItem.id);
                    if (controller != null) {
                      await _pauseAndDisposeControllerSafely(controller);
                    }
                    if (mounted) await _prepare(activeItem);
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

  Future<void> _trackShareAction(AurenEntertainmentItem item) async {
    final viewerId = uid;
    if (viewerId == null) return;
    try {
      await repo.trackShortAction(
        viewerId,
        item.id,
        action: 'share',
        mood: mood,
      );
    } catch (_) {
      // Sharing should remain available if analytics are temporarily offline.
    }
  }

  Future<void> _shareItem(AurenEntertainmentItem item) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.link),
        title: const Text('نسخ رابط المحتوى'),
        onTap: () async {
          try {
            await Clipboard.setData(ClipboardData(text: item.mediaUrl));
            unawaited(_trackShareAction(item));
            if (sheet.mounted) Navigator.pop(sheet);
          } catch (_) {
            if (sheet.mounted) {
              ScaffoldMessenger.of(sheet).showSnackBar(
                const SnackBar(
                  content: Text('تعذّر نسخ الرابط. حاول مرة أخرى.'),
                ),
              );
            }
          }
        },
      ),
      ListTile(leading: const Icon(Icons.send_outlined), title: const Text('مشاركة داخل AUREN'), onTap: () { unawaited(_trackShareAction(item)); Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'أريد مشاركة هذا المحتوى داخل AUREN: '+item.title+'\n'+item.mediaUrl))); }),
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('تعذّر تحميل التعليقات. حاول لاحقاً.'),
                      );
                    }
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) {
                      return const Center(child: Text('كن أول من يعلّق 👋'));
                    }
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
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          try {
                            await repo.addShortComment(
                              uid!,
                              item.id,
                              text,
                              mood: mood,
                            );
                            if (sheetContext.mounted) controller.clear();
                          } catch (_) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text('تعذّر إرسال التعليق. حاول مرة أخرى.'),
                                ),
                              );
                            }
                          }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      final activeController =
          _activeItemId == null ? null : controllers[_activeItemId];
      _resumeAfterLifecycle =
          activeController != null &&
          activeController.value.isInitialized &&
          activeController.value.isPlaying;
      for (final controller in controllers.values) {
        unawaited(_pauseControllerSafely(controller));
      }
      return;
    }

    if (state == AppLifecycleState.resumed && _resumeAfterLifecycle) {
      _resumeAfterLifecycle = false;
      final activeId = _activeItemId;
      final activeController =
          activeId == null ? null : controllers[activeId];
      if (activeController != null &&
          activeController.value.isInitialized &&
          mounted) {
        activeController.play().catchError((Object _) async {
          // A failed resume must not leave a broken controller available for
          // the next page build or a later lifecycle transition.
          if (activeId != null &&
              identical(controllers[activeId], activeController)) {
            controllers.remove(activeId);
          }
          if (activeId != null) _failedControllerIds.add(activeId);
          try {
            await activeController.dispose();
          } catch (_) {
            // The native player may already have released its resources.
          }
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final activeItem = _activeItemId == null ? null : _itemsById[_activeItemId];
    if (activeItem != null) unawaited(_trackView(activeItem));
    final remainingControllers = controllers.values.toList();
    controllers.clear();
    for (final controller in remainingControllers) {
      unawaited(_disposeControllerSafely(controller));
    }
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

  void _pruneFeedMetadata(Set<String> feedIds) {
    // Keep metadata for the current feed and in-flight work only. Without this,
    // a long session with changing feed snapshots can retain every old item ID.
    final playbackIds = <String>{
      ...feedIds,
      ..._preparing,
      ..._retainedControllerIds,
      if (_activeItemId != null) _activeItemId!,
    };
    final itemIds = <String>{
      ...feedIds,
      ..._preparing,
      ..._tracking,
      if (_activeItemId != null) _activeItemId!,
    };

    _itemsById.removeWhere((id, _) => !itemIds.contains(id));
    _qualityUrls.removeWhere((id, _) => !playbackIds.contains(id));
    _playbackGeneration.removeWhere((id, _) => !playbackIds.contains(id));
    _failedControllerIds.removeWhere((id) => !playbackIds.contains(id));
  }

  void _changeShortCategory(String value) {
    if (value == shortCategory) return;
    // Changing the feed is still the end of the currently visible Short.
    // Record its playback before the controller is disposed, just as paging does.
    final currentId = _activeItemId;
    final currentItem = currentId == null ? null : _itemsById[currentId];
    if (currentItem != null) unawaited(_trackView(currentItem));
    _retainedControllerIds.clear();
    final oldControllers = controllers.values.toList();
    controllers.clear();
    for (final controller in oldControllers) {
      unawaited(_pauseAndDisposeControllerSafely(controller));
    }
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 12),
              const Text('تعذّر تحميل الشورتات حالياً. تحقق من الاتصال وحاول مرة أخرى.'),
            ],
          ),
        ),
      );
    }
    for (final item in items) {
      _itemsById[item.id] = item;
    }
    final visibleItems = items.where(_matchesCategory).toList();
    _pruneFeedMetadata(items.map((item) => item.id).toSet());

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
                      _startedAt.putIfAbsent(item.id, DateTime.now);
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
                      onTap: () => _togglePlayback(item, c),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                    )
                  else if (_failedControllerIds.contains(item.id))
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          const Text('تعذّر تشغيل الفيديو', style: TextStyle(color: Colors.white)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => _retryPreparation(item),
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
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
                                final actionMood = mood;
                                try {
                                  await repo.toggleShortLike(uid!, item.id, next);
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تعذّر تحديث الإعجاب. حاول مرة أخرى.'),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await repo.trackShortAction(
                                    uid!,
                                    item.id,
                                    action: next ? 'like' : 'unlike',
                                    mood: actionMood,
                                  );
                                } catch (_) {
                                  // A like should not appear to fail because analytics are offline.
                                }
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
                                  try {
                                    if (isSaved) {
                                      await repo.unsave(uid!, item.id);
                                    } else {
                                      await repo.save(uid!, item.id);
                                    }
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تعذّر تحديث المحفوظات. حاول مرة أخرى.'),
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await repo.trackShortAction(
                                      uid!,
                                      item.id,
                                      action: isSaved ? 'unsave' : 'save',
                                      mood: mood,
                                    );
                                  } catch (_) {
                                    // Saving content must work independently of analytics.
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

                  if ([item.mediaUrlLow, item.mediaUrlMedium, item.mediaUrlHigh]
                      .any(_isHttpVideoUrl))
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
