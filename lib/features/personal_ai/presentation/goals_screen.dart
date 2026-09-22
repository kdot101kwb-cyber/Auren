import 'package:flutter/material.dart';
import '../../../core/models/goal.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenGoalsScreen extends StatefulWidget {
  const AurenGoalsScreen({super.key});
  @override State<AurenGoalsScreen> createState() => _AurenGoalsScreenState();
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyGoals({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.flag_outlined, size: 52),
      const SizedBox(height: 12),
      const Text('أضف أول هدف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('AUREN يساعدك تحوّل الهدف إلى خطوات قابلة للتنفيذ.', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('إنشاء هدف')),
    ]),
  ));
}

class _AurenGoalsScreenState extends State<AurenGoalsScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = GoalRepository();
  bool _creating = false;

  Future<void> _updateProgress(String uid, AurenGoal goal) async {
    var progress = goal.progress.clamp(0, 100);
    final result = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('تحديث: ${goal.title}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$progress%'),
            Slider(value: progress.toDouble(), min: 0, max: 100, divisions: 20, label: '$progress%', onChanged: (v) => setDialogState(() => progress = v.round())),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, progress), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (result == null) return;
    final now = DateTime.now();
    await _repo.upsert(uid, AurenGoal(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      progress: result,
      status: result >= 100 ? 'completed' : goal.status,
      createdAt: goal.createdAt,
      updatedAt: now,
    ));
  }

  Future<void> _add(String uid) async {
    final controller = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New goal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Goal')),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Why / details')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim().isNotEmpty), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _creating = true);
    final now = DateTime.now();
    try {
      await _repo.upsert(uid, AurenGoal(
      id: 'goal_${now.microsecondsSinceEpoch}',
      title: controller.text.trim(),
      description: description.text.trim().isEmpty ? null : description.text.trim(),
      progress: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
      ));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Goal → Reality'), actions: [
        IconButton(onPressed: _creating ? null : () => _add(uid), icon: const Icon(Icons.add)),
      ]),
      body: StreamBuilder<List<AurenGoal>>(
        stream: _repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load goals: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final goals = snapshot.data!;
          if (goals.isEmpty) return _EmptyGoals(onAdd: _creating ? null : () => _add(uid));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (_, i) {
              final goal = goals[i];
              return Card(
                child: ListTile(
                  title: Text(goal.title),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (goal.description != null) Text(goal.description!),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: goal.progress / 100),
                    const SizedBox(height: 4),
                    Text('${goal.progress}%'),
                  ]),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'progress') {
                        await _updateProgress(uid, goal);
                      } else if (value == 'ask') {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MessengerScreen(
                            initialPrompt: 'هذا هدفي: "${goal.title}". ${goal.description ?? ''}\\nحوّله إلى خطة عملية، وحدد أول 3 خطوات ومؤشرات التقدم.',
                          ),
                        ));
                      } else if (value == 'delete') {
                        await _repo.delete(uid, goal.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'progress', child: Text('تحديث التقدم')),
                      PopupMenuItem(value: 'ask', child: Text('خلّي AUREN يخطط له')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
