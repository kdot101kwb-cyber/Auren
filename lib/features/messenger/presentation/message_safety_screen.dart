import 'package:flutter/material.dart';

import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/message_safety_repository.dart';

class AurenMessageSafetyScreen extends StatefulWidget {
  const AurenMessageSafetyScreen({super.key});

  @override
  State<AurenMessageSafetyScreen> createState() => _AurenMessageSafetyScreenState();
}

class _AurenMessageSafetyScreenState extends State<AurenMessageSafetyScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = MessageSafetyRepository();
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Message Safety')),
      body: uid == null
          ? const Center(child: Text('لا يوجد حساب نشط.'))
          : StreamBuilder<List<String>>(
              stream: _repo.watchBlockedUsers(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('تعذر تحميل قائمة الحظر.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final blocked = snapshot.data!;
                if (blocked.isEmpty) {
                  return const Center(child: Text('لا يوجد مستخدمون محظورون.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: blocked.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final blockedUid = blocked[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.block)),
                      title: Text(blockedUid),
                      subtitle: const Text('لن تستطيع مراسلته حتى إلغاء الحظر.'),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            await _repo.unblock(uid, blockedUid);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تعذر إلغاء الحظر: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Unblock'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
