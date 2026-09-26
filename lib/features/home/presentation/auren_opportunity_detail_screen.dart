import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/opportunities/opportunity_repository.dart';
import '../../../services/social/match_everything_service.dart';
import '../../../core/models/opportunity.dart';

class AurenOpportunityDetailScreen extends StatefulWidget {
  final AurenMatchItem item;
  final String intent;
  const AurenOpportunityDetailScreen({super.key, required this.item, required this.intent});
  @override State<AurenOpportunityDetailScreen> createState() => _AurenOpportunityDetailScreenState();
}

class _AurenOpportunityDetailScreenState extends State<AurenOpportunityDetailScreen> {
  final _auth = FirebaseAurenAuthService();
  final _repo = OpportunityRepository();
  bool _busy = false;
  bool _interested = false;
  bool _applied = false;

  Future<void> _toggleInterest() async {
    final uid = _auth.currentUserId;
    if (uid == null) { _toast('سجّل الدخول أولاً.'); return; }
    setState(() => _busy = true);
    try {
      await _repo.toggleInterest(
        uid: uid,
        opportunityId: widget.item.id,
        interested: _interested,
        snapshot: widget.item.data,
      );
      if (mounted) setState(() => _interested = !_interested);
      _toast(_interested ? 'تم حفظ الفرصة في اهتماماتك.' : 'تم إلغاء متابعة الفرصة.');
    } catch (e) {
      _toast('تعذر تحديث المتابعة: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final uid = _auth.currentUserId;
    if (uid == null) { _toast('سجّل الدخول أولاً.'); return; }
    if (_applied || await _repo.hasApplied(uid, widget.item.id)) {
      if (mounted) setState(() => _applied = true);
      _toast('سبق أن تقدمت لهذه الفرصة.');
      return;
    }
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('التقديم على الفرصة'),
        content: TextField(controller: note, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'رسالة قصيرة (اختياري)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تأكيد التقديم')),
        ],
      ),
    );
    final clean = note.text.trim();
    note.dispose();
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _repo.apply(uid: uid, opportunity: AurenOpportunity.fromMap(widget.item.id, widget.item.data), note: clean);
      if (mounted) setState(() => _applied = true);
      _toast('تم إرسال التقديم بنجاح.');
    } catch (e) {
      _toast('تعذر إرسال التقديم: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.item.data;
    final location = [d['city'], d['country']].where((x) => x != null && x.toString().trim().isNotEmpty).join(' • ');
    final type = (d['type'] ?? d['category'])?.toString() ?? 'Opportunity';
    final description = (d['description'] ?? d['text'])?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.radar, size: 40),
          const SizedBox(height: 12),
          Text(widget.item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (widget.item.subtitle.isNotEmpty) ...[const SizedBox(height: 8), Text(widget.item.subtitle)],
          const SizedBox(height: 14),
          Chip(label: Text(type)),
          if (location.isNotEmpty) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.location_on_outlined), title: const Text('الموقع'), subtitle: Text(location)),
        ]))),
        if (widget.intent.trim().isNotEmpty) Card(child: ListTile(leading: const Icon(Icons.search), title: const Text('طلبك'), subtitle: Text(widget.intent))),
        if (description.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(description))),
        if (widget.item.reasons.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سبب المطابقة', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...widget.item.reasons.map((x) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $x'))),
        ]))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : _toggleInterest, icon: Icon(_interested ? Icons.bookmark : Icons.bookmark_border), label: Text(_interested ? 'محفوظة' : 'حفظ الفرصة'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.icon(onPressed: _busy || _applied ? null : _apply, icon: const Icon(Icons.send), label: Text(_applied ? 'تم التقديم' : 'التقديم'))),
        ]),
      ]),
    );
  }
}
