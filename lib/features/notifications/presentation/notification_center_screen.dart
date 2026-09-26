import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/conversation_repository.dart';
import '../../../services/messaging/messenger_screen.dart';
import '../../../services/social/notification_service.dart';

class AurenNotificationCenterScreen extends StatefulWidget {
  const AurenNotificationCenterScreen({super.key});
  @override State<AurenNotificationCenterScreen> createState() => _AurenNotificationCenterScreenState();
}

class _AurenNotificationCenterScreenState extends State<AurenNotificationCenterScreen> {
  final auth = FirebaseAurenAuthService();
  final service = AurenNotificationService();
  String filter = 'all';
  bool unreadOnly = false;

  bool _matches(AurenNotification n) {
    if (unreadOnly && n.read) return false;
    if (filter == 'all') return true;
    if (filter == 'social') return ['follow', 'like', 'comment'].contains(n.type);
    if (filter == 'messages') return ['message', 'group'].contains(n.type);
    if (filter == 'ai') return n.type == 'action';
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          StreamBuilder<int>(
            stream: service.watchUnreadCount(uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Center(child: Text('$count unread', style: Theme.of(context).textTheme.labelMedium)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'read') await service.markAllRead(uid);
                    if (value == 'unread') setState(() => unreadOnly = !unreadOnly);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'read', enabled: count > 0, child: const Text('Mark all as read')),
                    PopupMenuItem(value: 'unread', child: Text(unreadOnly ? 'Show all' : 'Unread only')),
                  ],
                ),
              ]);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AurenNotification>>(
        stream: service.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load notifications.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final all = snapshot.data!;
          final items = all.where(_matches).toList();
          return Column(children: [
            SizedBox(
              height: 58,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('all', 'All', all.length),
                  _filterChip('social', 'Social', all.where((n) => ['follow','like','comment'].contains(n.type)).length),
                  _filterChip('messages', 'Messages', all.where((n) => ['message','group'].contains(n.type)).length),
                  _filterChip('ai', 'AUREN AI', all.where((n) => n.type == 'action').length),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyNotifications(filtered: all.isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) => _NotificationTile(
                        item: items[index],
                        onTap: () => _openNotification(items[index]),
                        onToggleRead: () async {
                          if (items[index].read) {
                            await service.markUnread(uid, items[index].id);
                          } else {
                            await service.markRead(uid, items[index].id);
                          }
                        },
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text('$label${count > 0 ? ' · $count' : ''}'),
      selected: filter == value,
      onSelected: (_) => setState(() => filter = value),
    ),
  );

  Future<void> _openNotification(AurenNotification item) async {
    final uid = auth.currentUserId;
    if (uid == null) return;
    if (!item.read) await service.markRead(uid, item.id);
    final conversationId = item.conversationId;
    if (conversationId == null || conversationId.isEmpty || !mounted) return;
    final conversation = await ConversationRepository().findById(conversationId);
    if (conversation == null || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => MessengerScreen(conversationId: conversationId),
    ));
  }
}

class _NotificationTile extends StatelessWidget {
  final AurenNotification item;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  const _NotificationTile({required this.item, required this.onTap, required this.onToggleRead});

  IconData _icon(String type) {
    switch (type) {
      case 'message':
      case 'group': return Icons.chat_bubble_outline;
      case 'follow': return Icons.person_add_alt_1;
      case 'like': return Icons.favorite_border;
      case 'comment': return Icons.mode_comment_outlined;
      case 'action': return Icons.auto_awesome;
      default: return Icons.notifications_none;
    }
  }

  String _label(String type) {
    switch (type) {
      case 'message': return 'Message';
      case 'group': return 'Group';
      case 'follow':
      case 'like':
      case 'comment': return 'Social';
      case 'action': return 'AUREN AI';
      default: return 'System';
    }
  }

  String _time(DateTime? value) {
    if (value == null) return '';
    final delta = DateTime.now().difference(value);
    if (delta.isNegative || delta.inSeconds < 60) return 'Now';
    if (delta.inMinutes < 60) return '· ${delta.inMinutes}m';
    if (delta.inHours < 24) return '· ${delta.inHours}h';
    if (delta.inDays < 7) return '· ${delta.inDays}d';
    return '${value.day}/${value.month}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: item.read ? theme.colorScheme.surface : theme.colorScheme.primaryContainer.withOpacity(.22),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 23, child: Icon(_icon(item.type))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.w600 : FontWeight.bold))),
                Text(_time(item.createdAt), style: theme.textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              Text(_label(item.type), style: theme.textTheme.labelSmall),
              if (item.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ])),
            PopupMenuButton<String>(
              onSelected: (_) => onToggleRead(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(item.read ? 'Mark as unread' : 'Mark as read')),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  final bool filtered;
  const _EmptyNotifications({this.filtered = false});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_none, size: 64),
        const SizedBox(height: 14),
        Text(filtered ? 'Nothing in this filter' : 'No notifications yet',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(filtered
          ? 'Try another category or show all notifications.'
          : 'New followers, messages, likes and AUREN actions will appear here.',
          textAlign: TextAlign.center),
      ]),
    ),
  );
}
