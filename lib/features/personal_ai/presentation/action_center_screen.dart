import 'package:cloud_functions/cloud_functions.dart';
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
  final _executor = FirebaseAurenActionExecutor();

  String? _uid;
  String? _busyActionId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final uid = _auth.currentUserId ?? await _auth.signInAnonymously();
      if (mounted) setState(() => _uid = uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تجهيز Action Center: $e')),
        );
      }
    }
  }

  Future<void> _decide(AurenActionRequest action, String decision) async {
    final uid = _uid;
    if (uid == null || _busyActionId != null) return;

    setState(() => _busyActionId = action.id);
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('decideAurenAction')
          .call({'actionId': action.id, 'decision': decision});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decision == 'approved' ? 'تعذرت الموافقة على الأمر: $e' : 'تعذر رفض الأمر: $e')),
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
      // The client only records explicit user approval.
      // The trusted backend is responsible for execution and final status.
      var approvedAction = action;
      if (action.status == 'pending') {
        await _decide(action, 'approved');
        approvedAction = AurenActionRequest(
          id: action.id,
          conversationId: action.conversationId,
          actionType: action.actionType,
          title: action.title,
          description: action.description,
          payload: action.payload,
          permission: action.permission,
          riskLevel: action.riskLevel,
          approvalLevel: action.approvalLevel,
          spendingLimitMinor: action.spendingLimitMinor,
          currency: action.currency,
          requiresApproval: action.requiresApproval,
          status: 'approved',
          result: action.result,
          createdAt: action.createdAt,
        );
      }

      final execution = await _executor.execute(
        uid: uid,
        action: approvedAction,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(execution.result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الأمر للتنفيذ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  Widget _actionCard(AurenActionRequest action, {bool history = false}) {
    final statusLabel = switch (action.status) {
      'completed' => 'اكتمل',
      'failed' => 'فشل التنفيذ',
      'rejected' => 'مرفوض',
      'approved' => 'تمت الموافقة — جاهز للتنفيذ',
      _ => 'بانتظار موافقتك',
    };
    return Card(
      child: ListTile(
        leading: Icon(
          history
              ? (action.status == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.history)
              : Icons.shield_outlined,
        ),
        title: Text(action.title),
        subtitle: Text(
          '${action.description}\n$statusLabel'
          '${action.result == null ? '' : '\n${action.result}'}',
        ),
        isThreeLine: action.result != null || !history,
        trailing: history
            ? null
            : _busyActionId == action.id
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () => _decide(action, 'rejected'),
                        icon: const Icon(Icons.close),
                      ),
                      IconButton(
                        tooltip: action.status == 'approved'
                            ? 'Execute'
                            : 'Approve & execute',
                        onPressed: () => _approve(action),
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
      ),
    );
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
        stream: _repo.watchOutstanding(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load actions: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final actions = snapshot.data!.take(20).toList();
          return StreamBuilder<List<AurenActionRequest>>(
            stream: _repo.watchHistory(uid),
            builder: (context, historySnapshot) {
              if (historySnapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load action history: ${historySnapshot.error}',
                  ),
                );
              }
              final history =
                  (historySnapshot.data ?? const <AurenActionRequest>[]).take(20).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Needs your attention',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (actions.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('ما عندك أوامر معلّقة.'),
                      ),
                    )
                  else
                    ...actions.map(_actionCard),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...history.map(
                      (action) => _actionCard(action, history: true),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
