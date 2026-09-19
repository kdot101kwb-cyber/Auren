import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/users/user_repository.dart';
import '../../../services/social/follow_repository.dart';
import 'social_graph_screen.dart';

class AurenProfileScreen extends StatelessWidget {
  const AurenProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    final follows = FollowRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder(
        stream: UserRepository().watch(uid),
        builder: (context, s) {
          if (s.hasError) return const Center(child: Text('Could not load profile.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final p = s.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
              const SizedBox(height: 16),
              Text(p.displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Connect. Create. Achieve.'),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Count(label: 'Followers', stream: follows.followersCount(uid), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
                Expanded(child: _Count(label: 'Following', stream: follows.followingCount(uid), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
              ]),
              const SizedBox(height: 18),
              Card(child: ListTile(leading: const Icon(Icons.edit), title: const Text('Edit profile'), onTap: () => showDialog(context: context, builder: (_) => _EditNameDialog(uid: uid, current: p.displayName)))),
              Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('AI Profile'), subtitle: const Text('Personal • Creator • Professional • Business'))),
              Card(child: ListTile(leading: const Icon(Icons.people_outline), title: const Text('Social Graph'), subtitle: const Text('Followers, following and communities'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
            ],
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label; final Stream<int> stream; final VoidCallback onTap;
  const _Count({required this.label, required this.stream, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: StreamBuilder<int>(stream: stream, builder: (_, s) => Column(children: [
      Text('${s.data ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label),
    ])),
  );
}

class _EditNameDialog extends StatefulWidget {
  final String uid, current;
  const _EditNameDialog({required this.uid, required this.current});
  @override State<_EditNameDialog> createState() => _EditNameDialogState();
}
class _EditNameDialogState extends State<_EditNameDialog> {
  late final c = TextEditingController(text: widget.current);
  bool saving = false;
  Future<void> save() async {
    final name = c.text.trim();
    if (name.isEmpty || name.length > 80) return;
    setState(() => saving = true);
    try { await UserRepository().updateDisplayName(widget.uid, name); if (mounted) Navigator.pop(context); }
    catch (_) { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit profile'),
    content: TextField(controller: c, autofocus: true, maxLength: 80, decoration: const InputDecoration(labelText: 'Display name')),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: saving ? null : save, child: const Text('Save')),
    ],
  );
  @override void dispose() { c.dispose(); super.dispose(); }
}