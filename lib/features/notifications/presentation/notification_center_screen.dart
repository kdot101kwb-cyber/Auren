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

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: service.watchUnreadCount(uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return PopupMenuButton<String>(
                onSelected: (value) async { if (value == 'read') await service.markAllRead(uid); },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'read', enabled: count > 0, child: const Text('Mark all as read')),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AurenNotification>>(
        stream: service.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load notifications.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const _EmptyNotifications();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
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
          );
        },
      ),
    );
  }

  Future<void> _openNotification(AurenNotification item) async {
    final uid = auth.currentUserId;
    if (uid == null) return;
    if (!item.read) await service.markRead(uid, item.id);
    final conversationId = item.conversationId;
    if (conversationId == null || conversationId.isEmpty || !mounted) return;
    final conversation = await ConversationRepository().findById(conversationId);
    if (conversation == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessengerScreen(conversationId: conversationId)),
    );
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

  String _time(DateTime? value) {
    if (value == null) return '';
    final delta = DateTime.now().difference(value);
    if (delta.inSeconds < 60) return 'الآن';
    if (delta.inMinutes < 60) return 'منذ \${delta.inMinutes} د';
    if (delta.inHours < 24) return 'منذ \${delta.inHours} س';
    if (delta.inDays < 7) return 'منذ \${delta.inDays} ي';
    return '\${value.day}/\${value.month}/\${value.year}';
  }

  @override
  Widget build(BuildContext context) => Material(
    color: item.read ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primaryContainer.withOpacity(.22),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 23, child: Icon(_icon(item.type))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.w600 : FontWeight.bold))),
                  Text(_time(item.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ]),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (_) => onToggleRead(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle', child: Text(item.read ? 'Mark as unread' : 'Mark as read')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();
  @override Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_none, size: 64),
        const SizedBox(height: 14),
        const Text('No notifications yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('New followers, messages, likes and AUREN actions will appear here.', textAlign: TextAlign.center),
      ]),
    ),
  );
}
