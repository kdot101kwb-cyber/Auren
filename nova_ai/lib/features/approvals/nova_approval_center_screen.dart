import 'package:flutter/material.dart';

import '../../core/approval/nova_owner_action_queue.dart';

/// Owner review UI for proposed actions. Approval records permission only;
/// this queue has no executor and does not perform external side effects.
class NovaApprovalCenterScreen extends StatefulWidget {
  const NovaApprovalCenterScreen({super.key, this.queue});

  final NovaOwnerActionQueue? queue;

  @override
  State<NovaApprovalCenterScreen> createState() => _NovaApprovalCenterScreenState();
}

class _NovaApprovalCenterScreenState extends State<NovaApprovalCenterScreen> {
  late final NovaOwnerActionQueue _queue = widget.queue ?? NovaOwnerActionQueue();
  List<NovaActionRequest> _records = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() { _loading = true; _error = null; });
    try {
      final records = await _queue.list();
      if (!mounted) return;
      setState(() { _records = records; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذر قراءة سجل الموافقات المحلي.'; });
    }
  }

  Future<void> _addProposal() async {
    final type = TextEditingController();
    final summary = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب موافقة جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: type, textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'نوع الإجراء')),
            TextField(controller: summary, textDirection: TextDirection.rtl,
              minLines: 2, maxLines: 4,
              decoration: const InputDecoration(labelText: 'وصف واضح لما سيحدث')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('إضافة للمراجعة')),
        ],
      ),
    );
    final actionType = type.text.trim();
    final description = summary.text.trim();
    type.dispose();
    summary.dispose();
    if (accepted != true || actionType.isEmpty || description.isEmpty) return;
    final now = DateTime.now().toUtc();
    final saved = await _queue.enqueue(
      id: 'approval-${now.microsecondsSinceEpoch}',
      actionType: actionType,
      summary: description,
      isReadOnly: false,
      externalSideEffect: true,
      sensitive: true,
    );
    if (!saved && mounted) setState(() => _error = 'تعذر إضافة طلب الموافقة.');
    await _reload();
  }

  Future<void> _approve(NovaActionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد موافقة المالك'),
        content: Text('هل توافق على هذا الإجراء؟\n\n${request.summary}\n\nالموافقة لا تنفذ الإجراء تلقائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('أوافق')),
        ],
      ),
    );
    if (confirmed == true) {
      await _queue.approve(request.id, ownerConfirmed: true);
      await _reload();
    }
  }

  Future<void> _reject(NovaActionRequest request) async {
    final reason = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(
          controller: reason,
          autofocus: true,
          textDirection: TextDirection.rtl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'سبب الرفض (مطلوب)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('رفض')),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (submitted == true && value.isNotEmpty) {
      await _queue.reject(request.id, reason: value);
      await _reload();
    }
  }

  String _status(NovaActionStatus status) => switch (status) {
    NovaActionStatus.awaitingApproval => 'بانتظار موافقتك',
    NovaActionStatus.approved => 'موافق عليه',
    NovaActionStatus.rejected => 'مرفوض',
    NovaActionStatus.running => 'قيد التنفيذ',
    NovaActionStatus.completed => 'مكتمل',
    NovaActionStatus.failed => 'فشل',
  };

  @override
  Widget build(BuildContext context) {
    final pending = _records.where((record) => record.status == NovaActionStatus.awaitingApproval).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز موافقات المالك'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'تحديث')],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProposal,
        icon: const Icon(Icons.add_task),
        label: const Text('طلب موافقة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  Card(child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('طلبات تنتظر قرارك'),
                    trailing: Text('$pending', style: Theme.of(context).textTheme.headlineSmall),
                  )),
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_records.isEmpty) const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('لا توجد طلبات موافقة حالياً.')),
                  ),
                  ..._records.map((record) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(child: Text(record.actionType, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Chip(label: Text(_status(record.status))),
                          ]),
                          Text(record.summary, textDirection: TextDirection.rtl),
                          if (record.reason != null) Text('السبب: ${record.reason}', textDirection: TextDirection.rtl),
                          if (record.status == NovaActionStatus.awaitingApproval) Row(
                            children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () => _reject(record),
                                child: const Text('رفض'),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: FilledButton(
                                onPressed: () => _approve(record),
                                child: const Text('موافقة صريحة'),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Text(
                    'حد أمني: الموافقة تسجل قرارك فقط. لا يوجد تنفيذ أو نشر أو إرسال أو تحويل أموال من هذه الشاشة.',
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
    );
  }
}
