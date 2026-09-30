import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/learning_plan_service.dart';
import '../../../services/education/education_learning_engine.dart';
import '../../messenger/presentation/messenger_screen.dart';

class LearningPlanScreen extends StatefulWidget {
  const LearningPlanScreen({super.key});
  @override State<LearningPlanScreen> createState() => _LearningPlanScreenState();
}

class _LearningPlanScreenState extends State<LearningPlanScreen> {
  final service = LearningPlanService();
  final engine = EducationLearningEngine();
  final subject = TextEditingController();
  final title = TextEditingController();
  int minutes = 30;
  String track = 'School';
  String level = 'Beginner';
  String goal = 'فهم المادة';

  void _aiPlan() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'أنا طالب وأريد خطة مذاكرة ذكية. اسألني عن المرحلة والصف والمادة والاختبار والوقت المتاح، ثم قسّم المنهج إلى دروس صغيرة، واجبات، مراجعة واختبارات، وتابع نقاط ضعفي.')));

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || subject.text.trim().isEmpty) return;
    await service.savePlan(uid: uid, title: title.text.trim().isEmpty ? 'خطة ' + subject.text.trim() : title.text.trim(), track: track, subject: subject.text.trim(), level: level, minutesPerDay: minutes, weeklyGoals: ['الهدف: $goal', 'فهم الدروس', 'حل تمارين', 'مراجعة الأخطاء', 'اختبار قصير']);
    if (mounted) { subject.clear(); title.clear(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ خطة التعلم'))); }
  }

  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    return Scaffold(
      appBar: AppBar(title: const Text('خطتي الدراسية')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('أنشئ خطة بسيطة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم الخطة')),
          const SizedBox(height: 8),
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'المادة أو المهارة')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: track, items: const [DropdownMenuItem(value: 'Languages', child: Text('تعلم لغة')), DropdownMenuItem(value: 'School', child: Text('المدرسة')), DropdownMenuItem(value: 'Institute & Vocational', child: Text('معهد / مهني')), DropdownMenuItem(value: 'Professional Skills', child: Text('مهارة مهنية'))], onChanged: (v) => setState(() => track = v ?? track), decoration: const InputDecoration(labelText: 'المسار')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: level, items: const [DropdownMenuItem(value: 'Beginner', child: Text('مبتدئ')), DropdownMenuItem(value: 'Elementary', child: Text('أساسي')), DropdownMenuItem(value: 'Intermediate', child: Text('متوسط')), DropdownMenuItem(value: 'Advanced', child: Text('متقدم'))], onChanged: (v) => setState(() => level = v ?? level), decoration: const InputDecoration(labelText: 'المستوى')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: goal,
            items: const [
              DropdownMenuItem(value: 'فهم المادة', child: Text('فهم المادة')),
              DropdownMenuItem(value: 'اجتياز اختبار', child: Text('اجتياز اختبار')),
              DropdownMenuItem(value: 'محادثة', child: Text('محادثة')),
              DropdownMenuItem(value: 'مهارة عملية', child: Text('مهارة عملية')),
              DropdownMenuItem(value: 'شهادة مهنية', child: Text('شهادة مهنية')),
            ],
            onChanged: (v) => setState(() => goal = v ?? goal),
            decoration: const InputDecoration(labelText: 'الهدف'),
          ),
          const SizedBox(height: 8),
          Text('الوقت اليومي: $minutes دقيقة'),
          Slider(min: 5, max: 180, divisions: 35, value: minutes.toDouble(), onChanged: (v) => setState(() => minutes = v.round())),
          Row(children: [Expanded(child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ الخطة'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: _aiPlan, icon: const Icon(Icons.auto_awesome), label: const Text('AI Tutor')))]),
        ]))),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(stream: service.watchPlans(uid), builder: (context, snapshot) {
          final plans = snapshot.data ?? const <Map<String, dynamic>>[];
          return Column(children: plans.map((p) {
            final id = p['id']?.toString() ?? '';
            final subjectName = p['subject']?.toString() ?? '';
            final planLevel = p['level']?.toString() ?? 'Beginner';
            final daily = (p['minutesPerDay'] as num?)?.toInt() ?? 30;
            return Card(child: Column(children: [
              ListTile(leading: const Icon(Icons.route), title: Text(p['title']?.toString() ?? 'خطة تعلم'), subtitle: Text('$subjectName • $planLevel • $daily دقيقة يومياً'), trailing: p['status'] == 'completed' ? const Icon(Icons.check_circle) : const Icon(Icons.arrow_forward_ios, size: 16)),
              if (id.isNotEmpty) StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.watchTasks(uid, id),
                builder: (context, taskSnapshot) {
                  final tasks = taskSnapshot.data ?? const <Map<String, dynamic>>[];
                  if (tasks.isEmpty) return Padding(padding: const EdgeInsets.fromLTRB(16,0,16,12), child: FilledButton.icon(onPressed: () => engine.buildNextSteps(uid: uid, planId: id, subject: subjectName, level: planLevel, minutesPerDay: daily), icon: const Icon(Icons.auto_awesome), label: const Text('أنشئ مسار اليوم')));
                  return Padding(padding: const EdgeInsets.fromLTRB(16,0,16,12), child: Column(children: tasks.map((task) {
                    final done = task['completed'] == true;
                    return ListTile(dense: true, leading: Icon(done ? Icons.check_circle : Icons.play_circle_outline), title: Text(task['title']?.toString() ?? ''), subtitle: Text('${task['minutes']?.toString() ?? '5'} دقيقة • ${task['type']?.toString() ?? ''}'), trailing: done ? null : IconButton(icon: const Icon(Icons.check), onPressed: () => service.completeTask(uid, id, task['id'].toString())));
                  }).toList()));
                },
              ),
              if (id.isNotEmpty) Align(alignment: AlignmentDirectional.centerStart, child: Padding(padding: const EdgeInsets.fromLTRB(16,0,16,12), child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: engine.buildNextLessonPrompt(subject: subjectName, level: planLevel)))), icon: const Icon(Icons.auto_awesome), label: const Text('الدرس التالي مع AI')))),
            ]));
          }).toList());
        }),
      ]),
    );
  }

  @override void dispose() { subject.dispose(); title.dispose(); super.dispose(); }
}