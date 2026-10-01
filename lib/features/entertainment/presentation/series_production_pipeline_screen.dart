import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/series_production_service.dart';

class SeriesProductionPipelineScreen extends StatelessWidget {
  final String projectId;
  const SeriesProductionPipelineScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول لعرض المشروع.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Series Production Pipeline')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: SeriesProductionService().watchProject(uid, projectId),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل خط الإنتاج: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (data == null) return const Center(child: Text('المشروع غير موجود.'));
          final progress = ((data['progress'] as num?)?.toDouble() ?? 0) / 100;
          final stages = (data['stages'] as List?)?.map((e) => e.toString()).toList() ?? const [];
          final current = data['stage']?.toString() ?? '';
          final currentIndex = stages.indexOf(current);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(data['title']?.toString() ?? 'Series', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(current + ' • ' + (progress * 100).round().toString() + '%'),
              const SizedBox(height: 18),
              ...stages.asMap().entries.map((entry) {
                final index = entry.key;
                final stage = entry.value;
                final done = currentIndex >= 0 && index < currentIndex;
                final active = stage == current;
                return Card(
                  child: ListTile(
                    leading: Icon(done ? Icons.check_circle : active ? Icons.play_circle : Icons.schedule),
                    title: Text(stage),
                    subtitle: Text(done ? 'مكتملة' : active ? 'قيد التنفيذ' : 'في الانتظار'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
