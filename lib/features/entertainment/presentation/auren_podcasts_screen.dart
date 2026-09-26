import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_audio_player_screen.dart';

class AurenPodcastsScreen extends StatelessWidget {
  const AurenPodcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Podcasts')),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Podcast'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المحتوى: \${snapshot.error}'));
          }
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد حلقات Podcast مضافة بعد.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: item.imageUrl.isEmpty
                      ? const CircleAvatar(child: Icon(Icons.podcasts))
                      : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                  title: Text(item.title),
                  subtitle: Text(item.description, maxLines: 2),
                  trailing: uid == null ? null : IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () => repo.save(uid, item.id),
                  ),
                  onTap: item.mediaUrl.isEmpty ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
