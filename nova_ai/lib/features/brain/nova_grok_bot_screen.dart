import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NovaGrokBotScreen extends StatefulWidget {
  const NovaGrokBotScreen({super.key});
  @override
  State<NovaGrokBotScreen> createState() => _NovaGrokBotScreenState();
}

class _NovaGrokBotScreenState extends State<NovaGrokBotScreen> {
  final _prompt = TextEditingController();
  final _contextNotes = TextEditingController();
  String _mode = 'chat';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _prompt.dispose();
    _contextNotes.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> _send() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      await _ensureSignedIn();
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('novaGrokBot');
      final response = await callable.call(<String, dynamic>{
        'prompt': prompt,
        'context': _contextNotes.text.trim(),
        'mode': _mode,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      setState(() => _result = data);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'تعذر الاتصال بـ Grok Bot.');
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر استخدام Grok Bot. تحقق من تسجيل الدخول والاتصال.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSimplePlanCard() {
    final radar = _result?['opportunityRadar'];
    if (radar is! Map) return const SizedBox.shrink();
    final rawPlan = radar['simplePlan'];
    if (rawPlan is! Map) return const SizedBox.shrink();
    final plan = Map<String, dynamic>.from(rawPlan);
    final rawExperiment = plan['incomeExperiment'];
    final experiment = rawExperiment is Map
        ? Map<String, dynamic>.from(rawExperiment)
        : null;
    final checks = experiment?['validationChecks'] is List
        ? (experiment!['validationChecks'] as List).map((item) => item.toString()).toList()
        : <String>[];
    final candidates = plan['githubCandidates'] is List
        ? (plan['githubCandidates'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('خطة بسيطة لليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (experiment != null) ...[
              Text('الفرصة: ${experiment['title'] ?? ''}', textDirection: TextDirection.rtl,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (experiment['firstAction'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('ابدأ: ${experiment['firstAction']}', textDirection: TextDirection.rtl),
                ),
              if (experiment['deliverable'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('المطلوب اليوم: ${experiment['deliverable']}', textDirection: TextDirection.rtl),
                ),
              if (checks.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('قبل الاعتماد أو الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...checks.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $item', textDirection: TextDirection.rtl),
                )),
              ],
            ] else
              const Text('ما في فرصة مناسبة للوقت المحدد اليوم. لا نختلق خطة؛ زِد الوقت المتاح أو جرّب لاحقاً.', textDirection: TextDirection.rtl),
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('مشروعات GitHub المرشحة (غير مثبتة وغير مفحوصة بعد)', style: TextStyle(fontWeight: FontWeight.bold)),
              ...candidates.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${item['name'] ?? item['id'] ?? 'مشروع'}'),
                    if (item['url'] != null)
                      SelectableText(item['url'].toString(), textDirection: TextDirection.ltr),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 8),
            const Text('لا يوجد دخل مضمون. لن يتم التواصل مع العملاء أو تثبيت الأدوات أو نشر المحتوى تلقائياً.',
                textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVA Grok Bot')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مساعد واحد، أدوات متعددة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('يجمع المحادثة والتخطيط والبحث ومساعدة البرمجة في واجهة واحدة. اتصال Grok يتطلب إعداد مفتاح الخادم وقد يترتب عليه تكلفة.'),
          SizedBox(height: 8),
          Text('لا ينفذ هذا البوت أوامر خارجية؛ يقترح الخطوات فقط. أي تنفيذ حقيقي يحتاج موافقتك وربطاً آمناً بمركز المهام.', style: TextStyle(color: Colors.white70)),
        ]),
      )),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _mode,
        decoration: const InputDecoration(labelText: 'نوع المهمة', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'chat', child: Text('محادثة عامة')),
          DropdownMenuItem(value: 'research', child: Text('بحث وتحليل')),
          DropdownMenuItem(value: 'coding', child: Text('برمجة ومراجعة الكود')),
          DropdownMenuItem(value: 'planning', child: Text('تخطيط ومقارنة الخيارات')),
          DropdownMenuItem(value: 'content', child: Text('محتوى وصور وفيديو')),
        ],
        onChanged: _loading ? null : (value) { if (value != null) setState(() => _mode = value); },
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _prompt, minLines: 3, maxLines: 7, maxLength: 6000, textDirection: TextDirection.rtl,
        decoration: const InputDecoration(labelText: 'شنو داير من Grok Bot؟', hintText: 'اكتب المهمة أو السؤال...', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _contextNotes, minLines: 1, maxLines: 4, maxLength: 10000, textDirection: TextDirection.rtl,
        decoration: const InputDecoration(labelText: 'سياق إضافي (اختياري)', hintText: 'أضف معلومات غير سرية تساعد على فهم الطلب.', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _loading ? null : _send,
        icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Grok Bot يفكر...' : 'إرسال إلى Grok Bot'),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, textDirection: TextDirection.rtl))),
      ],
      if (_result != null) ...[
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_result!['bot'] ?? 'NOVA Grok Bot'} · ${_result!['model'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_result!['answer'] ?? ''}', textDirection: TextDirection.rtl),
            if (_result!['nextSteps'] is List && (_result!['nextSteps'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('الخطوات المقترحة', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_result!['nextSteps'] as List).map((step) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $step', textDirection: TextDirection.rtl),
              )),
            ],
            if (_result!['proposedAction'] != null) ...[
              const SizedBox(height: 12),
              Text('مقترح يحتاج موافقتك: ${_result!['proposedAction']}', textDirection: TextDirection.rtl,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            Text('${_result!['message'] ?? 'لم يتم تنفيذ أي إجراء خارجي.'}', textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white70)),
          ]),
        )),
        _buildSimplePlanCard(),
      ],
    ]),
  );
}
