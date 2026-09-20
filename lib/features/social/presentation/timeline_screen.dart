import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';

class AurenTimelineScreen extends StatelessWidget {
  const AurenTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAurenAuthService();
    final uid = auth.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Social'),
        actions: [
          IconButton(
            tooltip: 'Create post',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()),
            ),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AurenCreatePostScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in required'))
          : StreamBuilder<List<AurenPost>>(
              stream: PostRepository().watchFeed(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load AUREN Social: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!;
                if (posts.isEmpty) {
                  return const Center(child: Text('ابدأ أول منشور في AUREN'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: posts.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) return const _StoriesStrip();
                    return _PostCard(post: posts[i - 1], uid: uid);
                  },
                );
              },
            ),
    );
  }
}

class _StoriesStrip extends StatelessWidget {
  const _StoriesStrip();

  @override
  Widget build(BuildContext context) {
    final stories = ['Your story', 'AUREN AI', 'Creators', 'Nearby', 'Friends'];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 2),
              ),
              child: CircleAvatar(
                child: Icon(i == 0 ? Icons.add : Icons.person_outline),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 74,
              child: Text(
                stories[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(
              post.authorId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.more_horiz),
          ),
          if (post.mediaUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: Icon(Icons.broken_image_outlined, size: 42)),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                StreamBuilder<bool>(
                  stream: repo.watchLiked(post.id, uid),
                  builder: (context, s) {
                    final liked = s.data ?? false;
                    return IconButton(
                      onPressed: s.connectionState == ConnectionState.waiting
                          ? null
                          : () => repo.toggleLike(post.id, uid, liked),
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        size: 28,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AurenCommentsScreen(postId: post.id),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${post.likes} likes',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Text(post.text),
            ),
        ],
      ),
    );
  }
}