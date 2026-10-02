import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/kids/kids_activities_repository.dart';

class AurenKidsActivitiesScreen extends StatelessWidget {
  const AurenKidsActivitiesScreen({super.key, required this.ageBand, this.category});
  final int ageBand;
  final String? category;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام أنشطة AUREN Kids.')));
    final repo = KidsActivitiesRepository();
    return Scaffold(
      appBar: AppBar(title: Text(category == null ? 'Kids Activities' : 'Kids · $category')),
      body: StreamBuilder<List<KidsActivity>>(
        stream: repo.watchActivities(ageBand),
        builder: (context, a) {
          if (a.hasError) return const Center(child: Text('تعذر تحميل الأنشطة حالياً.'));
          if (!a.hasData) return const Center(child: CircularProgressIndicator());
          return StreamBuilder<KidsActivityProgress>(
            stream: repo.watchProgress(uid),
            builder: (context, p) {
              final done = p.data?.completedIds ?? <String>{};
              final items = a.data!
                  .where((item) => category == null || item.category == category)
                  .toList();
              if (items.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد أنشطة منشورة لهذه الفئة العمرية حالياً.')));
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: Text('تعلم اليوم · ${items.where((x) => done.contains(x.id)).length}/${items.length}'), subtitle: Text(category == null
                      ? 'أنشطة مناسبة للفئة $ageBand+'
                      : 'أنشطة $category مناسبة للفئة $ageBand+'))),
                  const SizedBox(height: 12),
                  ...items.map((x) {
                    final isDone = done.contains(x.id);
                    return Card(child: ListTile(leading: Icon(isDone ? Icons.check_circle : Icons.play_circle_outline), title: Text(x.title), subtitle: Text('${x.description}\n${x.minutes} دقيقة · ${x.category}'), isThreeLine: true, trailing: Checkbox(value: isDone, onChanged: (v) => repo.setCompleted(uid: uid, activityId: x.id, completed: v ?? false))));
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
