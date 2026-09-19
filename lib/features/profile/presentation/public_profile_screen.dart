import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/follow_repository.dart';

class AurenPublicProfileScreen extends StatefulWidget {
  final AurenUserProfile profile;
  const AurenPublicProfileScreen({super.key, required this.profile});
  @override State<AurenPublicProfileScreen> createState() => _AurenPublicProfileScreenState();
}

class _AurenPublicProfileScreenState extends State<AurenPublicProfileScreen> {
  final repo = FollowRepository();
  bool busy = false;

  Future<void> _toggle(String me, bool following) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await repo.toggle(me, widget.profile.uid, following);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update follow status.')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAurenAuthService().currentUserId;
    final own = me == widget.profile.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(widget.profile.displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: StreamBuilder<int>(
              stream: repo.followersCount(widget.profile.uid),
              builder: (_, s) => _stat('${s.data ?? 0}', 'Followers'),
            )),
            Expanded(child: StreamBuilder<int>(
              stream: repo.followingCount(widget.profile.uid),
              builder: (_, s) => _stat('${s.data ?? 0}', 'Following'),
            )),
          ]),
          const SizedBox(height: 20),
          if (!own && me != null)
            StreamBuilder<bool>(
              stream: repo.watchFollowing(me, widget.profile.uid),
              builder: (context, s) {
                final following = s.data ?? false;
                return FilledButton.icon(
                  onPressed: busy ? null : () => _toggle(me, following),
                  icon: Icon(following ? Icons.person_remove : Icons.person_add),
                  label: Text(busy ? 'Updating…' : following ? 'Following' : 'Follow'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label),
    ],
  );
}