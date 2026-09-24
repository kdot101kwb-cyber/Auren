import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/agent_task.dart';
import '../../../services/agents/agent_collaboration_repository.dart';
import '../../../services/agents/workflow_repository.dart';

class AurenWorkflowDashboardScreen extends StatelessWidget {
  const AurenWorkflowDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    final repo = AurenWorkflowRepository();
    final collaboration = AurenAgentCollaborationRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Workflow Dashboard')),
      body: StreamBuilder<List<AurenWorkflowSummary>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('تعذر تحميل الـWorkflow: ${snapshot.error}'));
          final workflows = snapshot.data ?? const <AurenWorkflowSummary>[];
          if (workflows.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا توجد Workflows محفوظة حتى الآن.\nابدأ خطة من Talent وستظهر هنا تلقائياً.', textAlign: TextAlign.center),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workflows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final w = workflows[i];
              final total = w.totalSteps > 0 ? w.totalSteps : 1;
              final progress = (w.completedSteps / total).clamp(0.0, 1.0);
              return Card(
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _WorkflowDetails(workflow: w, repo: collaboration),
                  )),
                  leading: const CircleAvatar(child: Icon(Icons.account_tree_outlined)),
                  title: Text(w.workflowId),
                  subtitle: Text(
                    'الوكيل الحالي: ${w.currentAgent.isEmpty ? 'غير محدد' : w.currentAgent}\n'
                    'التقدم: ${w.completedSteps}/${w.totalSteps} • فشل: ${w.failedSteps}',
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(width: 72, child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(w.state), const SizedBox(height: 6), LinearProgressIndicator(value: progress)],
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkflowDetails extends StatelessWidget {
  final AurenWorkflowSummary workflow;
  final AurenAgentCollaborationRepository repo;
  const _WorkflowDetails({required this.workflow, required this.repo});

  Future<void> _execute(BuildContext context, AurenAgentTask task) async {\n    try {\n      await repo.execute(task.id, output: {'source': task.sourceAgent, 'target': task.targetAgent, 'workflowId': workflow.workflowId, 'step': (task.input['step'] as num?)?.toInt() ?? 0, 'message': 'تم تنفيذ المرحلة بعد موافقة المستخدم.'});\n      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تنفيذ المرحلة وتحديث الـWorkflow.')));\n    } catch (e) {\n      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ المهمة: $e')));\n    }\n  }\n\n  Future<void> _command(BuildContext context, String command) async {
    try {
      await repo.orchestrate(workflow.workflowId, command: command);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ الأمر: ${e}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الـWorkflow')),
      body: uid == null ? const Center(child: Text('سجّل الدخول أولاً.')) :
      StreamBuilder<List<AurenAgentTask>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          final tasks = (snapshot.data ?? const <AurenAgentTask>[])
              .where((t) => t.input['workflowId'] == workflow.workflowId).toList();
          tasks.sort((a,b) => ((a.input['step'] as num?)?.toInt() ?? 0).compareTo((b.input['step'] as num?)?.toInt() ?? 0));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workflow.workflowId, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('الحالة: ${workflow.state}'),
                  Text('المرحلة: ${workflow.currentStep + 1}/${workflow.totalSteps}'),
                  Text('الوكيل: ${workflow.currentAgent}'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    if (workflow.state != 'paused') OutlinedButton.icon(onPressed: () => _command(context, 'pause'), icon: const Icon(Icons.pause), label: const Text('إيقاف')),
                    if (workflow.state == 'paused') OutlinedButton.icon(onPressed: () => _command(context, 'resume'), icon: const Icon(Icons.play_arrow), label: const Text('استئناف')),
                    if (workflow.failedSteps > 0) TextButton.icon(onPressed: () => _command(context, 'retry'), icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                  ]),
                ],
              ))),
              const SizedBox(height: 8),
              if (tasks.isEmpty) const Card(child: ListTile(title: Text('لا توجد مهام محفوظة.'))),
              ...tasks.map((t) => Card(child: ListTile(
                leading: CircleAvatar(child: Text('${((t.input['step'] as num?)?.toInt() ?? 0) + 1}')),
                title: Text('${t.sourceAgent} → ${t.targetAgent}'),
                subtitle: Text('${t.title}\nالحالة: ${t.status}'),
                isThreeLine: true,
                trailing: t.status == 'proposed'
                    ? Wrap(children: [
                        IconButton(onPressed: () => repo.decide(t.id, 'cancelled'), icon: const Icon(Icons.close)),
                        IconButton(onPressed: () => repo.decide(t.id, 'approved'), icon: const Icon(Icons.check)),
                      ])
                    : t.status == 'approved'\n                        ? IconButton(onPressed: () => _execute(context, t), icon: const Icon(Icons.play_arrow))\n                        : Icon(t.status == 'completed' ? Icons.check_circle : Icons.hourglass_top),
              ))),
            ],
          );
        },
      ),
    );
  }
}
