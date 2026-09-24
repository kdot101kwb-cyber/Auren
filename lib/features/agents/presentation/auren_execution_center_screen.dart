import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/agent_task.dart';
import '../../../services/agents/agent_collaboration_repository.dart';

class AurenExecutionCenterScreen extends StatelessWidget {
  const AurenExecutionCenterScreen({super.key});

  Color _statusColor(BuildContext context, String status) {
    if (status == 'completed') return Colors.green;
    if (status == 'approved') return Colors.blue;
    if (status == 'failed') return Colors.red;
    if (status == 'cancelled') return Colors.grey;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    }
    final repo = AurenAgentCollaborationRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Execution Center')),
      body: StreamBuilder<List<AurenAgentTask>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المهام: ${snapshot.error}'));
          }
          final tasks = snapshot.data ?? const <AurenAgentTask>[];
          if (tasks.isEmpty) {
            return const Center(child: Text('لا توجد مهام وكلاء حتى الآن.'));
          }
          final counts = <String, int>{};
          for (final task in tasks) {
            counts[task.status] = (counts[task.status] ?? 0) + 1;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      _CountChip(label: 'الكل', value: tasks.length),
                      _CountChip(label: 'بانتظار الموافقة', value: counts['proposed'] ?? 0),
                      _CountChip(label: 'جاهز للتنفيذ', value: counts['approved'] ?? 0),
                      _CountChip(label: 'مكتمل', value: counts['completed'] ?? 0),
                      _CountChip(label: 'فشل', value: counts['failed'] ?? 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...tasks.map((task) => Card(
                child: ListTile(
                  onTap: () => _showTask(context, repo, task),
                  leading: CircleAvatar(
                    child: Icon(task.status == 'completed'
                        ? Icons.check
                        : task.status == 'failed'
                            ? Icons.error_outline
                            : Icons.smart_toy_outlined),
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.sourceAgent} → ${task.targetAgent}\nالحالة: ${task.status}',
                  ),
                  isThreeLine: true,
                  trailing: task.requiresApproval
                      ? Text('موافقة', style: TextStyle(color: _statusColor(context, task.status)))
                      : null,
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTask(BuildContext context, AurenAgentCollaborationRepository repo, AurenAgentTask task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('${task.sourceAgent} → ${task.targetAgent}'),
              Text('الحالة: ${task.status}'),
              if (task.input.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('بيانات المهمة'),
                const SizedBox(height: 4),
                Text(task.input.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
              ],
              if (task.output.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('النتيجة'),
                const SizedBox(height: 4),
                Text(task.output.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
              ],
              const SizedBox(height: 16),
              if (task.status == 'proposed')
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () async {
                      await repo.decide(task.id, 'cancelled');
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(
                    onPressed: () async {
                      await repo.decide(task.id, 'approved');
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('موافقة'),
                  )),
                ]),
              if (task.status == 'approved')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await repo.execute(task.id, output: {
                        'source': task.sourceAgent,
                        'target': task.targetAgent,
                        'workflowId': task.input['workflowId'],
                        'step': task.input['step'],
                        'message': 'تم التنفيذ بعد موافقة المستخدم.',
                      });
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('تنفيذ المهمة'),
                  ),
                ),
              if (task.status == 'completed')
                const Text('تم التنفيذ وتسجيل النتيجة في سجل AUREN.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  const _CountChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
