import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/memory/memory_timeline_repository.dart';

class AurenMemoryTimelineScreen extends StatelessWidget {
  const AurenMemoryTimelineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Timeline')),
      body: uid == null ? const Center(child: Text('Please sign in first.')) : StreamBuilder<List<AurenMemoryTimelineEvent>>(
        stream: MemoryTimelineRepository().watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل السجل: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!;
          if (events.isEmpty) return const Center(child: Text('لسه ما عندك سجل تغييرات للذاكرة.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = events[i];
              final icon = e.action == 'created' ? Icons.add_circle_outline : e.action == 'deleted' ? Icons.delete_outline : Icons.edit_note_outlined;
              return Card(child: ListTile(
                leading: Icon(icon),
                title: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(e.value, maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: Text(_date(e.createdAt)),
              ));
            },
          );
        },
      ),
    );
  }
  static String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }
}