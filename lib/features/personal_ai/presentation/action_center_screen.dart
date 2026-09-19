import 'package:flutter/material.dart';

import '../../../core/models/action_request.dart';
import '../../../services/actions/action_executor.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/auth/auth_service.dart';

class AurenActionCenterScreen extends StatefulWidget {
  const AurenActionCenterScreen({super.key});

  @override
  State<AurenActionCenterScreen> createState() =>
      _AurenActionCenterScreenState();
}

class _AurenActionCenterScreenState extends State<AurenActionCenterScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = ActionRepository();
  final _executor = HttpsAurenActionExecutor();

  String? _uid;
  String? _busyActionId;

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUserId;
  }

  Future<void> _reject(AurenActionRequest action) async {
    final uid = _uid;
    if (uid == null || _busyActionId != null) return;

    setState(() => _busyActionId = action.id);
    try {
      await _repo.setStatus(uid, action.id, 'rejected');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر رفض الأمر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  Future<void> _approve(AurenActionRequest action) async {
    final uid = _uid;
    if (uid == null || _busyActionId != null) return;

    setState(() => _busyActionId = action.id);

    try {
      await _repo.setStatus(uid, action.id, 'executing');

      final execution = await _executor.execute(
        uid: uid,
        action: action,
      );

      await _repo.setStatus(
        uid,
        action.id,
        execution.status == 'completed' ? 'completed' : execution.status,
        result: execution.result,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(execution.result)),
        );
      }
    } catch (e) {
      await _repo.setStatus(
        uid,
        action.id,
        'failed',
        result: e.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تنفيذ الأمر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Action Center')),
      body: StreamBuilder<List<AurenActionRequest>>(
        stream: _repo.watchPending(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load actions: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final actions = snapshot.data!;
          if (actions.isEmpty) {
            return const Center(child: Text('ما عندك أوامر معلّقة.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final action = actions[i];
              final busy = _busyActionId == action.id;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(action.title),
                  subtitle: Text(action.description),
                  isThreeLine: true,
                  trailing: busy
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Reject',
                              onPressed: () => _reject(action),
                              icon: const Icon(Icons.close),
                            ),
                            IconButton(
                              tooltip: 'Approve',
                              onPressed: () => _approve(action),
                              icon: const Icon(Icons.check),
                            ),
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
