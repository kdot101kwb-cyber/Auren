import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/agent_listing.dart';
import '../../../services/agents/agent_protocol_repository.dart';
import '../../../services/agents/agent_installation_repository.dart';
import '../../../core/models/agent_message.dart';

class AgentDetailScreen extends StatefulWidget {
  final AurenAgentListing agent;
  const AgentDetailScreen({super.key, required this.agent});
  @override State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  bool _installing = false;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    _loadInstallation();
  }

  Future<void> _loadInstallation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final installed = await AurenAgentInstallationRepository().isInstalled(uid, widget.agent.agentId);
    if (mounted) setState(() => _installed = installed);
  }

  Future<void> _toggleInstallation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _installing) return;
    setState(() => _installing = true);
    try {
      final repo = AurenAgentInstallationRepository();
      if (_installed) {
        await repo.uninstall(uid, widget.agent.agentId);
      } else {
        await repo.install(
          uid: uid,
          agentId: widget.agent.agentId,
          name: widget.agent.name,
          version: widget.agent.version,
        );
      }
      if (mounted) setState(() => _installed = !_installed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الـAgent: ' + e.toString())));
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override void dispose() { _message.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await AurenAgentProtocolRepository().enqueue(AurenAgentMessage(
        messageId: 'msg_' + id,
        senderAgentId: 'primary',
        recipientAgentId: widget.agent.agentId,
        type: 'request',
        payload: {'text': text},
        createdAt: DateTime.now(),
      ));
      _message.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للـAgent.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الإرسال: ' + e.toString())));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override Widget build(BuildContext context) {
    final a = widget.agent;
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 30, child: Icon(Icons.smart_toy_outlined, size: 30)),
          const SizedBox(height: 14),
          Text(a.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6), Text(a.description), const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: a.capabilities.map((x) => Chip(label: Text(x))).toList()),
        ]))),
        Card(child: ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Trust & Reputation'), subtitle: Text('★ ' + a.reputationScore.toStringAsFixed(1) + ' • ' + a.reviewCount.toString() + ' مراجعة'))),
        Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Pricing'), subtitle: Text(a.pricingModel + ' • ' + (a.amountMinor == 0 ? 'مجاني' : (a.amountMinor / 100).toStringAsFixed(2) + ' ' + a.currency)))),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _installing ? null : _toggleInstallation,
          icon: _installing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_installed ? Icons.check_circle_outline : Icons.add_circle_outline),
          label: Text(_installed ? 'Agent مثبت — إزالة التثبيت' : 'تثبيت Agent'),
        ),
        const SizedBox(height: 18),
        const Text('تواصل مع الـAgent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _message, minLines: 2, maxLines: 5, decoration: const InputDecoration(hintText: 'اكتب المهمة أو الطلب...', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: const Text('إرسال عبر A2A')),
      ]),
    );
  }
}
