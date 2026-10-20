import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/auth_service.dart';
import '../domain/creative_project.dart';

/// Offline-first planning board for creative work. Media stays in existing
/// Media Studio; this screen stores project metadata and version notes only.
class AurenCreativeProjectsScreen extends StatefulWidget {
  const AurenCreativeProjectsScreen({super.key});

  @override
  State<AurenCreativeProjectsScreen> createState() => _AurenCreativeProjectsScreenState();
}

class _AurenCreativeProjectsScreenState extends State<AurenCreativeProjectsScreen> {
  final _auth = FirebaseAurenAuthService();
  List<AurenCreativeProject> _projects = [];
  bool _loading = true;
  String? get _uid => _auth.currentUserId;
  String _key(String uid) => 'auren.creative_projects.v1.$uid';

  @override
  void initState() {
    super.initState();
    _load();
  }

  AurenCreativeProject _decode(Map<String, dynamic> value) => AurenCreativeProject(
        id: value['id'] as String,
        ownerId: value['ownerId'] as String,
        title: value['title'] as String,
        description: value['description'] as String? ?? '',
        status: CreativeProjectStatus.values.firstWhere(
          (s) => s.name == value['status'],
          orElse: () => CreativeProjectStatus.planning,
        ),
        createdAt: DateTime.parse(value['createdAt'] as String),
        updatedAt: DateTime.parse(value['updatedAt'] as String),
        assets: (value['assets'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((a) => CreativeAssetReference(
                  id: a['id'] as String,
                  name: a['name'] as String,
                  kind: CreativeAssetKind.values.firstWhere(
                    (k) => k.name == a['kind'],
                    orElse: () => CreativeAssetKind.other,
                  ),
                  uri: a['uri'] as String,
                  addedAt: DateTime.parse(a['addedAt'] as String),
                  contentType: a['contentType'] as String?,
                  sizeBytes: a['sizeBytes'] as int?,
                  checksum: a['checksum'] as String?,
                ))
            .toList(),
        versions: (value['versions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((v) => CreativeProjectVersion(
                  number: v['number'] as int,
                  summary: v['summary'] as String,
                  createdAt: DateTime.parse(v['createdAt'] as String),
                  snapshotUri: v['snapshotUri'] as String?,
                ))
            .toList(),
      );

  Map<String, dynamic> _encode(AurenCreativeProject project) => {
        'id': project.id,
        'ownerId': project.ownerId,
        'title': project.title,
        'description': project.description,
        'status': project.status.name,
        'createdAt': project.createdAt.toIso8601String(),
        'updatedAt': project.updatedAt.toIso8601String(),
        'assets': project.assets.map((a) => {
          'id': a.id, 'name': a.name, 'kind': a.kind.name, 'uri': a.uri,
          'addedAt': a.addedAt.toIso8601String(), 'contentType': a.contentType,
          'sizeBytes': a.sizeBytes, 'checksum': a.checksum,
        }).toList(),
        'versions': project.versions.map((v) => {
          'number': v.number, 'summary': v.summary,
          'createdAt': v.createdAt.toIso8601String(), 'snapshotUri': v.snapshotUri,
        }).toList(),
      };

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      final data = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final projects = data.whereType<Map<String, dynamic>>().map(_decode).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) setState(() => _projects = projects);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل المشاريع: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(List<AurenCreativeProject> projects) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in required');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), jsonEncode(projects.map(_encode).toList()));
    if (mounted) setState(() => _projects = projects);
  }

  Future<void> _createOrEdit({AurenCreativeProject? project}) async {
    final uid = _uid;
    if (uid == null) return;
    final title = TextEditingController(text: project?.title ?? '');
    final description = TextEditingController(text: project?.description ?? '');
    var status = project?.status ?? CreativeProjectStatus.planning;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(project == null ? 'مشروع إبداعي جديد' : 'تعديل المشروع',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(controller: title, maxLength: 100,
                    decoration: const InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: description, minLines: 3, maxLines: 5,
                    decoration: const InputDecoration(labelText: 'الهدف والخطة', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<CreativeProjectStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                  items: CreativeProjectStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                  onChanged: (value) { if (value != null) setSheetState(() => status = value); },
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    if (title.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم المشروع أولاً.')));
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ المشروع'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) {
      title.dispose();
      description.dispose();
      return;
    }

    final now = DateTime.now();
    final updatedTitle = title.text.trim();
    final updatedDescription = description.text.trim();
    final versions = List<CreativeProjectVersion>.from(project?.versions ?? const []);
    if (project != null &&
        (project.title != updatedTitle || project.description != updatedDescription || project.status != status)) {
      final latest = versions.isEmpty ? 0 : versions.map((v) => v.number).reduce((a, b) => a > b ? a : b);
      final changedFields = <String>[
        if (project.title != updatedTitle) 'الاسم',
        if (project.description != updatedDescription) 'الخطة',
        if (project.status != status) 'الحالة',
      ];
      versions.add(CreativeProjectVersion(
        number: latest + 1,
        summary: 'تعديل: ${changedFields.join('، ')}',
        createdAt: now,
      ));
    }
    final result = AurenCreativeProject(
      id: project?.id ?? 'project-${now.microsecondsSinceEpoch}',
      ownerId: uid,
      title: updatedTitle,
      description: updatedDescription,
      status: status,
      createdAt: project?.createdAt ?? now,
      updatedAt: now,
      assets: project?.assets ?? const [],
      versions: versions,
    );
    final projects = [result, ..._projects.where((p) => p.id != result.id)]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    try {
      await _persist(projects);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المشروع على الجهاز.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $error')));
    } finally {
      title.dispose();
      description.dispose();
    }
  }

  Future<void> _showVersionHistory(AurenCreativeProject project) async {
    final versions = [...project.versions]
      ..sort((a, b) => b.number.compareTo(a.number));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('سجل المشروع: ${project.title}'),
        content: SizedBox(
          width: 420,
          child: versions.isEmpty
              ? const Text('لا توجد مراجعات مسجلة لهذا المشروع حتى الآن.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: versions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('v${version.number}')),
                      title: Text(version.summary),
                      subtitle: Text(
                        '${version.createdAt.toLocal().toString().split('.').first}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(AurenCreativeProject project) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشروع؟'),
        content: Text('سيتم حذف «${project.title}» من هذا الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (yes == true) {
      try {
        await _persist(_projects.where((p) => p.id != project.id).toList());
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحذف: $error')));
      }
    }
  }

  String _statusLabel(CreativeProjectStatus status) => switch (status) {
    CreativeProjectStatus.planning => 'تخطيط',
    CreativeProjectStatus.active => 'قيد التنفيذ',
    CreativeProjectStatus.paused => 'متوقف مؤقتاً',
    CreativeProjectStatus.completed => 'مكتمل',
    CreativeProjectStatus.archived => 'مؤرشف',
  };

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لإدارة المشاريع.')));
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Creative Projects'), actions: [
        IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _createOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('مشروع جديد'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const Text('نظّم الفكرة والخطة والحالة وسجل التغييرات في مساحة واحدة.'),
          const SizedBox(height: 12),
          if (_projects.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(22),
              child: Column(children: [
                Icon(Icons.workspaces_outline, size: 42),
                SizedBox(height: 8),
                Text('ابدأ مشروعك الإبداعي الأول'),
                Text('فيلم، بودكاست، تصميم، حملة أو مستند طويل.'),
              ]),
            ))
          else
            ..._projects.map((p) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.workspaces_outline)),
                title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${_statusLabel(p.status)} • ${p.assets.length} أصول • ${p.versions.length} مراجعات\n${p.description}'),
                isThreeLine: true,
                onTap: () => _createOrEdit(project: p),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _createOrEdit(project: p);
                    if (v == 'history') _showVersionHistory(p);
                    if (v == 'delete') _delete(p);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تحرير')),
                    const PopupMenuItem(value: 'history', child: Text('سجل المراجعات')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 12),
          const Text('المشاريع محفوظة محلياً فقط حالياً. رفع الأصول ومشاركتها والمزامنة السحابية تحتاج تكاملاً لاحقاً.',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
