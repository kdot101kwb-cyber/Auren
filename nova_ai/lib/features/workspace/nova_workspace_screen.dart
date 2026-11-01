import 'package:flutter/material.dart';

import '../../core/offline/nova_local_workspace_store.dart';

/// Device-local workspace UI. Tasks remain on this device; this screen does
/// not start agents or perform external actions.
class NovaWorkspaceScreen extends StatefulWidget {
  const NovaWorkspaceScreen({super.key, this.store});

  final NovaLocalWorkspaceStore? store;

  @override
  State<NovaWorkspaceScreen> createState() => _NovaWorkspaceScreenState();
}

class _NovaWorkspaceScreenState extends State<NovaWorkspaceScreen> {
  late final NovaLocalWorkspaceStore _store =
      widget.store ?? NovaLocalWorkspaceStore();
  final _title = TextEditingController();
  final _details = TextEditingController();
  List<NovaWorkspaceTask> _tasks = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _store.loadTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر قراءة مساحة العمل المحلية.';
      });
    }
  }

  Future<void> _addTask() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now().toUtc();
    final task = NovaWorkspaceTask(
      id: 'local-${now.microsecondsSinceEpoch}',
      title: title,
      details: _details.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    try {
      final saved = await _store.saveTask(task);
      if (!saved) throw StateError('save failed');
      _title.clear();
      _details.clear();
      if (mounted) Navigator.of(context).pop();
      await _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر حفظ المهمة على الجهاز.');
    }
  }

  Future<void> _showAddDialog() async {
    _title.clear();
    _details.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مهمة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'عنوان المهمة'),
            ),
            TextField(
              controller: _details,
              textDirection: TextDirection.rtl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'تفاصيل اختيارية'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _addTask,
            child: const Text('حفظ محلياً'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(NovaWorkspaceTask task, bool value) async {
    await _store.setCompleted(task.id, value);
    await _reload();
  }

  Future<void> _delete(NovaWorkspaceTask task) async {
    await _store.deleteTask(task.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((task) => task.isCompleted).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مساحة عمل NOVA'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(child: _Metric(label: 'كل المهام', value: '${_tasks.length}')),
                          Expanded(child: _Metric(label: 'مكتملة', value: '$completed')),
                          Expanded(child: _Metric(label: 'متبقية', value: '${_tasks.length - completed}')),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  if (_tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 52),
                          SizedBox(height: 12),
                          Text('مساحة العمل فارغة. أضف أول مهمة.'),
                          SizedBox(height: 6),
                          Text('تُحفظ المهام على هذا الجهاز فقط.'),
                        ],
                      ),
                    ),
                  ..._tasks.map((task) => Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) => _toggle(task, value ?? false),
                      ),
                      title: Text(
                        task.title,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: task.details.isEmpty
                          ? null
                          : Text(task.details, textDirection: TextDirection.rtl),
                      trailing: IconButton(
                        tooltip: 'حذف',
                        onPressed: () => _delete(task),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Text(
                    'تنبيه الخصوصية: هذه المهام محلية ولا تتم مزامنتها مع السحابة. لا تحفظ كلمات المرور أو مفاتيح المحافظ أو عبارات الاسترداد هنا.',
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(label, textDirection: TextDirection.rtl),
    ],
  );
}
