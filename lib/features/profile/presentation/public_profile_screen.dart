import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/follow_repository.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/users/presence_service.dart';
import '../../../services/social/profile_mode_service.dart';
import '../../../services/social/safety_repository.dart';
import '../../social/presentation/safety_actions_sheet.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/social/adaptive_profile_service.dart';

class AurenPublicProfileScreen extends StatefulWidget {
  final AurenUserProfile profile;
  const AurenPublicProfileScreen({super.key, required this.profile});
  @override
  State<AurenPublicProfileScreen> createState() => _AurenPublicProfileScreenState();
}

class _AurenPublicProfileScreenState extends State<AurenPublicProfileScreen> {
  final repo = FollowRepository();
  final conversations = ConversationRepository();
  final profileModes = AurenProfileModeService();
  final safety = AurenSafetyRepository();
  bool busy = false;
  bool messaging = false;

  Future<void> _toggle(String me, bool following) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await repo.toggle(me, widget.profile.uid, following);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update follow status.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _message(String me) async {
    if (messaging) return;
    setState(() => messaging = true);
    try {
      final conversation = await conversations.getOrCreateDirectConversation(
        uid: me,
        otherUid: widget.profile.uid,
        otherTitle: widget.profile.displayName,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessengerScreen(conversationId: conversation.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open conversation: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => messaging = false);
    }
  }

  void _askAuren() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(
          initialPrompt:
              'ساعدني أفهم كيف يمكنني التواصل أو التعاون مع ' +
              widget.profile.displayName +
              ' في AUREN. اقترح خطوات مناسبة ومحترمة بدون افتراض معلومات غير موجودة عن الشخص.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAurenAuthService().currentUserId;
    final own = me == widget.profile.uid;
    final photoUrl = widget.profile.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (me != null && !own)
            StreamBuilder<bool>(
              stream: safety.watchBlocked(me, widget.profile.uid),
              builder: (context, blockedSnapshot) {
                final blocked = blockedSnapshot.data == true;
                return IconButton(
                  tooltip: blocked ? 'Unblock' : 'Safety',
                  icon: Icon(blocked ? Icons.block : Icons.more_horiz),
                  onPressed: () async {
                    if (blocked) await safety.unblock(me, widget.profile.uid);
                    else await AurenSafetyActionsSheet.show(context, uid: me, targetUid: widget.profile.uid, contentType: 'profile');
                  },
                );
              },
            ),
          IconButton(
            tooltip: 'Share profile',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final link = 'https://auren.app/u/' + widget.profile.uid;
              await Clipboard.setData(ClipboardData(text: link));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile link copied.')),
                );
              }
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(Icons.person, size: 52)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              widget.profile.displayName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<Map<String, dynamic>?>(
            stream: AurenPresenceService().watch(widget.profile.uid),
            builder: (_, snapshot) {
              final data = snapshot.data;
              final online = data?['online'] == true;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: online ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(online ? 'Online' : 'Offline'),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: repo.followersCount(widget.profile.uid),
                  builder: (_, s) => _stat(
                    (s.data ?? 0).toString(),
                    'Followers',
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<int>(
                  stream: repo.followingCount(widget.profile.uid),
                  builder: (_, s) => _stat(
                    (s.data ?? 0).toString(),
                    'Following',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<AurenProfileMode>(
            stream: profileModes.watchActiveMode(widget.profile.uid),
            builder: (context, modeSnapshot) {
              final mode = modeSnapshot.data ?? AurenProfileMode.personal;
              return StreamBuilder<AurenProfileModeData>(
                stream: profileModes.watch(widget.profile.uid, mode),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null || !data.discoverable) return const SizedBox.shrink();

                  final adaptive = const AurenAdaptiveProfileService();
                  final result = adaptive.suggest(
                    currentMode: mode,
                    context: AurenProfileContext.social,
                    profile: data,
                  );
                  final displayMode = result.mode;

                  final sections = <String>[];
                  void add(String label, List<String> values, {int max = 4}) {
                    if (values.isNotEmpty) sections.add(label + ': ' + values.take(max).join('، '));
                  }

                  // The same profile is presented differently depending on the
                  // active mode; no duplicate profile data is created.
                  switch (displayMode) {
                    case AurenProfileMode.creator:
                      add('محتوى', data.services);
                      add('اهتمامات', data.interests);
                      add('إنجازات', data.achievements, max: 3);
                      add('لغات', data.languages);
                      break;
                    case AurenProfileMode.professional:
                      add('مهارات', data.skills);
                      add('أهداف', data.goals, max: 3);
                      add('إنجازات', data.achievements, max: 3);
                      add('لغات', data.languages);
                      break;
                    case AurenProfileMode.business:
                      add('خدمات / منتجات', data.services);
                      add('اهتمامات', data.interests);
                      add('إنجازات', data.achievements, max: 3);
                      add('لغات', data.languages);
                      break;
                    case AurenProfileMode.personal:
                      add('اهتمامات', data.interests);
                      add('لغات', data.languages);
                      break;
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI Profile • ' + displayMode.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (displayMode != mode)
                                const Tooltip(
                                  message: 'عرض متكيف مع السياق',
                                  child: Icon(Icons.tune, size: 18),
                                ),
                            ],
                          ),
                          if (data.headline.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(data.headline, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                          if (data.bio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(data.bio),
                          ],
                          if (sections.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(sections.join('\\n')),
                          ],
                          if (displayMode != mode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'AUREN يعرض المعلومات الأنسب للسياق الحالي بدون تغيير وضع الملف الأساسي.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          if (!own && me != null)
            StreamBuilder<bool>(
              stream: safety.watchBlocked(me, widget.profile.uid),
              builder: (context, blockedSnapshot) {
                if (blockedSnapshot.data == true) {
                  return const Card(child: ListTile(leading: Icon(Icons.block), title: Text('Profile blocked'), subtitle: Text('Unblock from the top menu to interact again.')));
                }
                return Column(children: [
          FilledButton.tonalIcon(
              onPressed: messaging ? null : () => _message(me),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(messaging ? 'Opening…' : 'Message'),
            ),
          if (!own && me != null)
            FilledButton.tonalIcon(
              onPressed: _askAuren,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask AUREN'),
            ),
          if (!own && me != null)
            StreamBuilder<bool>(
              stream: repo.watchFollowing(me, widget.profile.uid),
              builder: (context, s) {
                final following = s.data ?? false;
                return FilledButton.icon(
                  onPressed: busy ? null : () => _toggle(me, following),
                  icon: Icon(following ? Icons.person_remove : Icons.person_add),
                  label: Text(
                    busy ? 'Updating…' : following ? 'Following' : 'Follow',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      );
}
