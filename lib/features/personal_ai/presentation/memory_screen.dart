import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/memory/memory_repository.dart';
import '../../../core/models/memory_item.dart';

class AurenMemoryScreen extends StatelessWidget {
  const AurenMemoryScreen({super.key});

  Future<void> _add(BuildContext context, String uid) async {
    final key = TextEditingController();
    final value = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add memory'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: key, decoration: const InputDecoration(labelText: 'What')),
          TextField(controller: value, decoration: const InputDecoration(labelText: 'Value')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, key.text.trim().isNotEmpty && value.text.trim().isNotEmpty), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await MemoryRepository().upsert(uid, AurenMemoryItem(
      id: 'memory_${DateTime.now().microsecondsSinceEpoch}',
      key: key.text.trim(),
      value: value.text.trim(),
      enabled: true,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required.')));
    final repo = MemoryRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Memory'),
        actions: [IconButton(onPressed: () => _add(context, uid), icon: const Icon(Icons.add))],
      ),
      body: StreamBuilder<List<AurenMemoryItem>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load memory: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('لسه ما حفظنا أي معلومات.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                child: SwitchListTile(
                  title: Text(item.key),
                  subtitle: Text(item.value),
                  value: item.enabled,
                  onChanged: (enabled) => repo.upsert(uid, AurenMemoryItem(
                    id: item.id, key: item.key, value: item.value,
                    enabled: enabled, updatedAt: DateTime.now(),
                  )),
                  secondary: IconButton(
                    onPressed: () => repo.delete(uid, item.id),
                    icon: const Icon(Icons.delete_outline),
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
