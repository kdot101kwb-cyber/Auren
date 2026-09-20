import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';

class AurenSavedPulseScreen extends StatelessWidget {
  const AurenSavedPulseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    final saved = FirebaseFirestore.instance.collection('users').doc(uid).collection('savedPosts').orderBy('createdAt', descending: true).limit(50);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Pulse')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: saved.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load saved posts: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ids = snapshot.data!.docs.map((d) => d.id).toList();
          if (ids.isEmpty) return const Center(child: Text('No saved Pulse posts yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: ids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _SavedPost(postId: ids[i]),
          );
        },
      ),
    );
  }
}

class _SavedPost extends StatelessWidget {
  final String postId;
  const _SavedPost({required this.postId});
  @override
  Widget build(BuildContext context) => FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
      final data = snapshot.data!.data();
      if (data == null) return const SizedBox.shrink();
      final type = data['contentType']?.toString() ?? 'moment';
      final text = data['text']?.toString() ?? '';
      final author = data['authorId']?.toString() ?? '';
      return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.bookmark)), title: Text(type.toUpperCase()), subtitle: Text(text.isEmpty ? 'Saved post' : text, maxLines: 3, overflow: TextOverflow.ellipsis), trailing: Text(author, maxLines: 1, overflow: TextOverflow.ellipsis)));
    },
  );
}