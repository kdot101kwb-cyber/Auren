import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenWatchHistoryScreen extends StatelessWidget {
  const AurenWatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لعرض سجل المشاهدة.')));
    }
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المشاهدة')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.watchHistory(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل السجل: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? const <Map<String, dynamic>>[];
          if (entries.isEmpty) {
            return const Center(child: Text('لم تشاهد محتوى بعد.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final e = entries[index];
              final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
              final completed = e['completed'] == true;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: e['imageUrl']?.toString().isNotEmpty == true
                      ? CircleAvatar(backgroundImage: NetworkImage(e['imageUrl'].toString()))
                      : const CircleAvatar(child: Icon(Icons.history)),
                  title: Text(e['title']?.toString() ?? 'محتوى'),
                  subtitle: Text(completed ? 'تمت المشاهدة' : '${(progress * 100).round()}% تمت مشاهدته'),
                  trailing: Icon(completed ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AurenEntertainmentDetailScreen(itemId: e['id'].toString()),
                    ),
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
