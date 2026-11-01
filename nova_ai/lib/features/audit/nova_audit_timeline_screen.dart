import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/audit/nova_local_audit_ledger.dart';

/// Read-only viewer for the bounded, redacted device-local audit ledger.
class NovaAuditTimelineScreen extends StatefulWidget {
  const NovaAuditTimelineScreen({super.key, this.ledger});

  final NovaLocalAuditLedger? ledger;

  @override
  State<NovaAuditTimelineScreen> createState() => _NovaAuditTimelineScreenState();
}

class _NovaAuditTimelineScreenState extends State<NovaAuditTimelineScreen> {
  late final NovaLocalAuditLedger _ledger = widget.ledger ?? NovaLocalAuditLedger();
  List<NovaAuditEvent> _events = const [];
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
      final events = await _ledger.read();
      if (!mounted) return;
      setState(() { _events = events; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذر قراءة سجل التدقيق المحلي.'; });
    }
  }

  Future<void> _showDetails(NovaAuditEvent event) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(event.type),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.message, textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              Text('الوقت: ${event.createdAt.toLocal()}'),
              if (event.actionId != null) Text('معرّف الإجراء: ${event.actionId}'),
              const SizedBox(height: 8),
              const Text('بيانات إضافية بعد تنقية الحقول الحساسة:'),
              SelectableText(const JsonEncoder.withIndent('  ').convert(event.metadata)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل تدقيق NOVA'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'تحديث')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('الأحداث المحفوظة على الجهاز'),
                    trailing: Text('${_events.length}', style: Theme.of(context).textTheme.headlineSmall),
                  )),
                  if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  if (_events.isEmpty) const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('لا توجد أحداث مسجلة حتى الآن.')),
                  ),
                  ..._events.map((event) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(event.message, textDirection: TextDirection.rtl),
                      subtitle: Text('${event.type} • ${event.createdAt.toLocal()}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetails(event),
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Text(
                    'السجل محلي ومحدود وليس دليلاً غير قابل للتلاعب. تُنقّى مفاتيح حساسة معروفة، لكن لا تحفظ أسراراً في بيانات الأحداث.',
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
    );
  }
}
