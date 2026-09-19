import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/social/follow_repository.dart';
import '../../../services/users/user_repository.dart';
import 'public_profile_screen.dart';

class AurenSocialGraphScreen extends StatelessWidget {
  final String uid;
  const AurenSocialGraphScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final follows = FollowRepository();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social Graph'),
          bottom: const TabBar(tabs: [Tab(text: 'Followers'), Tab(text: 'Following')]),
        ),
        body: TabBarView(
          children: [
            _FollowList(stream: follows.followers(uid)),
            _FollowList(stream: follows.following(uid)),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends StatelessWidget {
  final Stream<List<String>> stream;
  const _FollowList({required this.stream});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<String>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load social graph.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ids = snapshot.data!;
          if (ids.isEmpty) return const Center(child: Text('Nothing here yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ids.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _UserRow(uid: ids[i]),
          );
        },
      );
}

class _UserRow extends StatelessWidget {
  final String uid;
  const _UserRow({required this.uid});

  @override
  Widget build(BuildContext context) => StreamBuilder<AurenUserProfile?>(
        stream: UserRepository().watch(uid),
        builder: (context, snapshot) {
          final p = snapshot.data;
          final name = p?.displayName ?? 'AUREN User';
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name),
            subtitle: Text(uid, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: p == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AurenPublicProfileScreen(profile: p)),
                    ),
          );
        },
      );
}