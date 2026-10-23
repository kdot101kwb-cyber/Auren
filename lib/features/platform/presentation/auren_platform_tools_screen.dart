import 'package:flutter/material.dart';

import '../../../services/platform/auren_platform_tools_service.dart';

class AurenPlatformToolsScreen extends StatefulWidget {
  const AurenPlatformToolsScreen({super.key});

  @override
  State<AurenPlatformToolsScreen> createState() =>
      _AurenPlatformToolsScreenState();
}

class _AurenPlatformToolsScreenState extends State<AurenPlatformToolsScreen> {
  final _service = AurenPlatformToolsService();
  AurenConnectivityReport? _connectivity;
  AurenStorageSnapshot? _storage;
  List<AurenFeedbackDraft> _drafts = const [];
  bool _loading = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<Object>([
        _service.connectivityReport(),
        _service.inspectCache(),
        _service.feedbackDrafts(),
      ]);
      if (!mounted) return;
      setState(() {
        _connectivity = results[0] as AurenConnectivityReport;
        _storage = results[1] as AurenStorageSnapshot;
        _drafts = results[2] as List<AurenFeedbackDraft>;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث معلومات الأدوات.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDraft({required String kind}) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(kind == 'bug' ? 'الإبلاغ عن عطل' : 'إرسال ملاحظة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'عنوان مختصر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'التفاصيل',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ستُحفظ المسودة على هذا الجهاز فقط. لن تُرسل تلقائياً.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حفظ المسودة'),
            ),
          ],
        ),
      );
      if (saved != true) return;
      await _service.saveFeedback(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: kind,
        title: titleController.text,
        details: detailsController.text,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المسودة على الجهاز.')),
        );
      }
    } on ArgumentError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل عنواناً وتفاصيل صحيحة.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ المسودة.')),
        );
      }
    } finally {
      titleController.dispose();
      detailsController.dispose();
    }
  }

  Future<void> _removeDraft(AurenFeedbackDraft draft) async {
    try {
      await _service.removeFeedback(draft.id);
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حذف المسودة.')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح الملفات المؤقتة؟'),
        content: const Text(
          'سيتم حذف ملفات مركز أدوات AUREN المؤقتة فقط. '
          'لن تُحذف ملفات المستخدم أو تنزيلات الميزات الأخرى.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('مسح الملفات'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _clearing = true);
    try {
      await _service.clearOwnedCache();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح الملفات المؤقتة التابعة لهذه الصفحة.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر مسح الملفات المؤقتة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Platform Tools'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'المساعدة وأدوات الجهاز',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'أدوات مساعدة محلية؛ فحص الشبكة لا يضمن أن الإنترنت يعمل.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.help_outline),
                    title: Text('مركز المساعدة والإرشاد'),
                    subtitle: Text('إجابات قصيرة للمشكلات الشائعة'),
                  ),
                  ...AurenPlatformToolsService.helpTopics.map(
                    (topic) => ExpansionTile(
                      key: ValueKey('help-${topic.id}'),
                      title: Text(topic.title),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(topic.body),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text('تشخيص الاتصال'),
                  subtitle: Text('نوع الشبكة فقط، وليس اختباراً مؤكداً للإنترنت'),
                ),
                ListTile(
                  title: Text(_connectivity?.summary ?? 'لم يتم الفحص بعد.'),
                  trailing: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('مساحة التخزين المؤقتة'),
                  subtitle: Text(
                    _storage == null
                        ? 'لم يتم الفحص بعد.'
                        : '${AurenPlatformToolsService.formatBytes(_storage!.bytes)} • ${_storage!.fileCount} ملف',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _loading || _clearing ? null : _clearCache,
                      icon: _clearing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_sweep_outlined),
                      label: const Text('مسح ملفات هذه الأداة المؤقتة'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.feedback_outlined),
                    title: Text('الملاحظات والإبلاغ عن الأعطال'),
                    subtitle: Text('تُحفظ المسودات محلياً ولا تُرسل تلقائياً'),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _createDraft(kind: 'feedback'),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('ملاحظة جديدة'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _createDraft(kind: 'bug'),
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('الإبلاغ عن عطل'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_drafts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('لا توجد مسودات محفوظة.'),
                    )
                  else
                    ..._drafts.map(
                      (draft) => ListTile(
                        key: ValueKey('feedback-${draft.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          draft.kind == 'bug'
                              ? Icons.bug_report_outlined
                              : Icons.feedback_outlined,
                        ),
                        title: Text(draft.title),
                        subtitle: Text(
                          draft.details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'حذف المسودة',
                          onPressed: () => _removeDraft(draft),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
