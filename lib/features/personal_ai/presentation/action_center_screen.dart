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
  static const _knownActions = <String>['demo.echo', 'demo.create_note', 'memory.save'];

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

  Future<void> _decide(AurenActionRequest action, String decision, {bool manageBusy = true}) async {
    final uid = _uid;
    if (uid == null || (_busyActionId != null && _busyActionId != action.id)) return;

    if (manageBusy) setState(() => _busyActionId = action.id);
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('decideAurenAction')
          .call({'actionId': action.id, 'decision': decision});
    } catch (e) {
      rethrow;
    } finally {
      if (manageBusy && mounted) setState(() => _busyActionId = null);
    }
  }

  Future<void> _approve(AurenActionRequest action) async {
    if (_uid == null || _busyActionId != null || action.status != 'pending') return;
    setState(() => _busyActionId = action.id);
    try {
      await _decide(action, 'approved', manageBusy: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الموافقة. اضغط تنفيذ عند استعدادك.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل الموافقة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  Future<void> _execute(AurenActionRequest action) async {
    final uid = _uid;
    if (uid == null || _busyActionId != null || action.status != 'approved') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تنفيذ AUREN'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(action.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(action.description),
              const SizedBox(height: 12),
              Text('الأمر: ' + action.actionType),
              if (action.spendingLimitMinor != null)
                Text('حد العملية: ' + action.spendingLimitMinor.toString() + ' ' + action.currency),
              const SizedBox(height: 12),
              const Text('سيتم التنفيذ الآن بعد موافقتك السابقة.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyActionId = action.id);
    try {
      final execution = await _executor.execute(uid: uid, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(execution.result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تنفيذ الأمر: ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  Widget _securityPanel(String uid) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _repo.watchPermissionLedger(uid),
      builder: (context, permissionSnapshot) {
        final permission = permissionSnapshot.data;
        final enabled = permission?['enabled'] == true;
        final rawAllowed = permission?['allowedActions'];
        final allowed = rawAllowed is List
            ? rawAllowed.whereType<String>().toSet().toList()
            : <String>[];
        final currency = permission?['currency']?.toString() ?? 'USD';
        final dailyLimit = permission?['dailySpendingLimitMinor'];
        final rawSpent = permission?['spentTodayMinor'];
        final spentToday = rawSpent is num ? rawSpent.toInt() : 0;
        return StreamBuilder<Map<String, dynamic>?>(
          stream: _repo.watchTrust(uid),
          builder: (context, trustSnapshot) {
            final trust = trustSnapshot.data;
            final score = trust?['score'] ?? 50;
            final completed = trust?['completedExecutions'] ?? 0;
            final failed = trust?['failedExecutions'] ?? 0;
            return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.shield_outlined), const SizedBox(width: 10), Expanded(child: Text('AUREN Security', style: Theme.of(context).textTheme.titleMedium)), Switch(value: enabled, onChanged: (value) async {
                try { await _repo.setPermissionLedger(uid, enabled: value, allowedActions: allowed, dailySpendingLimitMinor: dailyLimit is num ? dailyLimit.toInt() : null, currency: currency); }
                catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الصلاحيات: $e'))); }
              })]),
              Text(enabled ? 'صلاحيات AUREN مفعّلة' : 'صلاحيات AUREN متوقفة'),
              const SizedBox(height: 12),
              Text('الأوامر المسموح بها', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _knownActions.map((type) {
                  final selected = allowed.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (value) async {
                      final next = {...allowed};
                      if (value) { next.add(type); } else { next.remove(type); }
                      try {
                        await _repo.setPermissionLedger(uid, enabled: enabled, allowedActions: next.toList(), dailySpendingLimitMinor: dailyLimit is num ? dailyLimit.toInt() : null, currency: currency);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الأمر المسموح: $e')));
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text('الحد اليومي', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                  'المستخدم اليوم: $spentToday $currency',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 6),
              TextFormField(
                key: ValueKey('daily-limit-\${dailyLimit ?? 'none'}'),
                initialValue: dailyLimit is num ? dailyLimit.toInt().toString() : '',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 5000',
                  suffixText: currency,
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) async {
                  final parsed = value.trim().isEmpty ? null : int.tryParse(value.trim());
                  if (value.trim().isNotEmpty && parsed == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('أدخل رقمًا صحيحًا للحد اليومي.')),
                    );
                    return;
                  }
                  try {
                    await _repo.setPermissionLedger(
                      uid,
                      enabled: enabled,
                      allowedActions: allowed,
                      dailySpendingLimitMinor: parsed,
                      currency: currency,
                    );
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر تحديث الحد اليومي: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final spent = permission?['spentTodayMinor'] is num
                      ? (permission!['spentTodayMinor'] as num).toInt()
                      : 0;
                  if (dailyLimit is! num) {
                    return Text(
                      'المستخدم اليوم: $spent $currency • لا يوجد حد يومي محدد',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  final limit = dailyLimit.toInt();
                  final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('استخدام الإنفاق اليومي: $spent / $limit $currency'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: ratio),
                      const SizedBox(height: 4),
                      if (spent >= limit && limit > 0)
                        const Text('تم الوصول إلى الحد اليومي.'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Text('Trust: $score/100  •  نجاح $completed  •  فشل $failed'),
              const SizedBox(height: 10),
              Text('العمليات الجديدة تحتاج موافقتك الصريحة قبل التنفيذ.', style: Theme.of(context).textTheme.bodySmall),
            ])));
          },
        );
      },
    );
  }
  Future<void> _recover(AurenActionRequest action) async {
    final uid = _uid;
    if (uid == null || _busyActionId != null || action.status != 'executing') return;
    setState(() => _busyActionId = action.id);
    try {
      final execution = await _executor.recover(uid: uid, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(execution.result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر استرجاع العملية: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyActionId = null);
    }
  }

  Widget _auditPanel(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.watchAudit(uid, limit: 10),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final events = snapshot.data ?? const <Map<String, dynamic>>[];
        if (events.isEmpty) return const SizedBox.shrink();
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('سجل الأمان'),
            subtitle: const Text('آخر تغييرات الموافقة والتنفيذ'),
            children: events.map((event) {
              final status = event['status']?.toString() ?? 'unknown';
              final type = event['actionType']?.toString() ?? 'action';
              final label = switch (status) {
                'approved' => 'تمت الموافقة',
                'rejected' => 'تم الرفض',
                'completed' => 'اكتمل التنفيذ',
                'failed' => 'فشل التنفيذ',
                _ => status,
              };
              return ListTile(
                dense: true,
                leading: Icon(
                  status == 'approved'
                      ? Icons.check_circle_outline
                      : status == 'rejected'
                          ? Icons.cancel_outlined
                          : Icons.history,
                ),
                title: Text(type),
                subtitle: Text(label),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatActionTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
  Widget _actionCard(AurenActionRequest action, {bool history = false}) {
    final statusLabel = switch (action.status) {
      'completed' => 'اكتمل',
      'failed' => 'فشل التنفيذ',
      'rejected' => 'مرفوض',
      'executing' => 'جارٍ التنفيذ — يمكن الاسترجاع بعد اكتمال نافذة الأمان',
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
          '${action.executionStartedAt == null ? '' : '\nبدأ التنفيذ: ' + _formatActionTime(action.executionStartedAt!)}'
          '${action.executionSpendingDay == null ? '' : '\nيوم الإنفاق: ${action.executionSpendingDay}'}'
          '${action.result == null ? '' : '\n${action.result}'}',
        ),
        isThreeLine: action.result != null || !history,
        trailing: history
            ? (action.status == 'executing'
                ? IconButton(
                    tooltip: 'Recover',
                    onPressed: _busyActionId == null ? () => _recover(action) : null,
                    icon: const Icon(Icons.restart_alt),
                  )
                : null)
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
                        onPressed: () async {
                          try {
                            await _decide(action, 'rejected');
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر رفض الأمر: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.close),
                      ),
                      if (action.status == 'pending')
                        IconButton(
                          tooltip: 'Approve',
                          onPressed: () => _approve(action),
                          icon: const Icon(Icons.check),
                        )
                      else if (action.status == 'approved')
                        IconButton(
                          tooltip: 'Execute',
                          onPressed: () => _execute(action),
                          icon: const Icon(Icons.play_arrow),
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
                  _securityPanel(uid),
                  const SizedBox(height: 16),
                  _auditPanel(uid),
                  const SizedBox(height: 8),
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
