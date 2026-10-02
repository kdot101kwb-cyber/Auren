import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agents/agent_dispute_repository.dart';

class AgentDisputesScreen extends StatelessWidget {
  const AgentDisputesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: StreamBuilder(
        stream: AurenAgentDisputeRepository().watch(uid),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('لا توجد نزاعات.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: Text(item.reason),
                subtitle: Text('\${item.status} • action: \${item.actionId}'),
              );
            },
          );
        },
      ),
    );
  }
}
