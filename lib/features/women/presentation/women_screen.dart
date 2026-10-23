import 'package:flutter/material.dart';

import '../../../services/women/women_support_resource_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenWomenScreen extends StatefulWidget {
  const AurenWomenScreen({super.key});

  @override
  State<AurenWomenScreen> createState() => _AurenWomenScreenState();
}

class _AurenWomenScreenState extends State<AurenWomenScreen> {
  final _service = AurenWomenSupportResourceService();
  int _refresh = 0;
  bool _saving = false;

  Future<void> _addResource() async {
    final title = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مورد خاص'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'الاسم أو العنوان',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'اكتبي عنواناً أولاً'
                          : null,
                ),
                TextFormField(
                  controller: notes,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات اختيارية',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('حفظ على هذا الجهاز'),
          ),
        ],
      ),
    );
    final cleanTitle = title.text.trim();
    final cleanNotes = notes.text.trim();
    title.dispose();
    notes.dispose();
    if (result != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.add(title: cleanTitle, notes: cleanNotes);
      if (!mounted) return;
      setState(() => _refresh++);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المورد على هذا الجهاز.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ. تحققي من البيانات أو المساحة المتاحة.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      await _service.remove(id);
      if (mounted) setState(() => _refresh++);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف العنصر حالياً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Women'),
        actions: [
          IconButton(
            tooltip: 'اسألي AUREN',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessengerScreen(
                  initialPrompt:
                      'ساعدني في Women داخل AUREN واقترح خيارات وخطوات عملية، ووضّح ما يحتاج إلى تحقق.',
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addResource,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مورد خاص'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مساحة Women',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'احتفظي بقائمة خاصة من الموارد والملاحظات التي تختارينها. البيانات تبقى على هذا الجهاز ولا تُرسل إلى جهة خارجية.',
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('قائمة محلية خاصة — ليست دليلاً عاماً موثقاً.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'مواردي المحفوظة',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<AurenWomenSupportResource>>(
            key: ValueKey(_refresh),
            future: _service.list(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ListTile(
                  leading: Icon(Icons.error_outline),
                  title: Text('تعذر تحميل الموارد المحفوظة.'),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final resources = snapshot.data!;
              if (resources.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'لا توجد موارد محفوظة بعد. أضيفي اسماً أو ملاحظة تريدين الرجوع إليها لاحقاً.',
                    ),
                  ),
                );
              }
              return Column(
                children: resources
                    .map(
                      (resource) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.bookmark_outline),
                          ),
                          title: Text(resource.title),
                          subtitle: resource.notes.isEmpty
                              ? null
                              : Text(resource.notes),
                          trailing: IconButton(
                            tooltip: 'حذف من هذا الجهاز',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(resource.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
