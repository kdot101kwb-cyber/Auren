import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notifications/notification_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenNotificationsScreen extends StatefulWidget {
  const AurenNotificationsScreen({super.key});
  @override State<AurenNotificationsScreen> createState() => _AurenNotificationsScreenState();
}
class _AurenNotificationsScreenState extends State<AurenNotificationsScreen> {
  IconData _iconFor(String type, bool read) {
    if (type == 'message') return read ? Icons.chat_bubble_outline : Icons.chat;
    if (type == 'follow') return read ? Icons.person_outline : Icons.person_add;
    if (type == 'like') return read ? Icons.favorite_border : Icons.favorite;
    if (type == 'comment') return read ? Icons.mode_comment_outlined : Icons.mode_comment;
    if (type == 'group') return read ? Icons.groups_outlined : Icons.groups;
    if (type == 'action') return read ? Icons.task_alt : Icons.pending_actions;
    return read ? Icons.notifications_none : Icons.notifications_active;
  }
  final _repo = NotificationRepository();
  String? _uid;
  @override void initState() { super.initState(); _bootstrap(); }
  Future<void> _bootstrap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) setState(() => _uid = user?.uid);
  }
  @override Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        if (uid != null) TextButton(onPressed: () => _repo.markAllRead(uid), child: const Text('Mark all read')),
      ]),
      body: uid == null ? const Center(child: Text('يجب تسجيل الدخول لعرض الإشعارات')) : StreamBuilder<List<AurenNotification>>(
        stream: _repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('لا توجد إشعارات جديدة.'));
          return ListView.separated(
            itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) { final n = items[i]; return ListTile(
              leading: Icon(_iconFor(n.type, n.read)),
              title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text(n.body),
              onTap: () async {
                if (!n.read) await _repo.markRead(uid, n.id);
                if (!mounted || n.conversationId == null || n.conversationId!.isEmpty) return;
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MessengerScreen(conversationId: n.conversationId),
                ));
              },
            ); },
          );
        },
      ),
    );
  }
}