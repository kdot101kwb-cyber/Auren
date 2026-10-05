import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/personal_ai/personal_brief_service.dart';

class AurenPersonalBriefScreen extends StatefulWidget {
  const AurenPersonalBriefScreen({super.key});
  @override State<AurenPersonalBriefScreen> createState() => _AurenPersonalBriefScreenState();
}

class _AurenPersonalBriefScreenState extends State<AurenPersonalBriefScreen> {
  final _service = PersonalBriefService();
  AurenPersonalBrief? _brief;
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) { setState(() { _loading = false; _error = 'Please sign in first.'; }); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final brief = await _service.build(uid);
      if (mounted) setState(() { _brief = brief; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر إنشاء الملخص: $e'; });
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personal Brief'), actions: [IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh))]),
    body: _loading && _brief == null
      ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
      : RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.auto_awesome), SizedBox(width: 8), Text('AUREN Personal Brief', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12), Text(_brief!.summary),
          ]))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _stat('Active Goals', _brief!.activeGoals.toString())), const SizedBox(width: 8), Expanded(child: _stat('Progress', '${_brief!.averageProgress}%')), const SizedBox(width: 8), Expanded(child: _stat('Memory', _brief!.enabledMemories.toString()))]),
          const SizedBox(height: 12),
          Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.fromLTRB(16,16,16,8), child: Text('Current Priorities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            if (_brief!.priorities.isEmpty) const ListTile(title: Text('لا توجد أولوية محددة بعد.'))
            else ..._brief!.priorities.asMap().entries.map((e) => ListTile(leading: CircleAvatar(radius: 14, child: Text('${e.key + 1}')), title: Text(e.value))),
          ])),
        ])),
  );

  Widget _stat(String label, String value) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center)])));
}