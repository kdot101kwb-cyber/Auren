import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nova_autonomous_brain.dart';

class NovaAutonomousBrainScreen extends StatefulWidget {
  const NovaAutonomousBrainScreen({super.key});

  @override
  State<NovaAutonomousBrainScreen> createState() =>
      _NovaAutonomousBrainScreenState();
}

class _NovaAutonomousBrainScreenState extends State<NovaAutonomousBrainScreen> {
  static const _storageKey = 'nova.autonomous.brain.tasks.v1';
  final _goalController = TextEditingController();
  final _planner = const NovaAutonomousPlanner();
  List<NovaBrainTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final tasks = decodeNovaBrainTasks(preferences.getString(_storageKey));
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTasks() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, encodeNovaBrainTasks(_tasks));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ حالة العقل على هذا الجهاز')),
      );
    }
  }

  Future<void> _createPlan() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب النتيجة التي تريد من NOVA تحقيقها')),
      );
      return;
    }
    try {
      final plan = _planner.plan(goal);
      setState(() {
        _tasks = [plan, ..._tasks];
        _goalController.clear();
      });
      await _saveTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أنشأ NOVA خطة من ${plan.steps.length} خطوات. التنفيذ الخارجي يحتاج أدوات موصولة.')),
      );
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الهدف غير صالح')),
      );
    }
  }

  Future<String?> _askForEvidence(NovaBrainStep step) async {
    final controller = TextEditingController(text: step.evidence);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دليل التحقق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('اكتب رابط اختبار أو وصفاً واضحاً للدليل الذي يثبت نجاح الخطوة. لا تضع أسراراً هنا.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الدليل',
                hintText: 'مثال: رابط CI ناجح أو نتيجة فحص موثقة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final evidence = controller.text.trim();
              if (evidence.isNotEmpty) Navigator.pop(context, evidence);
            },
            child: const Text('حفظ الدليل'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _markStepVerified(int taskIndex, int stepIndex) async {
    final task = _tasks[taskIndex];
    final step = task.steps[stepIndex];
    final evidence = await _askForEvidence(step);
    if (!mounted || evidence == null || evidence.trim().isEmpty) return;

    final updatedSteps = [...task.steps];
    updatedSteps[stepIndex] = step.copyWith(
      status: NovaStepStatus.succeeded,
      evidence: evidence.trim(),
    );
    final updatedTasks = [..._tasks];
    updatedTasks[taskIndex] = task.copyWith(steps: updatedSteps);
    setState(() => _tasks = updatedTasks);
    await _saveTasks();
  }

  Future<void> _resetStep(int taskIndex, int stepIndex) async {
    final task = _tasks[taskIndex];
    final updatedSteps = [...task.steps];
    updatedSteps[stepIndex] = updatedSteps[stepIndex].copyWith(
      status: NovaStepStatus.pending,
      evidence: '',
    );
    final updatedTasks = [..._tasks];
    updatedTasks[taskIndex] = task.copyWith(steps: updatedSteps);
    setState(() => _tasks = updatedTasks);
    await _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task.isComplete).length;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF352969), Color(0xFF202039)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_alt, size: 30),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'العقل التنفيذي الذاتي',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('اكتب النتيجة المطلوبة. NOVA يقسمها إلى خطة، يحفظ تقدمها، ولا يعتبر أي خطوة ناجحة دون دليل.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _goalController,
                  minLines: 2,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'ما النتيجة التي تريد تحقيقها؟',
                    hintText: 'مثال: افحص فشل بناء AUREN وحدد السبب وخطة إصلاح واختبار تحقق',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onSubmitted: (_) => _createPlan(),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _createPlan,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('حلّل الهدف وأنشئ خطة'),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.task_alt),
                        const SizedBox(width: 10),
                        Expanded(child: Text('المهام: ${_tasks.length}')),
                        Text('مكتملة: $completed'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('خطط التنفيذ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_tasks.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('لا توجد خطط بعد. اكتب هدفاً بالأعلى للبدء.'),
                    ),
                  ),
                ...List.generate(_tasks.length, (taskIndex) {
                  final task = _tasks[taskIndex];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(task.goal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                tooltip: 'حذف الخطة',
                                onPressed: () => _deleteTask(taskIndex),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.isComplete
                                ? 'اكتملت الخطوات المسجلة بالدليل'
                                : '${task.completedSteps} من ${task.steps.length} خطوات تم التحقق منها',
                            style: TextStyle(color: task.isComplete ? Colors.greenAccent : Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: task.steps.isEmpty ? 0 : task.completedSteps / task.steps.length,
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(task.steps.length, (stepIndex) {
                            final step = task.steps[stepIndex];
                            final isDone = step.status == NovaStepStatus.succeeded;
                            return Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isDone ? Colors.greenAccent : Colors.white54,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(step.description, style: const TextStyle(color: Colors.white70)),
                                  if (step.evidence.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text('الدليل: ${step.evidence}', style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
                                  ],
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton.icon(
                                      onPressed: isDone
                                          ? () => _resetStep(taskIndex, stepIndex)
                                          : () => _markStepVerified(taskIndex, stepIndex),
                                      icon: Icon(isDone ? Icons.undo : Icons.verified_outlined),
                                      label: Text(isDone ? 'إعادة فتح الخطوة' : 'تسجيل تحقق بدليل'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const Text(
                            'هذه النسخة تنشئ الخطط وتحفظ الأدلة محلياً؛ لا تنفّذ أوامر خارجية تلقائياً حتى تُربط محركات التنفيذ وتُختبر.',
                            style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
