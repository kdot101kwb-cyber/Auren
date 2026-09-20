import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/post_repository.dart';

class AurenSavedPulseScreen extends StatelessWidget {
  const AurenSavedPulseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }
    final saved = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Pulse')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: saved.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load saved posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = snapshot.data!.docs.map((d) => d.id).toList();
          if (ids.isEmpty) {
            return const Center(child: Text('No saved Pulse posts yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _SavedPost(postId: ids[i], uid: uid),
          );
        },
      ),
    );
  }
}

class _SavedPost extends StatelessWidget {
  final String postId;
  final String uid;

  const _SavedPost({required this.postId, required this.uid});

  Future<void> _unsave(BuildContext context) async {
    await PostRepository().removeSaved(postId, uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Saved Pulse.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Post unavailable'),
              subtitle: const Text('This Pulse post may have been deleted.'),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _unsave(context),
              ),
            ),
          );
        }

        final type = data['contentType']?.toString() ?? 'moment';
        final text = data['text']?.toString() ?? '';
        final author = data['authorId']?.toString() ?? '';
        final mediaUrl = data['mediaUrl']?.toString() ?? '';

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.bookmark)),
                title: Text(type.toUpperCase()),
                subtitle: Text(
                  author.isEmpty ? 'Saved Pulse' : 'By $author',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Unsave',
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  onPressed: () => _unsave(context),
                ),
              ),
              if (text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(text, maxLines: 6, overflow: TextOverflow.ellipsis),
                ),
              if (mediaUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      mediaUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 80,
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
