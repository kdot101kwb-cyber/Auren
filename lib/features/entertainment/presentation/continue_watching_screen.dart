import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenContinueWatchingScreen extends StatelessWidget {
  const AurenContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لمتابعة المشاهدة.')));
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Continue Watching')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.watchContinueWatching(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final entries = snapshot.data ?? const <Map<String, dynamic>>[];
          if (entries.isEmpty) return const Center(child: Text('لا توجد مشاهدة متوقفة حالياً.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = entries[i];
              final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
              return Card(child: ListTile(
                title: Text(e['title']?.toString() ?? 'محتوى'),
                subtitle: Text('${(progress * 100).round()}% مكتمل'),
                trailing: SizedBox(width: 90, child: LinearProgressIndicator(value: progress)),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AurenEntertainmentDetailScreen(itemId: e['id'].toString()))),
              ));
            },
          );
        },
      ),
    );
  }
}
