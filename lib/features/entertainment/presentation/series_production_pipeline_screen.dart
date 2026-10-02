import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/entertainment_repository.dart';

class SeriesProductionPipelineScreen extends StatelessWidget {
  final String projectId;
  const SeriesProductionPipelineScreen({super.key, required this.projectId});

  static const _stages = <String>[
    'series_blueprint_ready',
    'episode_bibles_ready',
    'scenes_ready',
    'asset_manifest_ready',
    'ready_for_render',
    'render_queue_ready',
    'generation',
    'output',
    'qc',
    'ready',
  ];

  String _label(String stage) {
    const labels = {
      'series_blueprint_ready': 'مخطط المسلسل جاهز',
      'episode_bibles_ready': 'ملفات الحلقات جاهزة',
      'scenes_ready': 'المشاهد جاهزة',
      'asset_manifest_ready': 'قائمة الأصول جاهزة',
      'ready_for_render': 'جاهز للرندر',
      'render_queue_ready': 'في طابور الرندر',
      'generation': 'التوليد',
      'output': 'إنتاج المخرجات',
      'qc': 'مراجعة الجودة',
      'ready': 'جاهز للنشر',
    };
    return labels[stage] ?? stage;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('يجب تسجيل الدخول لعرض خط الإنتاج.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Series Production Pipeline')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: EntertainmentRepository().watchEntertainmentCreationJob(uid, projectId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل خط الإنتاج: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('مهمة إنتاج المسلسل غير موجودة.'));
          }

          final stage = data['productionStage']?.toString() ?? 'planning';
          final progress = ((data['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100);
          final status = data['status']?.toString() ?? '';
          final failed = status == 'failed' || stage.endsWith('_failed') || stage == 'production_failed';
          final currentIndex = _stages.indexOf(stage);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data['title']?.toString().trim().isNotEmpty == true
                    ? data['title'].toString()
                    : 'مسلسل AUREN',
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 8),
              Text(
                failed
                    ? 'حدث فشل في مرحلة الإنتاج • ${progress.round()}%'
                    : '${_label(stage)} • ${progress.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: failed ? Theme.of(context).colorScheme.error : null,
                ),
              ),
              if (data['productionError']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
                    title: const Text('تفاصيل الخطأ'),
                    subtitle: Text(data['productionError'].toString()),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ..._stages.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final done = !failed && currentIndex >= 0 && index < currentIndex;
                final active = item == stage && !failed;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : active
                              ? Icons.play_circle_fill_rounded
                              : failed && item == stage
                                  ? Icons.error_rounded
                                  : Icons.schedule_rounded,
                    ),
                    title: Text(_label(item)),
                    subtitle: Text(
                      done
                          ? 'مكتملة'
                          : active
                              ? 'قيد التنفيذ'
                              : failed && item == stage
                                  ? 'فشلت هذه المرحلة'
                                  : 'في الانتظار',
                    ),
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
