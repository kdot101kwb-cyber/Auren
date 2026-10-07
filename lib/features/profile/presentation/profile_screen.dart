import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/users/user_repository.dart';
import '../../../services/social/follow_repository.dart';
import 'social_graph_screen.dart';
import 'ai_profile_screen.dart';
import '../../../core/i18n/auren_localizations.dart';

class AurenProfileScreen extends StatelessWidget {
  final String? userId;
  const AurenProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final uid = userId ?? FirebaseAurenAuthService().currentUserId;
    if (uid == null) return Scaffold(body: Center(child: Text(AurenLocalizations.of(context).signInRequired)));
    final follows = FollowRepository();
    return Scaffold(
      appBar: AppBar(title: Text(AurenLocalizations.of(context).profile)),
      body: StreamBuilder(
        stream: UserRepository().watch(uid),
        builder: (context, s) {
          if (s.hasError) return Center(child: Text(AurenLocalizations.of(context).profileLoadError));
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
                Expanded(child: _Count(label: AurenLocalizations.of(context).followers, stream: follows.followersCount(uid), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
                Expanded(child: _Count(label: AurenLocalizations.of(context).following, stream: follows.followingCount(uid), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
              ]),
              const SizedBox(height: 18),
              Card(child: ListTile(leading: const Icon(Icons.edit), title: Text(AurenLocalizations.of(context).editProfile), onTap: () => showDialog(context: context, builder: (_) => _EditNameDialog(uid: uid, current: p.displayName)))),
              Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: Text(AurenLocalizations.of(context).aiProfile), subtitle: Text(AurenLocalizations.of(context).profileModes), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAiProfileScreen())))),
              Card(child: ListTile(leading: const Icon(Icons.people_outline), title: Text(AurenLocalizations.of(context).socialGraph), subtitle: Text(AurenLocalizations.of(context).socialGraphDescription), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenSocialGraphScreen(uid: uid))))),
              Card(child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(AurenLocalizations.of(context).shareProfile), subtitle: Text(AurenLocalizations.of(context).shareProfileDescription), onTap: () async {
                final link = 'https://auren.app/u/$uid';
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AurenLocalizations.of(context).copiedProfileLink)));
              })),
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
    title: Text(AurenLocalizations.of(context).editProfile),
    content: TextField(controller: c, autofocus: true, maxLength: 80, decoration: InputDecoration(labelText: AurenLocalizations.of(context).displayName)),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: Text(AurenLocalizations.of(context).cancel)),
      FilledButton(onPressed: saving ? null : save, child: Text(AurenLocalizations.of(context).save)),
    ],
  );
  @override void dispose() { c.dispose(); super.dispose(); }
}