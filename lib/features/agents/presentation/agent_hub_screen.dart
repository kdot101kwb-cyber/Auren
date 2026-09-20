import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agent_marketplace_screen.dart';
import '../../../services/actions/action_repository.dart';
import '../../../services/agents/agent_plugin_repository.dart';

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

  Future<void> _setAgentEnabled(bool enabled, Map<String, dynamic>? current) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _actionRepo.setPermissionLedger(uid, enabled: enabled,
      allowedActions: List<String>.from(current?['allowedActions'] ?? _allowedActions),
      dailySpendingLimitMinor: current?['dailySpendingLimitMinor'] as int?,
      currency: current?['currency']?.toString() ?? 'USD');
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
        final permission = snapshot.data; final enabled = permission?['enabled'] == true;
        return Card(child: ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Agent Permission Ledger'),
          subtitle: Text(enabled ? 'الصلاحيات مفعّلة' : 'الصلاحيات متوقفة'), trailing: Switch(value: enabled, onChanged: (v) => _setAgentEnabled(v, permission))));
      }),
      if (uid != null) Card(child: ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Audit Trail'),
        subtitle: const Text('سجل التنفيذ والموافقات والنتائج'), onTap: () => _showAudit(uid))),
      Card(child: ListTile(leading: const Icon(Icons.storefront_outlined), title: const Text('Agent Marketplace'),
        subtitle: const Text('اكتشف الوكلاء والقدرات المتاحة'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentMarketplaceScreen())))),
      Card(child: ListTile(leading: const Icon(Icons.extension_outlined), title: const Text('Developer / Plugins'),
        subtitle: const Text('تحقق من Plugin Manifest قبل النشر'), trailing: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.verified_outlined),
        onTap: busy ? null : validatePlugin)),
      const Card(child: ListTile(leading: Icon(Icons.hub_outlined), title: Text('Agent-to-Agent'), subtitle: Text('AUREN-A2A • هوية وصلاحيات وAudit'))),
      const Card(child: ListTile(leading: Icon(Icons.account_balance_wallet_outlined), title: Text('Agent Wallet'), subtitle: Text('حدود إنفاق وحجوزات معاملات'))),
    ]));
  }
}