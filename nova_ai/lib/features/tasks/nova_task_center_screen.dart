import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';

class NovaTaskCenterScreen extends StatefulWidget {
  const NovaTaskCenterScreen({super.key});

  @override
  State<NovaTaskCenterScreen> createState() => _NovaTaskCenterScreenState();
}

class _NovaTaskCenterScreenState extends State<NovaTaskCenterScreen> {
  final _prompt = TextEditingController();
  String _type = 'research';
  bool _busy = false;
  String? _message;
  List<Map<String, dynamic>> _tasks = const [];
  List<Map<String, dynamic>> _repairProposals = const [];

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _loadTasks() async {
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      setState(() => _message = NovaFirebaseRuntime.initializationError ??
          'يلزم إعداد Firebase وتفعيل App Check قبل الاتصال بالخادم.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('listNovaTasks').call(<String, dynamic>{'limit': 30});
      final data = Map<String, dynamic>.from(response.data as Map);
      final raw = (data['tasks'] as List? ?? const []);
      setState(() {
        _tasks = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _message = 'تم تحديث المهام من الخادم.';
      });
      await _loadRepairProposals();
    } catch (error) {
      setState(() => _message = 'تعذر تحميل المهام: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _loadRepairProposals() async {
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) return;
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('listNovaRepairProposals').call();
      final data = Map<String, dynamic>.from(response.data as Map);
      final raw = data['proposals'] as List? ?? const [];
      if (mounted) setState(() {
        _repairProposals = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (_) {
      // The repair functions may not be deployed until the reviewed release step.
    }
  }

  Future<void> _generateRepairProposal(Map<String, dynamic> task) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء اقتراح إصلاح'),
        content: const Text(
          'سيُرسل دليل الفشل المختصر والملفات المصدرية المحددة إلى نموذج OpenRouter المجاني لتحليلها واقتراح تعديل. لن يُكتب أي شيء في GitHub الآن. هل توافق على التحليل؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('موافق، حلّل')),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateNovaRepairProposal').call(<String, dynamic>{
        'taskId': '${task['taskId']}',
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _message =
          'أنشأت NOVA اقتراحاً للمراجعة: ${data['proposalId']}. لم يُطبّق أي تعديل بعد.');
      await _loadRepairProposals();
    } catch (error) {
      if (mounted) setState(() => _message = 'تعذر إنشاء اقتراح الإصلاح: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approveRepairProposal(Map<String, dynamic> proposal) async {
    final files = proposal['files'] as List? ?? const [];
    final preview = StringBuffer()
      ..writeln('${proposal['summary'] ?? ''}')
      ..writeln('\nSource: ${proposal['sourceCommitSha'] ?? ''}');
    for (final raw in files) {
      if (raw is! Map) continue;
      preview
        ..writeln('\nFILE: ${raw['path']}')
        ..writeln('REASON: ${raw['reason']}')
        ..writeln('--- COMPLETE REPLACEMENT ---')
        ..writeln('${raw['content'] ?? ''}');
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مراجعة واعتماد الإصلاح'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: SelectableText(
              '${preview.toString()}\n\nبالموافقة ستنشئ NOVA commit واحداً في فرع nova/repairs/ منفصل. لن تفتح PR ولن تدمج أو تنشر.',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رفض / إغلاق')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('أوافق على كتابة فرع الإصلاح')),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('approveAndApplyNovaRepair').call(<String, dynamic>{
        'proposalId': '${proposal['proposalId']}',
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _message =
          'تم إنشاء فرع الإصلاح ${data['branch']} والالتزام ${data['commitSha']}. ننتظر فحوصات CI؛ لم يُفتح PR.');
      await _loadRepairProposals();
    } catch (error) {
      if (mounted) setState(() => _message = 'لم يُطبق الإصلاح: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkRepairProposal(Map<String, dynamic> proposal) async {
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('checkNovaRepairValidation').call(<String, dynamic>{
        'proposalId': '${proposal['proposalId']}',
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _message = switch (data['state']) {
        'verified' => 'نجح الإصلاح في جميع فحوصات CI المطلوبة على نفس commit.',
        'failed' => 'فشل واحد أو أكثر من فحوصات الإصلاح. لن يُعتبر الإصلاح ناجحاً.',
        _ => 'فحوصات الإصلاح لم تكتمل بعد؛ الحالة ما زالت قيد الانتظار.',
      });
      await _loadRepairProposals();
    } catch (error) {
      if (mounted) setState(() => _message = 'تعذر التحقق من الإصلاح: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitTask() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) {
      setState(() => _message = 'اكتب وصف المهمة أولاً.');
      return;
    }
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      setState(() => _message = NovaFirebaseRuntime.initializationError ??
          'يلزم إعداد Firebase وتفعيل App Check قبل إرسال المهام.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final idempotencyKey = 'nova_${DateTime.now().microsecondsSinceEpoch}';
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('submitNovaTask').call(<String, dynamic>{
        'type': _type,
        'prompt': prompt,
        'idempotencyKey': idempotencyKey,
        'metadata': <String, dynamic>{'source': 'nova_android', 'locale': 'ar'},
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      _prompt.clear();
      setState(() => _message =
          'سُجلت المهمة في قائمة الخلفية: ${data['taskId']} — الحالة: ${data['status']}. '
          'ستتم معالجتها عند توفر العامل وإعداداته؛ التسجيل وحده لا يثبت بدء التنفيذ.');
      await _loadTasks();
    } catch (error) {
      setState(() => _message = 'فشل إرسال المهمة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _taskAction(String name, String taskId) async {
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(name).call(<String, dynamic>{'taskId': taskId});
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() => _message = 'تم تحديث الحالة إلى: ${data['status']}.');
      await _loadTasks();
    } catch (error) {
      setState(() => _message = 'تعذر تنفيذ الإجراء: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusLabel(dynamic status) => switch (status) {
    'succeeded' => 'نجاح',
    'failed' => 'فشل',
    'running' => 'قيد التنفيذ',
    'queued' || 'awaiting_approval' || 'provider_processing' => 'بانتظار / متابعة',
    'verification_incomplete' => 'تعذر التحقق بالكامل',
    _ => 'حالة غير معروفة',
  };

  Color _statusColor(dynamic status) => switch (status) {
    'succeeded' => Colors.green,
    'failed' => Colors.red,
    'running' => Colors.orange,
    'queued' || 'awaiting_approval' || 'provider_processing' => Colors.amber,
    'verification_incomplete' => Colors.deepOrange,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('مركز تنفيذ NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('المهام تُحفظ في الخادم وتُعالج بالخلفية حتى لو أغلقت التطبيق، بعد نشر وظائف Firebase وضبط مفتاح مزود الذكاء الاصطناعي. العامل المجدول يفحص قائمة الانتظار كل دقيقة؛ مهام الفيديو المدفوعة تتطلب موافقة صريحة وإعداد أسرار Higgsfield ونشر وظائف Firebase.'),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(NovaFirebaseRuntime.initialized ? Icons.cloud_done : Icons.cloud_off,
                color: NovaFirebaseRuntime.initialized ? Colors.greenAccent : Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(NovaFirebaseRuntime.initialized
                ? (NovaFirebaseRuntime.appCheckActivated ? 'Firebase مهيأ وApp Check نشط' : 'Firebase مهيأ؛ App Check غير مؤكد')
                : 'Firebase غير مهيأ في هذا البناء')),
          ]),
          if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) ...[
            const SizedBox(height: 8),
            Text(NovaFirebaseRuntime.initializationError ??
                'ابنِ التطبيق بقيم FIREBASE_API_KEY وFIREBASE_APP_ID وFIREBASE_MESSAGING_SENDER_ID وFIREBASE_PROJECT_ID.'),
          ],
        ],
      ))),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _type,
        decoration: const InputDecoration(labelText: 'نوع المهمة', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'chat', child: Text('محادثة / إجابة')),
          DropdownMenuItem(value: 'plan', child: Text('خطة تنفيذ')),
          DropdownMenuItem(value: 'research', child: Text('بحث وتحليل')),
          DropdownMenuItem(value: 'opportunity_scan', child: Text('بحث عن فرص دخل')),
          DropdownMenuItem(value: 'content_draft', child: Text('مسودة محتوى')),
          DropdownMenuItem(value: 'github_ci_check', child: Text('فحص GitHub Actions — قراءة فقط')),
          DropdownMenuItem(value: 'circleci_check', child: Text('فحص CircleCI وسجلات الأخطاء — قراءة فقط')),
          DropdownMenuItem(value: 'video_generation', child: Text('توليد فيديو عبر Higgsfield — مدفوع ويتطلب موافقة')),
          DropdownMenuItem(value: 'social_publish', child: Text('نشر اجتماعي — يتطلب موافقة')),
        ],
        onChanged: _busy ? null : (value) { if (value != null) setState(() => _type = value); },
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _prompt,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(labelText: _type == 'github_ci_check' ? 'رابط تشغيل GitHub Actions' : _type == 'circleci_check' ? 'رابط وظيفة CircleCI' : 'شنو داير NOVA تنفّذ؟', hintText: _type == 'github_ci_check' ? 'https://github.com/kdot101kwb-cyber/Auren/actions/runs/41069266046' : _type == 'circleci_check' ? 'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039' : 'اكتب هدف المهمة بالتفصيل', border: const OutlineInputBorder()),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _busy ? null : _submitTask,
        icon: const Icon(Icons.send),
        label: Text(_busy ? 'جاري التنفيذ…' : 'إرسال المهمة للخادم'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : _loadTasks,
        icon: const Icon(Icons.refresh),
        label: const Text('تحديث قائمة المهام'),
      ),
      if (_message != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(_message!, textDirection: TextDirection.rtl),
      ),
      const SizedBox(height: 12),
      const Text('المهام المسجلة في الخادم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (_tasks.isEmpty) const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('لا توجد مهام محمّلة بعد. اضغط تحديث القائمة بعد إعداد الاتصال.'),
      ),

      const SizedBox(height: 18),
      const Text('اقتراحات الإصلاح الذاتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Text('كل اقتراح يُعرض كاملاً للمراجعة. التطبيق يتطلب موافقتك، ثم ينشئ فرعاً منفصلاً فقط.'),
      OutlinedButton.icon(
        onPressed: _busy ? null : _loadRepairProposals,
        icon: const Icon(Icons.refresh),
        label: const Text('تحديث اقتراحات الإصلاح'),
      ),
      for (final proposal in _repairProposals)
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اقتراح ${proposal['proposalId']} — ${proposal['state']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${proposal['summary'] ?? ''}', textDirection: TextDirection.rtl),
            if (proposal['sourceCommitSha'] is String)
              SelectableText('Source commit: ${proposal['sourceCommitSha']}', textDirection: TextDirection.ltr),
            for (final raw in (proposal['files'] as List? ?? const []))
              if (raw is Map) ...[
                const Divider(),
                Text('FILE: ${raw['path']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('السبب: ${raw['reason'] ?? ''}', textDirection: TextDirection.rtl),
              ],
            if (proposal['repairBranch'] is String)
              SelectableText('Repair branch: ${proposal['repairBranch']}', textDirection: TextDirection.ltr),
            if (proposal['repairCommitSha'] is String)
              SelectableText('Repair commit: ${proposal['repairCommitSha']}', textDirection: TextDirection.ltr),
            if (proposal['validation'] is Map)
              Text('CI validation: ${(proposal['validation'] as Map)['status'] ?? proposal['state']}'),
            if (proposal['error'] is String)
              Text('الخطأ: ${proposal['error']}', style: const TextStyle(color: Colors.orangeAccent)),
            Wrap(spacing: 8, children: [
              if (proposal['state'] == 'awaiting_approval')
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _approveRepairProposal(proposal),
                  child: const Text('مراجعة وموافقة على الإصلاح'),
                ),
              if (proposal['state'] == 'validation_pending')
                OutlinedButton(
                  onPressed: _busy ? null : () => _checkRepairProposal(proposal),
                  child: const Text('افحص نتيجة CI'),
                ),
            ]),
          ]),
        )),

      for (final task in _tasks)
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task['type'] ?? 'task'} — ${_statusLabel(task['status'])}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor(task['status']))),
            const SizedBox(height: 5),
            Text('${task['prompt'] ?? task['taskId'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
            if (task['result'] is Map && (task['result'] as Map)['text'] is String) ...[
              const SizedBox(height: 8),
              Text('النتيجة: ${(task['result'] as Map)['text']}', textDirection: TextDirection.rtl),
            ],
            if (task['result'] is Map && (task['result'] as Map)['evidenceUrl'] is String) ...[
              const SizedBox(height: 8),
              SelectableText('دليل CI: ${(task['result'] as Map)['evidenceUrl']}', textDirection: TextDirection.ltr),
              Text('الفرع: ${(task['result'] as Map)['branch'] ?? 'غير معروف'} — النجاح المثبت: ${(task['result'] as Map)['verifiedSuccess'] == true || (task['result'] as Map)['runStatus'] == 'success' ? 'نعم' : 'لا'}'),
            ],
            if (task['result'] is Map && (task['result'] as Map)['diagnostics'] is Map) ...[
              const SizedBox(height: 8),
              Text(
                'تشخيص CI: ${((task['result'] as Map)['diagnostics'] as Map)['status'] ?? 'غير متاح'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (((task['result'] as Map)['diagnostics'] as Map)['message'] is String)
                Text('${((task['result'] as Map)['diagnostics'] as Map)['message']}',
                    textDirection: TextDirection.rtl),
              for (final diagnostic in (((task['result'] as Map)['diagnostics'] as Map)['failedJobs'] as List? ?? const []))
                if (diagnostic is Map) ...[
                  Text('الوظيفة: ${diagnostic['jobName'] ?? diagnostic['jobId'] ?? 'غير معروفة'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (diagnostic['message'] is String)
                    Text('${diagnostic['message']}', textDirection: TextDirection.rtl),
                  for (final evidence in (diagnostic['evidence'] as List? ?? const []))
                    if (evidence is Map)
                      SelectableText(
                        'L${evidence['line']}: ${evidence['text']}',
                        textDirection: TextDirection.ltr,
                      ),
                ],
              for (final step in (((task['result'] as Map)['diagnostics'] as Map)['failedSteps'] as List? ?? const []))
                if (step is Map) ...[
                  Text('الخطوة الفاشلة: ${step['name'] ?? 'غير معروفة'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  for (final evidence in (step['evidence'] as List? ?? const []))
                    if (evidence is Map)
                      SelectableText(
                        'L${evidence['line']}: ${evidence['text']}',
                        textDirection: TextDirection.ltr,
                      ),
                ],
            ],
            if (task['result'] is Map && (task['result'] as Map)['videoUrl'] is String) ...[
              const SizedBox(height: 8),
              SelectableText('رابط الفيديو: ${(task['result'] as Map)['videoUrl']}', textDirection: TextDirection.ltr),
            ],
            if (task['error'] is String && (task['error'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('الخطأ: ${task['error']}', style: const TextStyle(color: Colors.orangeAccent), textDirection: TextDirection.rtl),
            ],
            const SizedBox(height: 6),
            Text('المعرف: ${task['taskId'] ?? ''}', style: const TextStyle(fontSize: 11)),

            if (task['status'] == 'failed' &&
                task['result'] is Map &&
                (task['result'] as Map)['diagnostics'] is Map &&
                ((task['result'] as Map)['diagnostics'] as Map)['status'] == 'available')
              TextButton.icon(
                onPressed: _busy ? null : () => _generateRepairProposal(task),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('اقترح إصلاحاً بالذكاء الاصطناعي'),
              ),

            Wrap(spacing: 8, children: [
              if (task['status'] == 'awaiting_approval')
                TextButton(onPressed: _busy ? null : () => _taskAction('approveNovaTask', '${task['taskId']}'),
                    child: const Text('موافقة')),
              if (task['status'] == 'queued' || task['status'] == 'awaiting_approval')
                TextButton(onPressed: _busy ? null : () => _taskAction('cancelNovaTask', '${task['taskId']}'),
                    child: const Text('إلغاء')),
            ]),
          ],
        ))),
    ],
  );
}
