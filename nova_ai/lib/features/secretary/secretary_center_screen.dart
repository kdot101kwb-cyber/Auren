import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SecretaryWorkspace { nova, auren }

enum SecretaryRisk { low, reviewRequired }

class SecretaryDraft {
  const SecretaryDraft({
    required this.id,
    required this.workspace,
    required this.kind,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.risk,
    required this.createdAt,
  });

  final String id;
  final SecretaryWorkspace workspace;
  final String kind;
  final String recipient;
  final String subject;
  final String body;
  final SecretaryRisk risk;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'workspace': workspace.name,
        'kind': kind,
        'recipient': recipient,
        'subject': subject,
        'body': body,
        'risk': risk.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SecretaryDraft.fromJson(Map<String, dynamic> json) => SecretaryDraft(
        id: json['id'] as String,
        workspace: SecretaryWorkspace.values.firstWhere(
          (v) => v.name == json['workspace'],
          orElse: () => SecretaryWorkspace.nova,
        ),
        kind: json['kind'] as String? ?? 'email',
        recipient: json['recipient'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        body: json['body'] as String? ?? '',
        risk: SecretaryRisk.values.firstWhere(
          (v) => v.name == json['risk'],
          orElse: () => SecretaryRisk.reviewRequired,
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

SecretaryRisk classifySecretaryRisk(String text) {
  final normalized = text.toLowerCase();
  const sensitiveTerms = [
    'payment', 'refund', 'chargeback', 'password', 'security', 'legal',
    'lawyer', 'lawsuit', 'contract', 'bank', 'transfer', 'fraud',
    'دفع', 'استرداد', 'تحويل', 'بنك', 'كلمة المرور', 'اختراق', 'أمان',
    'قانوني', 'محامي', 'عقد', 'احتيال', 'شكوى',
  ];
  return sensitiveTerms.any(normalized.contains)
      ? SecretaryRisk.reviewRequired
      : SecretaryRisk.low;
}

class SecretaryCenterScreen extends StatefulWidget {
  const SecretaryCenterScreen({super.key});

  @override
  State<SecretaryCenterScreen> createState() => _SecretaryCenterScreenState();
}

class _SecretaryCenterScreenState extends State<SecretaryCenterScreen> {
  static const _storageKey = 'nova.secretary.drafts.v1';
  SecretaryWorkspace _workspace = SecretaryWorkspace.nova;
  final _recipient = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _source = TextEditingController();
  List<SecretaryDraft> _drafts = [];
  bool _loading = true;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  @override
  void dispose() {
    _recipient.dispose();
    _subject.dispose();
    _body.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      final loaded = <SecretaryDraft>[];
      for (final item in raw) {
        try {
          loaded.add(SecretaryDraft.fromJson(jsonDecode(item) as Map<String, dynamic>));
        } catch (_) {
          // Skip a malformed local draft instead of blocking the secretary screen.
        }
      }
      if (mounted) setState(() { _drafts = loaded; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _notice = 'تعذر فتح التخزين المحلي؛ لم يتم ربط أي بريد.'; });
    }
  }

  Future<void> _saveDraft() async {
    final recipient = _recipient.text.trim();
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      setState(() => _notice = 'اكتب عنواناً ومحتوى قبل حفظ المسودة.');
      return;
    }
    final risk = classifySecretaryRisk('$subject\n$body');
    final draft = SecretaryDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      workspace: _workspace,
      kind: _source.text.trim().isEmpty ? 'email' : _source.text.trim(),
      recipient: recipient,
      subject: subject,
      body: body,
      risk: risk,
      createdAt: DateTime.now(),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = [draft, ..._drafts];
      await prefs.setStringList(_storageKey, next.map((d) => jsonEncode(d.toJson())).toList());
      if (!mounted) return;
      setState(() {
        _drafts = next;
        _recipient.clear();
        _subject.clear();
        _body.clear();
        _source.clear();
        _notice = risk == SecretaryRisk.reviewRequired
            ? 'حُفظت المسودة، وصُنّفت للمراجعة البشرية قبل أي إرسال.'
            : 'حُفظت المسودة محلياً فقط؛ لم تُرسل لأي شخص.';
      });
    } catch (_) {
      if (mounted) setState(() => _notice = 'تعذر حفظ المسودة على الجهاز.');
    }
  }

  Future<void> _deleteDraft(SecretaryDraft draft) async {
    final next = _drafts.where((d) => d.id != draft.id).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, next.map((d) => jsonEncode(d.toJson())).toList());
      if (mounted) setState(() { _drafts = next; _notice = 'حُذفت المسودة المحلية.'; });
    } catch (_) {
      if (mounted) setState(() => _notice = 'تعذر حذف المسودة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceName = _workspace == SecretaryWorkspace.nova ? 'NOVA — سكرتيرك الشخصي' : 'AUREN — سكرتير الشركة';
    final visibleDrafts = _drafts.where((d) => d.workspace == _workspace).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('مركز السكرتارية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.support_agent, size: 30), SizedBox(width: 10), Expanded(child: Text('مركز السكرتارية التنفيذية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 8),
              const Text('تجهيز رسائل البريد وردود العملاء، حفظ المسودات، وفرز الحالات التي تحتاج تدخلك حتى أثناء غيابك.'),
              const SizedBox(height: 12),
              SegmentedButton<SecretaryWorkspace>(
                segments: const [
                  ButtonSegment(value: SecretaryWorkspace.nova, icon: Icon(Icons.person_outline), label: Text('شخصي — NOVA')),
                  ButtonSegment(value: SecretaryWorkspace.auren, icon: Icon(Icons.business_outlined), label: Text('الشركة — AUREN')),
                ],
                selected: {_workspace},
                onSelectionChanged: (v) => setState(() => _workspace = v.first),
              ),
              const SizedBox(height: 8),
              Text(workspaceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 12),
          const Card(child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('حالة التكامل', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Row(children: [Icon(Icons.link_off, color: Colors.orangeAccent), SizedBox(width: 8), Expanded(child: Text('البريد والقنوات غير متصلة بعد. هذه النسخة تحفظ مسودات محلية فقط.'))]),
              SizedBox(height: 6),
              Text('لا إرسال تلقائياً، ولا وصول إلى صندوق الوارد، ولا عمل بالخلفية حتى ربط OAuth وخادم موثوق واختبار الاتصال.'),
            ]),
          )),
          const SizedBox(height: 12),
          Text('إنشاء مسودة — ${_workspace == SecretaryWorkspace.nova ? 'شخصية' : 'للعملاء'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(key: const ValueKey('secretary-source'), controller: _source, decoration: const InputDecoration(labelText: 'نوع الرسالة / القناة (اختياري)', hintText: 'بريد، رد عميل، متابعة...', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(key: const ValueKey('secretary-recipient'), controller: _recipient, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'المستلم أو مرجع المحادثة (اختياري)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(key: const ValueKey('secretary-subject'), controller: _subject, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(key: const ValueKey('secretary-body'), controller: _body, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'نص البريد أو رد العميل', alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _saveDraft, icon: const Icon(Icons.save_outlined), label: const Text('حفظ مسودة على هذا الجهاز')),
          if (_notice != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_notice!, textDirection: TextDirection.rtl)),
          const SizedBox(height: 18),
          Text('المسودات المحفوظة (${visibleDrafts.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          if (!_loading && visibleDrafts.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('لا توجد مسودات لهذا القسم بعد.')),
          for (final draft in visibleDrafts)
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(draft.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(tooltip: 'حذف المسودة', onPressed: () => _deleteDraft(draft), icon: const Icon(Icons.delete_outline)),
              ]),
              Text(draft.recipient.isEmpty ? 'لم يُحدد مستلم' : draft.recipient),
              const SizedBox(height: 6),
              Text(draft.body),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                Chip(label: Text(draft.kind)),
                Chip(avatar: Icon(draft.risk == SecretaryRisk.low ? Icons.check_circle_outline : Icons.warning_amber, size: 16), label: Text(draft.risk == SecretaryRisk.low ? 'مبدئياً منخفضة المخاطر' : 'تحتاج مراجعة بشرية')),
                const Chip(avatar: Icon(Icons.save_outlined, size: 16), label: Text('محلية فقط')),
              ]),
              if (draft.risk == SecretaryRisk.reviewRequired)
                const Text('لا تُرسل هذه الرسالة آلياً؛ تحقق من التفاصيل والهوية والسياسة أولاً.', style: TextStyle(color: Colors.orangeAccent)),
            ]))),
          const SizedBox(height: 12),
          const Text('قواعد السكرتارية: الدفع والاسترداد والأمان والقانون والشكاوى تصعّد للمراجعة؛ لا ترسل رسائل فعلية دون ربط مصرح به وسياسة إرسال واضحة.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
