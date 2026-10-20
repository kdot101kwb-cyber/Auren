import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first notebook for capturing research notes on this device.
class AurenKnowledgeNotebookScreen extends StatefulWidget {
  const AurenKnowledgeNotebookScreen({super.key});

  @override
  State<AurenKnowledgeNotebookScreen> createState() =>
      _AurenKnowledgeNotebookScreenState();
}

class _AurenKnowledgeNotebookScreenState
    extends State<AurenKnowledgeNotebookScreen> {
  static const _storageKey = 'auren_knowledge_notebook_v1';
  final List<_NotebookEntry> _entries = [];
  bool _loading = true;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(_NotebookEntry.fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(entries);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _storageError = 'تعذّر قراءة الملاحظات المحفوظة على هذا الجهاز.';
      });
    }
  }

  Future<void> _persist() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(_entries.map((entry) => entry.toJson()).toList()),
      );
      if (mounted) setState(() => _storageError = null);
    } catch (_) {
      if (mounted) {
        setState(() => _storageError =
            'تعذّر حفظ التغيير. انسخ ملاحظتك قبل مغادرة الشاشة.');
      }
    }
  }

  Future<void> _addEntry() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final result = await showDialog<_NotebookEntry>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ملاحظة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'عنوان الملاحظة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 7,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'الفكرة أو المعلومة أو سؤال البحث',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              final now = DateTime.now().toUtc().toIso8601String();
              Navigator.pop(
                dialogContext,
                _NotebookEntry(
                  id: now,
                  title: title,
                  body: body,
                  updatedAt: now,
                ),
              );
            },
            child: const Text('حفظ الملاحظة'),
          ),
        ],
      ),
    );
    titleController.dispose();
    bodyController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _entries.insert(0, result);
      _storageError = null;
    });
    await _persist();
  }

  Future<void> _deleteEntry(_NotebookEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الملاحظة؟'),
        content: Text('سيتم حذف «${entry.title}» من هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _entries.removeWhere((item) => item.id == entry.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Knowledge Notebook')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  'أفكارك ومعرفتك في مكان واحد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'دفتر محلي يعمل دون اتصال. الملاحظات محفوظة على هذا الجهاز فقط، '
                  'ولا تتم مزامنتها إلى حسابك أو أجهزة أخرى.',
                ),
                if (_storageError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _storageError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                if (_entries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book_outlined, size: 36),
                          SizedBox(height: 8),
                          Text('دفترك جاهز'),
                          SizedBox(height: 4),
                          Text('احفظ أول فكرة أو ملاحظة بحثية لتعود إليها لاحقاً.'),
                        ],
                      ),
                    ),
                  )
                else
                  ..._entries.map(
                    (entry) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.sticky_note_2_outlined),
                        ),
                        title: Text(
                          entry.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(entry.body, maxLines: 4, overflow: TextOverflow.ellipsis),
                        ),
                        trailing: IconButton(
                          tooltip: 'حذف الملاحظة',
                          onPressed: () => _deleteEntry(entry),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NotebookEntry {
  const _NotebookEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt,
      };

  factory _NotebookEntry.fromJson(Map<String, dynamic> json) {
    return _NotebookEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'ملاحظة بدون عنوان',
      body: json['body'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
