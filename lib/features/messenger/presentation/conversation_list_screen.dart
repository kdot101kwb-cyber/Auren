import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/users/user_repository.dart';
import '../../../services/users/presence_service.dart';
import 'messenger_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../../services/notifications/notification_repository.dart';
import '../../safety/presentation/blocked_users_screen.dart';

class AurenConversationListScreen extends StatefulWidget {
  const AurenConversationListScreen({super.key});
  @override State<AurenConversationListScreen> createState() => _AurenConversationListScreenState();
}
class _AurenConversationListScreenState extends State<AurenConversationListScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = ConversationRepository();
  final _notifications = NotificationRepository();
  final _users = UserRepository();
  final _presence = AurenPresenceService();
  String? _uid;
  @override void initState() { super.initState(); _bootstrap(); }
  Future<void> _bootstrap() async { try { final uid = _auth.currentUserId; if (mounted) setState(() => _uid = uid); } catch (_) {} }
  Future<void> _createGroup() async {
    final title = TextEditingController();
    final member = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create group'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Group name')),
          TextField(controller: member, decoration: const InputDecoration(labelText: 'Member UIDs (comma separated)')),
          const SizedBox(height: 8),
          const Text('Add members by UID. You can add more later from the group screen.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, [title.text, member.text]), child: const Text('Create')),
        ],
      ),
    );
    title.dispose(); member.dispose();
    if (result == null || _uid == null) return;
    try {
      final members = result[1].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final c = await _repo.createGroup(uid: _uid!, title: result[0], memberIds: members);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: c.id)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء المجموعة: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Messenger'), actions: [
        IconButton(
          tooltip: 'Safety',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenBlockedUsersScreen())),
          icon: const Icon(Icons.shield_outlined),
        ),
        IconButton(onPressed: _createGroup, icon: const Icon(Icons.group_add)),
        if (uid != null)
          StreamBuilder<int>(
            stream: _notifications.watchUnreadCount(uid),
            builder: (_, snapshot) => IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenNotificationsScreen())),
              icon: Badge(
                isLabelVisible: (snapshot.data ?? 0) > 0,
                label: Text('${snapshot.data ?? 0}'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen())),
        icon: const Icon(Icons.auto_awesome), label: const Text('AUREN AI'),
      ),
      body: uid == null ? const Center(child: Text('سجّل الدخول أولاً لفتح Messenger.')) : RefreshIndicator(
        onRefresh: () async { if (mounted) setState(() {}); },
        child: StreamBuilder(
        stream: _repo.watchForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل المحادثات: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final conversations = snapshot.data!;
          if (conversations.isEmpty) return const Center(child: Text('ابدأ أول محادثة مع AUREN AI.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12), itemCount: conversations.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = conversations[i];
              final otherUid = !c.isAi && c.type == 'direct'
                  ? c.memberIds.where((id) => id != uid).firstOrNull
                  : null;
              return StreamBuilder<AurenUserProfile?>(
                stream: otherUid == null ? const Stream.empty() : _users.watch(otherUid),
                builder: (_, profile) {
                  final name = c.isAi ? 'AUREN AI' : (profile.data?.displayName ?? c.title);
                  final photoUrl = profile.data?.photoUrl;
                  return StreamBuilder<Map<String, dynamic>?>(
                    stream: otherUid == null ? const Stream.empty() : _presence.watch(otherUid),
                    builder: (_, presence) {
                      final online = presence.data?['online'] == true;
                      final at = c.lastMessageAt ?? c.updatedAt;
                      final time = at.hour.toString().padLeft(2, '0') + ':' + at.minute.toString().padLeft(2, '0');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Stack(children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(c.isAi ? Icons.auto_awesome : c.type == 'group' ? Icons.groups : Icons.person)
                                : null,
                          ),
                          if (otherUid != null)
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 13, height: 13,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: online ? Colors.green : Colors.grey,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                              ),
                            ),
                        ]),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Row(children: [
                          if (c.lastMessageSenderId == uid && c.lastMessage?.isNotEmpty == true)
                            const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.done_all, size: 14)),
                          Expanded(child: Text(
                            c.lastMessage?.isNotEmpty == true ? c.lastMessage! : (c.isAi ? 'AUREN AI' : c.type == 'group' ? 'Group conversation' : 'محادثة'),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                        trailing: StreamBuilder<int>(
                          stream: _repo.watchUnreadCount(c.id, uid),
                          builder: (_, unread) {
                            final count = unread.data ?? 0;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(time, style: Theme.of(context).textTheme.labelSmall),
                                const SizedBox(height: 5),
                                if (count > 0)
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 22),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: c.id)),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }
}