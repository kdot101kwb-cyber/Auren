import 'package:flutter/material.dart';
import '../../../core/models/goal.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/goals/goal_repository.dart';

class AurenGoalsScreen extends StatefulWidget {
  const AurenGoalsScreen({super.key});
  @override State<AurenGoalsScreen> createState() => _AurenGoalsScreenState();
}

class _AurenGoalsScreenState extends State<AurenGoalsScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = GoalRepository();

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
    final now = DateTime.now();
    await _repo.upsert(uid, AurenGoal(
      id: 'goal_${now.microsecondsSinceEpoch}',
      title: controller.text.trim(),
      description: description.text.trim().isEmpty ? null : description.text.trim(),
      progress: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Goal → Reality'), actions: [
        IconButton(onPressed: () => _add(uid), icon: const Icon(Icons.add)),
      ]),
      body: StreamBuilder<List<AurenGoal>>(
        stream: _repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load goals: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final goals = snapshot.data!;
          if (goals.isEmpty) return const Center(child: Text('أضف أول هدف، وخلّي AUREN يحوّله لخطة.'));
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _repo.delete(uid, goal.id),
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
