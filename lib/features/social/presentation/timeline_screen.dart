import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';
import 'create_post_screen.dart';

class AurenTimelineScreen extends StatelessWidget {
  const AurenTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAurenAuthService();
    final uid = auth.currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Pulse')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCreatePostScreen())),
        child: const Icon(Icons.add),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in required'))
          : StreamBuilder<List<AurenPost>>(
              stream: PostRepository().watchFeed(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Could not load Pulse: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                if (posts.isEmpty) return const Center(child: Text('ابدأ أول Pulse في AUREN'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _PostCard(post: posts[i], uid: uid),
                );
              },
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final AurenPost post;
  final String uid;
  const _PostCard({required this.post, required this.uid});

  @override
  Widget build(BuildContext context) {
    final repo = PostRepository();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.authorId, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(post.text),
          const SizedBox(height: 12),
          StreamBuilder<bool>(
            stream: repo.watchLiked(post.id, uid),
            builder: (context, s) {
              final liked = s.data ?? false;
              return Row(children: [
                IconButton(
                  onPressed: s.connectionState == ConnectionState.waiting ? null : () => repo.toggleLike(post.id, uid, liked),
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined),
                const SizedBox(width: 4),
                Text('${post.comments}'),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}