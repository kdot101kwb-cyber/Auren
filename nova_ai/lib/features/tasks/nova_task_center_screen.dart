import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';
import '../../services/offline/nova_offline_store.dart';

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
  final _offlineStore = NovaOfflineStore();
  List<NovaOfflineTask> _offlineTasks = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineTasks();
  }

  Future<void> _loadOfflineTasks() async {
    try {
      final tasks = await _offlineStore.getTasks();
      if (mounted) setState(() => _offlineTasks = tasks);
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر تحميل المهام المحلية.');
    }
  }

  Future<void> _saveOfflineTask() async {
    final title = _prompt.text.trim();
    if (title.isEmpty) {
      setState(() => _message = 'اكتب وصف المهمة أولاً لحفظها محلياً.');
      return;
    }
    try {
      await _offlineStore.saveTask(NovaOfflineTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        notes: 'النوع: $_type',
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ));
      _prompt.clear();
      await _loadOfflineTasks();
      if (mounted) setState(() => _message = 'تم حفظ المهمة على الهاتف؛ ستظل متاحة بدون إنترنت.');
    } catch (_) {
      if (mounted) setState(() => _message = 'تعذر حفظ المهمة على الهاتف.');
    }
  }

  Future<void> _toggleOfflineTask(NovaOfflineTask task, bool complete) async {
    await _offlineStore.saveTask(NovaOfflineTask(
      id: task.id,
      title: task.title,
      notes: task.notes,
      isComplete: complete,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    ));
    await _loadOfflineTasks();
  }

  Future<void> _deleteOfflineTask(String id) async {
    await _offlineStore.deleteTask(id);
    await _loadOfflineTasks();
  }

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
    } catch (error) {
      setState(() => _message = 'تعذر تحميل المهام: $error');
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
        decoration: const InputDecoration(labelText: 'شنو داير NOVA تنفّذ؟', hintText: 'اكتب هدف المهمة بالتفصيل', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _busy ? null : _submitTask,
        icon: const Icon(Icons.send),
        label: Text(_busy ? 'جاري التنفيذ…' : 'إرسال المهمة للخادم'),
      ),
      OutlinedButton.icon(
        onPressed: _saveOfflineTask,
        icon: const Icon(Icons.save_outlined),
        label: const Text('احفظ المهمة على الهاتف دون إنترنت'),
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
      const SizedBox(height: 16),
      const Text('المهام المحفوظة على الهاتف — بدون إنترنت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (_offlineTasks.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('لا توجد مهام محلية محفوظة. يمكنك حفظ مهمة حتى عند انقطاع الاتصال.'),
        ),
      for (final task in _offlineTasks)
        Card(child: ListTile(
          leading: Checkbox(
            value: task.isComplete,
            onChanged: (value) => _toggleOfflineTask(task, value ?? false),
          ),
          title: Text(task.title, style: TextStyle(
            decoration: task.isComplete ? TextDecoration.lineThrough : TextDecoration.none,
          )),
          subtitle: Text(task.notes),
          trailing: IconButton(
            tooltip: 'حذف المهمة المحلية',
            onPressed: () => _deleteOfflineTask(task.id),
            icon: const Icon(Icons.delete_outline),
          ),
        )),
      const SizedBox(height: 12),
      const Text('المهام المسجلة في الخادم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (_tasks.isEmpty) const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('لا توجد مهام محمّلة بعد. اضغط تحديث القائمة بعد إعداد الاتصال.'),
      ),
      for (final task in _tasks)
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task['type'] ?? 'task'} — ${task['status'] ?? 'unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('${task['prompt'] ?? task['taskId'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis),
            if (task['result'] is Map && (task['result'] as Map)['text'] is String) ...[
              const SizedBox(height: 8),
              Text('النتيجة: ${(task['result'] as Map)['text']}', textDirection: TextDirection.rtl),
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
