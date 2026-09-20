import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agent_marketplace_screen.dart';
import 'agent_wallet_screen.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/agents/agent_plugin_repository.dart';
import '../../../services/agents/agent_installation_repository.dart';

class AurenAgentHubScreen extends StatefulWidget {
  const AurenAgentHubScreen({super.key});
  @override State<AurenAgentHubScreen> createState() => _AurenAgentHubScreenState();
}

class _AurenAgentHubScreenState extends State<AurenAgentHubScreen> {
  bool busy = false;
  final _actionRepo = ActionRepository();
  static const _allowedActions = ['demo.echo', 'demo.create_note', 'memory.save'];

  Future<void> validatePlugin() async {
    setState(() => busy = true);
    try {
      final result = await AurenAgentPluginRepository().validate({
        'pluginId': 'auren.demo.plugin', 'name': 'AUREN Demo Plugin', 'version': '1.0.0',
        'capabilities': ['actions.discover'], 'entrypoint': 'demo://plugin',
      });
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Plugin Validated'),
        content: Text('Sandbox: ' + (result.policy['sandbox'] ?? '').toString() + '\nNetwork: ' +
          (result.policy['network'] ?? '').toString() + '\nSecrets: ' + (result.policy['secrets'] ?? '').toString() +
          '\nTimeout: ' + (result.policy['executionTimeoutMs'] ?? '').toString() + 'ms'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _savePermissions(Map<String, dynamic>? current, {
    bool? enabled,
    List<String>? actions,
    int? dailyLimit,
    bool clearLimit = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final currentActions = List<String>.from(current?['allowedActions'] ?? _allowedActions);
    final currentLimit = current?['dailySpendingLimitMinor'] as int?;
    await _actionRepo.setPermissionLedger(
      uid,
      enabled: enabled ?? current?['enabled'] == true,
      allowedActions: actions ?? currentActions,
      dailySpendingLimitMinor: clearLimit ? null : (dailyLimit ?? currentLimit),
      currency: current?['currency']?.toString() ?? 'USD',
    );
  }

  Future<void> _editPermissions(String uid, Map<String, dynamic>? current) async {
    final selected = <String>{
      ...List<String>.from(current?['allowedActions'] ?? _allowedActions),
    };
    final limitController = TextEditingController(
      text: ((current?['dailySpendingLimitMinor'] as int?) ?? 0).toString(),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agent Permissions'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final action in _allowedActions)
                CheckboxListTile(
                  value: selected.contains(action),
                  title: Text(action),
                  onChanged: (value) => setDialogState(() {
                    if (value == true) {
                      selected.add(action);
                    } else {
                      selected.remove(action);
                    }
                  }),
                ),
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily spending limit (minor units)',
                  helperText: '0 = no spending allowed',
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    final limit = int.tryParse(limitController.text.trim());
    limitController.dispose();
    if (result != true || limit == null || limit < 0) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل حد إنفاق صحيح.')));
      }
      return;
    }
    await _savePermissions(current, actions: selected.toList(), dailyLimit: limit);
  }

  void _showAudit(String uid) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) =>
      StreamBuilder<List<Map<String, dynamic>>>(stream: _actionRepo.watchAudit(uid, limit: 30), builder: (context, snapshot) {
        final events = snapshot.data ?? const <Map<String, dynamic>>[];
        return SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .75, child: ListView(
          padding: const EdgeInsets.all(16), children: [
            Text('AUREN Audit Trail', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (events.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد عمليات مسجلة حتى الآن.')),
            ...events.map((e) => Card(child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(e['actionType']?.toString() ?? 'agent.action'),
              subtitle: Text((e['status']?.toString() ?? 'unknown') + ' • risk: ' +
                (e['riskLevel']?.toString() ?? 'unknown') + '\n' + (e['result']?.toString() ?? 'تم تسجيل الحدث.')),
            ))),
          ],
        )));
      }),
    );
  }

  Widget _trustCard(String uid) => StreamBuilder<Map<String, dynamic>?>(
    stream: _actionRepo.watchTrust(uid),
    builder: (context, snapshot) {
      final trust = snapshot.data;
      final score = (trust?['score'] as num?)?.toDouble() ?? 50;
      final completed = (trust?['completedExecutions'] as num?)?.toInt() ?? 0;
      final failed = (trust?['failedExecutions'] as num?)?.toInt() ?? 0;
      final status = trust?['status']?.toString() ?? 'active';
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.verified_user_outlined), SizedBox(width: 12),
          Text('Trust & Reputation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),
        Row(children: [SizedBox(width: 58, height: 58, child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: score / 100), Text(score.round().toString()),
        ])), const SizedBox(width: 16), Expanded(child: Text('الحالة: ' + status + '\nنجاح: ' + completed.toString() +
          ' • فشل: ' + failed.toString() + '\nالثقة تُحدّث من سجل التنفيذ.'))]),
      ])));
    },
  );

  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar: AppBar(title: const Text('AUREN Agents')), body: ListView(padding: const EdgeInsets.all(16), children: [
      if (uid != null) _trustCard(uid),
      if (uid != null) StreamBuilder<Map<String, dynamic>?>(stream: _actionRepo.watchPermissionLedger(uid), builder: (context, snapshot) {
        final permission = snapshot.data;
        final enabled = permission?['enabled'] == true;
        return Card(child: ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('Agent Permission Ledger'),
          subtitle: Text(enabled ? 'الصلاحيات مفعّلة' : 'الصلاحيات متوقفة'),
          trailing: Wrap(children: [
            IconButton(
              tooltip: 'إدارة الصلاحيات',
              icon: const Icon(Icons.tune),
              onPressed: () => _editPermissions(uid, permission),
            ),
            Switch(value: enabled, onChanged: (v) => _savePermissions(permission, enabled: v)),
          ]),
        ));
      }),
      if (uid != null) Card(child: ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Audit Trail'),
        subtitle: const Text('سجل التنفيذ والموافقات والنتائج'), onTap: () => _showAudit(uid))),
      Card(child: ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Agent Marketplace'),
        subtitle: const Text('اكتشف الوكلاء والقدرات المتاحة'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentMarketplaceScreen())))),
      if (uid != null)
        StreamBuilder(
          stream: AurenAgentInstallationRepository().watch(uid),
          builder: (context, snapshot) {
            final agents = snapshot.data ?? const [];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.apps_outlined),
                title: const Text('Installed Agents'),
                subtitle: Text(agents.isEmpty
                    ? 'لا توجد Agents مثبتة'
                    : 'Agents نشطة: ${agents.length}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SafeArea(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * .65,
                      child: agents.isEmpty
                          ? const Center(child: Text('ثبّت Agent من الـMarketplace أولاً.'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: agents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final agent = agents[index];
                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.smart_toy_outlined)),
                                  title: Text(agent.name),
                                  subtitle: Text('v${agent.version} • ${agent.status}'),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      Card(child: ListTile(leading: const Icon(Icons.extension_outlined), title: const Text('Developer / Plugins'),
        subtitle: const Text('تحقق من Plugin Manifest قبل النشر'), trailing: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.verified_outlined),
        onTap: busy ? null : validatePlugin)),
      const Card(child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('Agent-to-Agent'), subtitle: Text('AUREN-A2A • هوية وصلاحيات وAudit'))),
      Card(child: ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Agent Wallet'), subtitle: const Text('الرصيد والعمليات وحدود الإنفاق'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentWalletScreen())))),
    ]));
  }
}
