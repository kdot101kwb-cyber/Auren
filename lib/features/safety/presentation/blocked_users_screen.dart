import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/messaging/message_safety_repository.dart';

class AurenBlockedUsersScreen extends StatefulWidget {
  const AurenBlockedUsersScreen({super.key});

  @override
  State<AurenBlockedUsersScreen> createState() => _AurenBlockedUsersScreenState();
}

class _AurenBlockedUsersScreenState extends State<AurenBlockedUsersScreen> {
  final _auth = FirebaseAurenAuthService();
  final _safety = MessageSafetyRepository();
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
      appBar: AppBar(title: const Text('Blocked users')),
      body: uid == null
          ? const Center(child: Text('Sign in to manage blocked users.'))
          : StreamBuilder<List<String>>(
              stream: _safety.watchBlockedUsers(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('تعذر تحميل قائمة الحظر'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!;
                if (users.isEmpty) return const Center(child: Text('لا يوجد مستخدمون محظورون.'));
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final blockedUid = users[i];
                    return ListTile(
                      leading: const Icon(Icons.block),
                      title: Text(blockedUid),
                      trailing: TextButton(
                        onPressed: () => _safety.unblock(uid, blockedUid),
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
