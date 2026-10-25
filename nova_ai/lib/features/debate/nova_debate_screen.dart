import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class NovaDebateScreen extends StatefulWidget {
  const NovaDebateScreen({super.key});
  @override
  State<NovaDebateScreen> createState() => _NovaDebateScreenState();
}

class _NovaDebateScreenState extends State<NovaDebateScreen> {
  final prompt = TextEditingController();
  final contextNotes = TextEditingController();
  bool loading = false;
  String? error;
  Map<String, dynamic>? result;
  String? debateId;

  @override
  void dispose() {
    prompt.dispose();
    contextNotes.dispose();
    super.dispose();
  }

  Future<void> review() async {
    if (prompt.text.trim().isEmpty || loading) return;
    FocusScope.of(context).unfocus();
    setState(() { loading = true; error = null; result = null; });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('novaStrategicDebate');
      final response = await callable.call(<String, dynamic>{'prompt': prompt.text.trim(), 'context': contextNotes.text.trim()});
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() {
        result = Map<String, dynamic>.from(data['debate'] as Map);
        debateId = data['debateId'] as String?;
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'تعذر تنفيذ مراجعة النقاش.');
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر قراءة النتيجة. تحقق من تسجيل الدخول والاتصال.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مجلس النقاش الاستراتيجي')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOVA لا يوافق تلقائياً', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('يراجع القرار من زوايا التطوير والجودة والأمان والتكلفة. يوازن النتيجة والوقت والتكلفة ويعرض الاعتراضات والبدائل وخطة قابلة للتحقق.'),
          SizedBox(height: 8),
          Text('شفافية: هذه أربع زوايا مراجعة من نموذج واحد، وليست أربعة نماذج مستقلة.', style: TextStyle(color: Colors.white70)),
        ],
      ))),
      const SizedBox(height: 12),
      TextField(controller: prompt, minLines: 3, maxLines: 6, maxLength: 5000, textDirection: TextDirection.rtl,
        decoration: const InputDecoration(labelText: 'الخطة أو القرار', hintText: 'اكتب ما تريد من NOVA مراجعته...', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: contextNotes, minLines: 2, maxLines: 5, maxLength: 12000, textDirection: TextDirection.rtl,
        decoration: const InputDecoration(labelText: 'السياق والأدلة (اختياري)', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: loading ? null : review,
        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.balance),
        label: Text(loading ? 'المجلس يراجع الخطة...' : 'ناقش الخطة واعترض عليها')),
      if (error != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(error!, textDirection: TextDirection.rtl))),
      ],
      if (result != null) ...[
        const SizedBox(height: 16),
        const Text('نتيجة المراجعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(const JsonEncoder.withIndent('  ').convert(_visibleResult), textDirection: TextDirection.ltr))),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('بوابة التنفيذ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('الخطة بانتظار موافقتك. لم يتم تنفيذ أي أمر أو تغيير. الموافقة لا تعني أن منفّذ المهام متصل أو أن تغييرات نُشرت.'),
          if (debateId != null) SelectableText('معرّف السجل: ' + debateId!),
        ]))),
      ],
    ]),
  );

  Map<String, dynamic> get _visibleResult => result ?? <String, dynamic>{};
}
