import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notifications/notification_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenNotificationsScreen extends StatefulWidget {
  const AurenNotificationsScreen({super.key});
  @override State<AurenNotificationsScreen> createState() => _AurenNotificationsScreenState();
}

class _AurenNotificationsScreenState extends State<AurenNotificationsScreen> {
  final _repo = NotificationRepository();
  String? _uid;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  String _category(AurenNotification n) {
    switch (n.type) {
      case 'message':
      case 'group': return 'messages';
      case 'follow':
      case 'like':
      case 'comment': return 'social';
      case 'opportunity':
      case 'business':
      case 'creator':
      case 'talent': return 'opportunities';
      case 'action':
      case 'system': return 'system';
      default: return 'all';
    }
  }

  IconData _iconFor(AurenNotification n) {
    switch (n.type) {
      case 'message': return Icons.chat_bubble_rounded;
      case 'group': return Icons.groups_rounded;
      case 'follow': return Icons.person_add_rounded;
      case 'like': return Icons.favorite_rounded;
      case 'comment': return Icons.mode_comment_rounded;
      case 'opportunity': return Icons.bolt_rounded;
      case 'business': return Icons.business_center_rounded;
      case 'creator': return Icons.auto_awesome_rounded;
      case 'talent': return Icons.stars_rounded;
      case 'action': return Icons.task_alt_rounded;
      case 'system': return Icons.settings_suggest_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _iconColor(BuildContext context, AurenNotification n) {
    final scheme = Theme.of(context).colorScheme;
    return n.read ? scheme.onSurfaceVariant : scheme.primary;
  }

  String _when(DateTime value) {
    final now = DateTime.now();
    final d = now.difference(value);
    if (d.inSeconds < 60) return 'الآن';
    if (d.inMinutes < 60) return 'منذ \${d.inMinutes} د';
    if (d.inHours < 24) return 'منذ \${d.inHours} س';
    if (d.inDays == 1) return 'أمس';
    if (d.inDays < 7) return 'منذ \${d.inDays} أيام';
    return '\${value.day}/\${value.month}/\${value.year}';
  }

  String _filterLabel(String value) {
    switch (value) {
      case 'unread': return 'غير مقروءة';
      case 'social': return 'اجتماعي';
      case 'messages': return 'رسائل';
      case 'opportunities': return 'فرص';
      case 'system': return 'النظام';
      default: return 'الكل';
    }
  }

  Future<void> _open(AurenNotification n) async {
    final uid = _uid;
    if (uid == null) return;
    if (!n.read) await _repo.markRead(uid, n.id);
    if (!mounted) return;
    if (n.conversationId != null && n.conversationId!.isNotEmpty) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => MessengerScreen(conversationId: n.conversationId),
      ));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(child: Icon(_iconFor(n))),
                const SizedBox(width: 12),
                Expanded(child: Text(n.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 14),
              Text(n.body, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              Text(_when(n.createdAt), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAll(String uid) async {
    await _repo.markAllRead(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعليم كل الإشعارات كمقروءة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول لعرض الإشعارات')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإشعارات'),
        actions: [
          StreamBuilder<int>(
            stream: _repo.watchUnreadCount(uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _markAll(uid),
                icon: const Icon(Icons.done_all),
                label: const Text('قراءة الكل'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AurenNotification>>(
        stream: _repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الإشعارات'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final all = snapshot.data!;
          final items = all.where((n) {
            if (_filter == 'unread') return !n.read;
            if (_filter == 'all') return true;
            return _category(n) == _filter;
          }).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: ['all', 'unread', 'social', 'messages', 'opportunities', 'system']
                      .map((value) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              label: Text(_filterLabel(value)),
                              selected: _filter == value,
                              onSelected: (_) => setState(() => _filter = value),
                            ),
                          )).toList(),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _empty(context, _filter == 'unread' ? 'ما عندك إشعارات غير مقروءة' : 'لا توجد إشعارات هنا')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final n = items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _iconColor(context, n).withValues(alpha: 0.12),
                                    child: Icon(_iconFor(n), color: _iconColor(context, n)),
                                  ),
                                  if (!n.read)
                                    PositionedDirectional(
                                      top: -2, end: -2,
                                      child: Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).scaffoldBackgroundColor, width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('\${n.body}\\n\${_when(n.createdAt)}', maxLines: 3, overflow: TextOverflow.ellipsis),
                              ),
                              isThreeLine: true,
                              onTap: () => _open(n),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('سنضع هنا الرسائل، التفاعلات، الفرص وتحديثات AUREN المهمة.', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
