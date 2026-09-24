import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../services/agents/agent_registry_repository.dart';

class MyAgentsScreen extends StatefulWidget {
  const MyAgentsScreen({super.key});
  @override State<MyAgentsScreen> createState() => _MyAgentsScreenState();
}
class _MyAgentsScreenState extends State<MyAgentsScreen> {
  final id = TextEditingController(); final name = TextEditingController();
  final description = TextEditingController(); final version = TextEditingController(text: '1.0.0');
  bool _busy = false;
  @override void dispose() { id.dispose(); name.dispose(); description.dispose(); version.dispose(); super.dispose(); }
  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || id.text.trim().isEmpty || name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await AurenAgentRegistryRepository().save(uid: uid, agentId: id.text.trim(), name: name.text, version: version.text, status: 'active');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الـAgent.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _publish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || id.text.trim().isEmpty || name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('publishAurenAgent').call({
        'agentId': id.text.trim(), 'name': name.text.trim(), 'description': description.text.trim(),
        'version': version.text.trim(), 'capabilities': const <String>[],
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر الـAgent في Marketplace.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول.')));
    return Scaffold(appBar: AppBar(title: const Text('My Agents')), body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: id, decoration: const InputDecoration(labelText: 'Agent ID')),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
      TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      TextField(controller: version, decoration: const InputDecoration(labelText: 'Version')),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('حفظ'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : _publish, icon: const Icon(Icons.publish_outlined), label: const Text('نشر'))),
      ]),
      const SizedBox(height: 20),
      StreamBuilder<List<Map<String, dynamic>>>(stream: AurenAgentRegistryRepository().watchMine(uid), builder: (context, s) {
        final xs = s.data ?? const <Map<String, dynamic>>[];
        return Column(children: xs.map<Widget>((x) => ListTile(leading: const Icon(Icons.smart_toy_outlined), title: Text(x['name']?.toString() ?? ''), subtitle: Text((x['id']?.toString() ?? '') + ' • ' + (x['version']?.toString() ?? '')))).toList());
      }),
    ]));
  }
}