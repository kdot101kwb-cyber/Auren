import 'package:flutter/material.dart';
import '../../../services/learning_skills/auren_learning_intelligence.dart';
import '../../../services/learning_skills/auren_offline_learning.dart';

/// Android-friendly local learning space: text lessons, notes and progress.
class AurenOfflineLearningScreen extends StatefulWidget {
  const AurenOfflineLearningScreen({super.key});

  @override
  State<AurenOfflineLearningScreen> createState() => _AurenOfflineLearningScreenState();
}

class _AurenOfflineLearningScreenState extends State<AurenOfflineLearningScreen> {
  final _offline = AurenOfflineLearning(const AurenSharedPreferencesLearningStore());
  final _goalController = TextEditingController(text: 'Build a useful skill');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _intelligence = const AurenLearningIntelligence();
  String _level = 'beginner';
  int _minutes = 30;
  bool _loading = true;
  List<AurenOfflineLesson> _lessons = const [];
  List<AurenOfflineProgress> _progress = const [];
  AurenLearningPlan? _plan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final lessons = await _offline.lessons();
      final progress = await _offline.progress();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر قراءة المحتوى المحلي. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _addLesson() async {
    _titleController.clear();
    _contentController.clear();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حفظ درس على الجهاز'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _titleController, maxLength: 160, decoration: const InputDecoration(labelText: 'عنوان الدرس')),
            TextField(controller: _contentController, maxLength: AurenOfflineLearning.maxContentCharacters, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'النص (بدون فيديو أو ملفات كبيرة)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ محلياً')),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final now = DateTime.now().toUtc();
      final id = 'local-${now.microsecondsSinceEpoch}';
      await _offline.saveLesson(AurenOfflineLesson(id: id, title: _titleController.text.trim(), content: _contentController.text.trim(), updatedAt: now));
      await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يُحفظ الدرس. تحقق من العنوان وحدود التخزين المحلي.')));
    }
  }

  Future<void> _editNote(AurenOfflineLesson lesson) async {
    final controller = TextEditingController(text: await _offline.noteFor(lesson.id));
    if (!mounted) {
      controller.dispose();
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ملاحظات: ${lesson.title}'),
        content: TextField(controller: controller, autofocus: true, minLines: 3, maxLines: 8, maxLength: AurenOfflineLearning.maxNoteCharacters, decoration: const InputDecoration(hintText: 'ملاحظاتك محفوظة على هذا الجهاز')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (accepted == true) {
      try {
        await _offline.saveNote(lesson.id, controller.text);
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الملاحظة أطول من الحد المسموح.')));
      }
    }
    controller.dispose();
  }

  Future<void> _toggleProgress(AurenOfflineLesson lesson) async {
    final isComplete = _progress.any((item) => item.lessonId == lesson.id && item.completed);
    await _offline.setCompleted(lesson.id, !isComplete);
    await _reload();
  }

  void _buildPlan() {
    try {
      final plan = _intelligence.buildPlan(goal: _goalController.text, level: _level, minutesPerDay: _minutes);
      setState(() {
        _plan = plan;
        _error = null;
      });
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب هدفاً واضحاً للتعلم.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final completeCount = _progress.where((item) => item.completed).length;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Offline Learning'), actions: [
        IconButton(tooltip: 'حفظ درس', onPressed: _addLesson, icon: const Icon(Icons.note_add_outlined)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('خطة تعلم خفيفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _goalController, maxLength: 120, decoration: const InputDecoration(labelText: 'هدفك')),
                DropdownButtonFormField<String>(value: _level, decoration: const InputDecoration(labelText: 'مستواك'), items: const [
                  DropdownMenuItem(value: 'beginner', child: Text('مبتدئ')),
                  DropdownMenuItem(value: 'intermediate', child: Text('متوسط')),
                  DropdownMenuItem(value: 'advanced', child: Text('متقدم')),
                ], onChanged: (value) => setState(() => _level = value ?? 'beginner')),
                const SizedBox(height: 12),
                Text('الوقت اليومي: $_minutes دقيقة'),
                Slider(value: _minutes.toDouble(), min: 5, max: 180, divisions: 35, label: '$_minutes دقيقة', onChanged: (value) => setState(() => _minutes = value.round())),
                FilledButton.icon(onPressed: _buildPlan, icon: const Icon(Icons.auto_awesome), label: const Text('أنشئ خطة بدون إنترنت')),
                if (_plan != null) ...[
                  const Divider(),
                  Text('${_plan!.goal} • ${_plan!.totalMinutes} دقيقة'),
                  ..._plan!.steps.map((step) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline), title: Text(step.title), subtitle: Text('${step.minutes} دقيقة • ${step.level}'))),
                ],
              ]))),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مكتبتك المحلية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_lessons.length} درس محفوظ • $completeCount مكتمل'),
                const SizedBox(height: 8),
                const Text('النصوص والملاحظات والتقدم تبقى على هذا الجهاز. لا تُحمّل فيديوهات ولا تُزامَن تلقائياً.'),
              ]))),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_lessons.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد دروس محلية بعد. استخدم زر إضافة درس لحفظ نص صغير يعمل دون اتصال.')))
              else
                ..._lessons.map((lesson) {
                  final completed = _progress.any((item) => item.lessonId == lesson.id && item.completed);
                  return Card(child: ExpansionTile(
                    leading: Icon(completed ? Icons.check_circle : Icons.menu_book_outlined),
                    title: Text(lesson.title),
                    subtitle: Text(completed ? 'مكتمل' : 'غير مكتمل'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(alignment: AlignmentDirectional.centerStart, child: Text(lesson.content)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        OutlinedButton.icon(onPressed: () => _editNote(lesson), icon: const Icon(Icons.edit_note), label: const Text('الملاحظات')),
                        OutlinedButton.icon(onPressed: () => _toggleProgress(lesson), icon: Icon(completed ? Icons.undo : Icons.check), label: Text(completed ? 'إلغاء الإكمال' : 'إكمال الدرس')),
                        IconButton(tooltip: 'حذف الدرس المحلي', onPressed: () async { await _offline.removeLesson(lesson.id); await _reload(); }, icon: const Icon(Icons.delete_outline)),
                      ]),
                    ],
                  ));
                }),
            ]),
    );
  }
}
