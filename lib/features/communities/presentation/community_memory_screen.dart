import 'package:flutter/material.dart';

import '../../../services/social/community_memory_service.dart';

class AurenCommunityMemoryScreen extends StatefulWidget {
  final String communityId;

  const AurenCommunityMemoryScreen({super.key, required this.communityId});

  @override
  State<AurenCommunityMemoryScreen> createState() =>
      _AurenCommunityMemoryScreenState();
}

class _AurenCommunityMemoryScreenState
    extends State<AurenCommunityMemoryScreen> {
  final AurenCommunityMemoryService _service = AurenCommunityMemoryService();

  Future<void> _add() async {
    final title = TextEditingController();
    final body = TextEditingController();
    var kind = 'milestone';

    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setLocalState) => AlertDialog(
            title: const Text('إضافة إلى ذاكرة المجتمع'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    items: const [
                      DropdownMenuItem(value: 'milestone', child: Text('إنجاز')),
                      DropdownMenuItem(value: 'decision', child: Text('قرار')),
                      DropdownMenuItem(value: 'outcome', child: Text('نتيجة')),
                    ],
                    onChanged: (value) {
                      if (value != null) setLocalState(() => kind = value);
                    },
                  ),
                  TextField(
                    controller: title,
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextField(
                    controller: body,
                    maxLength: 2000,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'التفاصيل'),
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
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      );

      if (accepted != true) return;
      await _service.createEntry(
        communityId: widget.communityId,
        kind: kind,
        title: title.text,
        body: body.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة السجل')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: $error')),
        );
      }
    } finally {
      title.dispose();
      body.dispose();
    }
  }

  String _kindLabel(String kind) => switch (kind) {
        'decision' => 'قرار',
        'outcome' => 'نتيجة',
        _ => 'إنجاز',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('ذاكرة المجتمع'),
          actions: [
            IconButton(
              tooltip: 'إضافة سجل',
              onPressed: _add,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        body: StreamBuilder<List<AurenCommunityMemoryEntry>>(
          stream: _service.watchEntries(widget.communityId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل ذاكرة المجتمع. تأكد من عضويتك والاتصال.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data!;
            if (entries.isEmpty) {
              return const Center(
                child: Text('لا توجد إنجازات أو قرارات محفوظة بعد.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history_edu_outlined),
                    title: Text(entry.title),
                    subtitle: Text(
                      '${_kindLabel(entry.kind)}\n${entry.body}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      );
}
