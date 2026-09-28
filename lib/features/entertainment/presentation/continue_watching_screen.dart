import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';
import 'auren_entertainment_output_screen.dart';

class AurenContinueWatchingScreen extends StatelessWidget {
  const AurenContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لمتابعة المشاهدة.')));
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Continue Watching')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Continue Watching', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchContinueWatching(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final entries = snapshot.data ?? const <Map<String, dynamic>>[];
              if (entries.isEmpty) return const Card(child: ListTile(title: Text('لا توجد مشاهدة متوقفة للمحتوى العادي.')));
              return Column(children: entries.take(10).map((e) {
                final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
                return Card(child: ListTile(
                  title: Text(e['title']?.toString() ?? 'محتوى'),
                  subtitle: Text('${(progress * 100).round()}% مكتمل'),
                  trailing: SizedBox(width: 80, child: LinearProgressIndicator(value: progress)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AurenEntertainmentDetailScreen(itemId: e['id'].toString()))),
                ));
              }).toList());
            },
          ),
          const SizedBox(height: 24),
          const Text('مسلسلاتك — متابعة المشاهدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchSeriesWatchProgress(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final entries = snapshot.data ?? const <Map<String, dynamic>>[];
              final active = entries.where((e) => e['completed'] != true && ((e['progress'] as num?)?.toDouble() ?? 0) > 0.02).take(10).toList();
              if (active.isEmpty) return const Card(child: ListTile(title: Text('لا توجد حلقات متوقفة حالياً.')));
              return Column(children: active.map((e) {
                final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
                final episode = e['episodeNumber']?.toString() ?? '?';
                final jobId = e['jobId']?.toString() ?? '';
                final videoUrl = e['videoUrl']?.toString() ?? '';
                return Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                  title: Text(e['title']?.toString().isNotEmpty == true ? e['title'].toString() : 'مسلسل AUREN'),
                  subtitle: Text('الحلقة $episode • ${(progress * 100).round()}% مكتمل'),
                  trailing: SizedBox(width: 70, child: LinearProgressIndicator(value: progress)),
                  onTap: videoUrl.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AurenEntertainmentOutputScreen(
                      output: {'url': videoUrl, 'type': 'video', 'mimeType': 'video/mp4'},
                      title: e['title']?.toString() ?? 'مسلسل AUREN',
                      episodeLabel: 'الحلقة $episode',
                      watchUid: uid,
                      watchJobId: jobId,
                      watchEpisodeNumber: int.tryParse(episode) ?? 1,
                      watchTitle: e['title']?.toString(),
                    ),
                  )),
                ));
              }).toList());
            },
          ),
        ],
      ),
    );
  }
}
