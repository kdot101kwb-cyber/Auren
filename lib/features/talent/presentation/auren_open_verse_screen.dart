import 'package:flutter/material.dart';

import '../../../services/talent/auren_open_verse_workspace.dart';

class AurenOpenVerseScreen extends StatefulWidget {
  const AurenOpenVerseScreen({super.key});

  @override
  State<AurenOpenVerseScreen> createState() => _AurenOpenVerseScreenState();
}

class _AurenOpenVerseScreenState extends State<AurenOpenVerseScreen> {
  final _workspace = AurenOpenVerseWorkspace();
  final _title = TextEditingController();
  final _brief = TextEditingController();
  final _genre = TextEditingController();
  final _roles = TextEditingController();
  final _bpm = TextEditingController();
  List<AurenOpenVerseProject> _projects = const [];
  String? _editingId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _title.dispose();
    _brief.dispose();
    _genre.dispose();
    _roles.dispose();
    _bpm.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final projects = await _workspace.listProjects();
      if (mounted) setState(() { _projects = projects; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'تعذر قراءة المسودات المحلية.'; });
    }
  }

  void _clearForm() {
    _title.clear();
    _brief.clear();
    _genre.clear();
    _roles.clear();
    _bpm.clear();
    setState(() { _editingId = null; _error = null; });
  }

  void _edit(AurenOpenVerseProject project) {
    _title.text = project.title;
    _brief.text = project.brief;
    _genre.text = project.genre;
    _roles.text = project.roles;
    _bpm.text = project.bpm?.toString() ?? '';
    setState(() { _editingId = project.id; _error = null; });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final rawBpm = _bpm.text.trim();
      final bpm = rawBpm.isEmpty ? null : int.tryParse(rawBpm);
      if (rawBpm.isNotEmpty && bpm == null) {
        throw ArgumentError('أدخل سرعة BPM كرقم صحيح.');
      }
      await _workspace.saveProject(
        id: _editingId,
        title: _title.text,
        brief: _brief.text,
        genre: _genre.text,
        roles: _roles.text,
        bpm: bpm,
      );
      await _refresh();
      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ مسودة التعاون على الجهاز.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ArgumentError || e is StateError
          ? e.toString().replaceFirst('Invalid argument(s): ', '')
          : 'تعذر حفظ المسودة. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(AurenOpenVerseProject project) async {
    try {
      await _workspace.removeProject(project.id);
      await _refresh();
      if (_editingId == project.id) _clearForm();
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر حذف المسودة.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Open Verse')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ابنِ مشروعك الموسيقي مع الآخرين',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('خطط للأغنية والأدوار المطلوبة محلياً. لا تُرسل دعوات ولا ترفع ملفات ولا تنفذ مدفوعات من هذه الشاشة.'),
                const SizedBox(height: 16),
                TextField(controller: _title, maxLength: 120,
                    decoration: const InputDecoration(labelText: 'اسم المشروع', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _brief, maxLines: 3, maxLength: 4000,
                    decoration: const InputDecoration(labelText: 'فكرة الأغنية أو وصف التعاون', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _genre, maxLength: 80,
                    decoration: const InputDecoration(labelText: 'النوع الموسيقي (اختياري)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _roles, maxLines: 2, maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'الأدوار المطلوبة (مثلاً: مغنٍ، كاتب، منتج)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _bpm, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'BPM (اختياري، من 40 إلى 240)', border: OutlineInputBorder())),
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(_saving ? Icons.hourglass_top : Icons.save_outlined),
                    label: Text(_editingId == null ? 'حفظ المسودة' : 'تحديث المسودة'),
                  )),
                  if (_editingId != null) ...[
                    const SizedBox(width: 8),
                    IconButton(onPressed: _clearForm, tooltip: 'إلغاء التعديل', icon: const Icon(Icons.close)),
                  ],
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text('مسوداتي (${_projects.length}/${AurenOpenVerseWorkspace.maxProjects})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (!_loading && _projects.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد مسودات بعد. أنشئ أول مشروع تعاون موسيقي.'))),
          ..._projects.map((project) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.graphic_eq)),
              title: Text(project.title),
              subtitle: Text([
                if (project.genre.isNotEmpty) project.genre,
                if (project.bpm != null) '${project.bpm} BPM',
                if (project.roles.isNotEmpty) project.roles,
              ].join(' • ').isEmpty ? 'مسودة محلية' : [
                if (project.genre.isNotEmpty) project.genre,
                if (project.bpm != null) '${project.bpm} BPM',
                if (project.roles.isNotEmpty) project.roles,
              ].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => _edit(project),
              trailing: IconButton(
                tooltip: 'حذف المسودة',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(project),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
