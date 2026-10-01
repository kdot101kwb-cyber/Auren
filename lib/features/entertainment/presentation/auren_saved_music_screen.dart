import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_audio_player_screen.dart';

class AurenSavedMusicScreen extends StatelessWidget {
  const AurenSavedMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final repo = EntertainmentRepository();

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول للوصول إلى الموسيقى المحفوظة.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Music'), actions: [IconButton(tooltip: 'تحديث', icon: const Icon(Icons.refresh_rounded), onPressed: () => setState(() {}))]),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchSavedItems(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المحفوظات: ${snapshot.error}'));
          }
          final items = (snapshot.data ?? const <AurenEntertainmentItem>[])
              .where((item) => item.type == 'Music')
              .toList();
          if (items.isEmpty) {
            return const Center(
              child: Text('لا توجد موسيقى محفوظة بعد.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: item.imageUrl.isEmpty
                      ? const CircleAvatar(child: Icon(Icons.music_note))
                      : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                  title: Text(item.title),
                  subtitle: Text(
                    item.description.isEmpty ? 'Music' : item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: item.mediaUrl.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AurenAudioPlayerScreen(item: item),
                            ),
                          ),
                  trailing: IconButton(
                    tooltip: 'إزالة من المحفوظات',
                    icon: const Icon(Icons.bookmark_remove_rounded),
                    onPressed: () async {
                      await repo.unsave(uid, item.id);
                      await repo.trackMusicAction(
                        uid,
                        item.id,
                        action: 'unsave',
                        contentType: item.type,
                      );
                    },
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
