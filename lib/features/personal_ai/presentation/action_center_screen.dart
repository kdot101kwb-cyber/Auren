import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/actions/action_repository.dart';
import '../../../core/models/action_request.dart';

class AurenActionCenterScreen extends StatelessWidget {
  const AurenActionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required.')));
    final repo = ActionRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Action Center')),
      body: StreamBuilder<List<AurenActionRequest>>(
        stream: repo.watchPending(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load actions: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final actions = snapshot.data!;
          if (actions.isEmpty) return const Center(child: Text('ما عندك أوامر معلّقة.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(a.title),
                  subtitle: Text(a.description),
                  isThreeLine: true,
                  trailing: Wrap(children: [
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: () => repo.setStatus(uid, a.id, 'rejected'),
                      icon: const Icon(Icons.close),
                    ),
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: () => repo.setStatus(uid, a.id, 'approved'),
                      icon: const Icon(Icons.check),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
