import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/auth/auth_service.dart';
import '../domain/auren_document.dart';

/// Offline-first document drafts stored on this device, scoped to the signed-in
/// AUREN user. Export uses the platform share sheet; drafts remain local.
class AurenDocumentStudioScreen extends StatefulWidget {
  const AurenDocumentStudioScreen({super.key});

  @override
  State<AurenDocumentStudioScreen> createState() => _AurenDocumentStudioScreenState();
}

class _AurenDocumentStudioScreenState extends State<AurenDocumentStudioScreen> {
  final _auth = FirebaseAurenAuthService();
  final _search = TextEditingController();
  List<AurenDocument> _documents = [];
  bool _loading = true;
  String _filter = '';

  String? get _uid => _auth.currentUserId;
  String _storageKey(String uid) => 'auren.document_studio.v1.$uid';

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      if (mounted) setState(() => _filter = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(uid));
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final docs = decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _documents = docs);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح المسودات المحلية: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AurenDocument _fromJson(Map<String, dynamic> json) => AurenDocument(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        status: AurenDocumentStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => AurenDocumentStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        revisions: (json['revisions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((revision) => AurenDocumentRevision(
                  number: revision['number'] as int,
                  title: revision['title'] as String,
                  body: revision['body'] as String? ?? '',
                  savedAt: DateTime.parse(revision['savedAt'] as String),
                ))
            .toList(),
      );

  Map<String, dynamic> _toJson(AurenDocument doc) => {
        'id': doc.id,
        'ownerId': doc.ownerId,
        'title': doc.title,
        'body': doc.body,
        'status': doc.status.name,
        'createdAt': doc.createdAt.toIso8601String(),
        'updatedAt': doc.updatedAt.toIso8601String(),
        'revisions': doc.revisions
            .map((revision) => {
                  'number': revision.number,
                  'title': revision.title,
                  'body': revision.body,
                  'savedAt': revision.savedAt.toIso8601String(),
                })
            .toList(),
      };

  Future<void> _persist(List<AurenDocument> documents) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in required');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(uid),
      jsonEncode(documents.map(_toJson).toList()),
    );
    if (mounted) setState(() => _documents = documents);
  }

  Future<void> _edit({AurenDocument? existing}) async {
    final uid = _uid;
    if (uid == null) return;
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'مستند جديد' : 'تحرير المستند',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'عنوان المستند',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                minLines: 8,
                maxLines: 16,
                maxLength: 50000,
                decoration: const InputDecoration(
                  labelText: 'اكتب أفكارك أو مستندك هنا',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  if (title.text.trim().isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('أدخل عنواناً للمستند أولاً.')),
                    );
                    return;
                  }
                  Navigator.of(sheetContext).pop(true);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ على هذا الجهاز'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true || !mounted) {
      title.dispose();
      body.dispose();
      return;
    }

    final now = DateTime.now();
    final original = existing;
    final revisions = List<AurenDocumentRevision>.from(original?.revisions ?? const []);
    if (original != null &&
        (original.title != title.text.trim() || original.body != body.text)) {
      revisions.add(AurenDocumentRevision(
        number: (revisions.isEmpty ? 0 : revisions.map((r) => r.number).reduce((a, b) => a > b ? a : b)) + 1,
        title: original.title,
        body: original.body,
        savedAt: now,
      ));
    }
    final doc = AurenDocument(
      id: original?.id ?? 'doc-${now.microsecondsSinceEpoch}',
      ownerId: uid,
      title: title.text.trim(),
      body: body.text,
      status: AurenDocumentStatus.draft,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      revisions: revisions,
    );
    final updated = [doc, ..._documents.where((item) => item.id != doc.id)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    try {
      await _persist(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المستند محلياً.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ المستند: $error')),
        );
      }
    } finally {
      title.dispose();
      body.dispose();
    }
  }

  Future<void> _export(AurenDocument document) async {
    final text = '${document.title}\n\n${document.body}';
    try {
      await SharePlus.instance.share(ShareParams(
        title: document.title,
        subject: document.title,
        text: text,
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر مشاركة المستند: $error')),
        );
      }
    }
  }

  Future<void> _delete(AurenDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المسودة؟'),
        content: Text('سيُحذف «${document.title}» من هذا الجهاز.'),
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
    if (confirmed != true) return;
    try {
      await _persist(_documents.where((doc) => doc.id != document.id).toList());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حذف المسودة: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('سجّل الدخول لاستخدام Document Studio.')),
      );
    }
    final visible = _documents.where((doc) {
      if (_filter.isEmpty) return true;
      return doc.title.toLowerCase().contains(_filter) ||
          doc.body.toLowerCase().contains(_filter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Document Studio'),
        actions: [
          IconButton(
            tooltip: 'تحديث المسودات',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('مستند جديد'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                const Text(
                  'أفكارك ومستنداتك، في مساحة بسيطة تعمل دون اتصال.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث في العناوين والنصوص',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                if (_documents.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined, size: 42),
                          SizedBox(height: 8),
                          Text('ما عندك مستندات لسه'),
                          Text('ابدأ بملاحظة أو خطة أو مسودة جديدة.'),
                        ],
                      ),
                    ),
                  )
                else if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('ما لقينا مستنداً مطابقاً للبحث.'),
                  )
                else
                  ...visible.map((doc) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.description_outlined),
                          ),
                          title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${doc.body.trim().isEmpty ? 'مستند فارغ' : doc.body.trim()}\n'
                            'تعديلات محفوظة: ${doc.revisions.length}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          onTap: () => _edit(existing: doc),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') _edit(existing: doc);
                              if (action == 'share') _export(doc);
                              if (action == 'delete') _delete(doc);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('تحرير')),
                              PopupMenuItem(value: 'share', child: Text('مشاركة / تصدير النص')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 12),
                const Text(
                  'ملاحظة: المسودات محفوظة على هذا الجهاز فقط حالياً؛ المزامنة السحابية غير مفعّلة؛ يمكن مشاركة نص المستند عبر قائمة المشاركة في الجهاز.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
    );
  }
}
