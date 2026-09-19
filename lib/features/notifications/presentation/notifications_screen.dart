import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/notifications/notification_repository.dart';

class AurenNotificationsScreen extends StatefulWidget {
  const AurenNotificationsScreen({super.key});
  @override State<AurenNotificationsScreen> createState() => _AurenNotificationsScreenState();
}
class _AurenNotificationsScreenState extends State<AurenNotificationsScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = NotificationRepository();
  String? _uid;
  @override void initState() { super.initState(); _bootstrap(); }
  Future<void> _bootstrap() async { try { final uid = _auth.currentUserId ?? await _auth.signInAnonymously(); if (mounted) setState(() => _uid = uid); } catch (_) {} }
  @override Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        if (uid != null) TextButton(onPressed: () => _repo.markAllRead(uid), child: const Text('Mark all read')),
      ]),
      body: uid == null ? const Center(child: CircularProgressIndicator()) : StreamBuilder<List<AurenNotification>>(
        stream: _repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('لا توجد إشعارات جديدة.'));
          return ListView.separated(
            itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) { final n = items[i]; return ListTile(
              leading: Icon(n.read ? Icons.notifications_none : Icons.notifications_active),
              title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text(n.body),
              onTap: n.read ? null : () => _repo.markRead(uid, n.id),
            ); },
          );
        },
      ),
    );
  }
}