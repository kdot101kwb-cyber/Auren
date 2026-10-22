import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/social/community_workbench_store.dart';

class AurenCommunityWorkbenchScreen extends StatefulWidget {
  const AurenCommunityWorkbenchScreen({super.key});
  @override
  State<AurenCommunityWorkbenchScreen> createState() => _AurenCommunityWorkbenchScreenState();
}

class _AurenCommunityWorkbenchScreenState extends State<AurenCommunityWorkbenchScreen>
    with SingleTickerProviderStateMixin {
  final _store = AurenCommunityWorkbenchStore();
  late final TabController _tabs;
  bool _busy = false;
  int _refresh = 0;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  String get _voterId => FirebaseAuth.instance.currentUser?.uid ?? 'local-device';

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(() => _refresh++);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التغيير محلياً: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<String>?> _ask(String title, List<_Field> fields) async {
    final controllers = fields.map((_) => TextEditingController()).toList();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < fields.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
              controller: controllers[i], maxLength: fields[i].maxLength,
              maxLines: fields[i].maxLines, keyboardType: fields[i].keyboardType,
              decoration: InputDecoration(labelText: fields[i].label, hintText: fields[i].hint),
            ))])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controllers.map((c) => c.text).toList()),
            child: const Text('حفظ كمسودة')),
        ],
      ),
    );
    for (final c in controllers) { c.dispose(); }
    return result;
  }

  Future<void> _createProject() async {
    final p = await _ask('مشروع جماعي جديد', const [
      _Field('اسم المشروع', maxLength: 120),
      _Field('الوصف', maxLength: 2000, maxLines: 3),
      _Field('معرّف المجتمع (اختياري)', maxLength: 160),
    ]);
    if (p == null) return;
    await _run(() async { await _store.createProject(title: p[0], description: p[1], communityId: p[2]); });
  }

  Future<void> _addTask(String id) async {
    final p = await _ask('إضافة مهمة', const [
      _Field('اسم المهمة', maxLength: 160), _Field('المسؤول (اختياري)', maxLength: 128),
    ]);
    if (p == null) return;
    await _run(() => _store.addProjectTask(projectId: id, title: p[0], assignee: p[1]));
  }

  Future<void> _addMilestone(String id) async {
    final p = await _ask('إضافة مرحلة', const [_Field('اسم المرحلة', maxLength: 160)]);
    if (p == null) return;
    await _run(() => _store.addProjectMilestone(projectId: id, title: p[0]));
  }

  Future<void> _createProposal() async {
    final p = await _ask('اقتراح قاعدة للمجتمع', const [
      _Field('معرّف المجتمع', maxLength: 160),
      _Field('عنوان الاقتراح', maxLength: 120),
      _Field('نص القاعدة المقترحة', maxLength: 2000, maxLines: 4),
    ]);
    if (p == null) return;
    await _run(() async { await _store.createRuleProposal(communityId: p[0], title: p[1], proposedRule: p[2]); });
  }

  Future<void> _createMeetup() async {
    final p = await _ask('مسودة لقاء مجتمعي', const [
      _Field('اسم اللقاء', maxLength: 120),
      _Field('الوصف', maxLength: 2000, maxLines: 3),
      _Field('موعد ISO مثل 2026-11-01T17:00:00Z', maxLength: 40),
      _Field('المكان أو رابط مقترح (نص فقط)', maxLength: 160),
      _Field('السعة المقترحة (رقم)', maxLength: 5, keyboardType: TextInputType.number),
    ]);
    if (p == null) return;
    final capacity = int.tryParse(p[4].trim());
    if (capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل السعة المقترحة كرقم صحيح.')));
      return;
    }
    await _run(() async { await _store.createMeetupDraft(title: p[0], description: p[1],
      startsAt: p[2], location: p[3], capacity: capacity); });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community & Collaboration'),
      bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
        Tab(icon: Icon(Icons.groups_2_outlined), text: 'المشاريع'),
        Tab(icon: Icon(Icons.how_to_vote_outlined), text: 'الحوكمة'),
        Tab(icon: Icon(Icons.event_outlined), text: 'اللقاءات'),
      ])),
    body: Column(children: [
      Material(color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(padding: EdgeInsets.all(12), child: Row(children: [
          Icon(Icons.offline_bolt_outlined), SizedBox(width: 8),
          Expanded(child: Text('حفظ محلي أولاً. الاقتراحات والتصويت والحضور مسودات على هذا الجهاز؛ لا نشر أو حجز أو دفع تلقائي.')),
        ]))),
      Expanded(child: TabBarView(controller: _tabs, children: [_projectsTab(), _governanceTab(), _meetupsTab()])),
    ]),
    floatingActionButton: AnimatedBuilder(animation: _tabs, builder: (context, _) =>
      FloatingActionButton.extended(onPressed: _busy ? null : () {
        if (_tabs.index == 0) _createProject();
        if (_tabs.index == 1) _createProposal();
        if (_tabs.index == 2) _createMeetup();
      }, icon: const Icon(Icons.add), label: Text(_tabs.index == 0 ? 'مشروع' : _tabs.index == 1 ? 'اقتراح قاعدة' : 'لقاء'))),
  );

  Widget _projectsTab() => FutureBuilder<List<Map<String, dynamic>>>(
    key: ValueKey('projects-$_refresh'), future: _store.listProjects(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return _errorState();
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data!;
      if (items.isEmpty) return _emptyState('لا توجد مشاريع بعد', 'أنشئ مشروعاً ثم أضف المهام والمراحل.');
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
        final project = items[i];
        final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List? ?? const []);
        final milestones = List<Map<String, dynamic>>.from(project['milestones'] as List? ?? const []);
        final progress = _store.projectProgress(project);
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${project['title']}', style: Theme.of(context).textTheme.titleMedium),
          if ('${project['description']}'.isNotEmpty) Text('${project['description']}'),
          const SizedBox(height: 8), LinearProgressIndicator(value: progress / 100),
          Text('التقدم $progress% • ${tasks.length} مهام • ${milestones.length} مراحل'),
          Wrap(spacing: 8, children: [
            TextButton.icon(onPressed: _busy ? null : () => _addTask('${project['id']}'), icon: const Icon(Icons.add_task), label: const Text('مهمة')),
            TextButton.icon(onPressed: _busy ? null : () => _addMilestone('${project['id']}'), icon: const Icon(Icons.flag_outlined), label: const Text('مرحلة')),
          ]),
          for (final task in tasks) CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero, value: task['status'] == 'done',
            title: Text('${task['title']}'),
            subtitle: Text('${task['assignee']}'.isEmpty ? 'غير مسندة' : 'المسؤول: ${task['assignee']}'),
            onChanged: _busy ? null : (done) => _run(() => _store.setProjectTaskStatus(
              projectId: '${project['id']}', taskId: '${task['id']}', status: done == true ? 'done' : 'todo')),
          ),
          for (final m in milestones) CheckboxListTile(
            dense: true, contentPadding: EdgeInsets.zero, value: m['completed'] == true,
            title: Text('مرحلة: ${m['title']}'),
            onChanged: _busy ? null : (done) => _run(() => _store.setMilestoneCompleted(
              projectId: '${project['id']}', milestoneId: '${m['id']}', completed: done == true)),
          ),
        ])));
      });
    });

  Widget _governanceTab() => FutureBuilder<List<Map<String, dynamic>>>(
    key: ValueKey('governance-$_refresh'), future: _store.listProposals(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return _errorState();
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data!;
      if (items.isEmpty) return _emptyState('لا توجد اقتراحات', 'اكتب قاعدة مقترحة ثم سجّل رأيك محلياً.');
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
        final p = items[i];
        final votes = Map<String, bool>.from(p['votes'] as Map? ?? const {});
        final voted = votes.containsKey(_voterId);
        final yes = _store.proposalSupportCount(p);
        final no = votes.length - yes;
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${p['title']}', style: Theme.of(context).textTheme.titleMedium),
          Text('${p['proposedRule']}'),
          Text('المجتمع: ${p['communityId']} • مؤيد $yes • معارض $no • الحالة: ${p['status']}'),
          const Text('التصويت والأرقام محفوظة محلياً على هذا الجهاز وليست نتيجة رسمية للمجتمع.'),
          if (p['status'] == 'open') Wrap(children: [
            TextButton(onPressed: _busy || voted ? null : () => _run(() => _store.voteOnProposal(proposalId: '${p['id']}', voterId: _voterId, support: true)), child: const Text('أؤيد')),
            TextButton(onPressed: _busy || voted ? null : () => _run(() => _store.voteOnProposal(proposalId: '${p['id']}', voterId: _voterId, support: false)), child: const Text('أعارض')),
            TextButton(onPressed: _busy ? null : () => _run(() => _store.closeProposal(proposalId: '${p['id']}', status: yes > no ? 'accepted' : 'rejected')), child: const Text('إغلاق المسودة بالنتيجة الحالية')),
          ]),
          if (voted) const Text('تم تسجيل صوتك على هذا الجهاز.'),
        ])));
      });
    });

  Widget _meetupsTab() => FutureBuilder<List<Map<String, dynamic>>>(
    key: ValueKey('meetups-$_refresh'), future: _store.listMeetupDrafts(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return _errorState();
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data!;
      if (items.isEmpty) return _emptyState('لا توجد لقاءات', 'أنشئ مسودة لقاء وأدر الاهتمام والحضور محلياً.');
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (context, i) {
        final m = items[i];
        final attendance = Map<String, String>.from(m['attendance'] as Map? ?? const {});
        final current = attendance[_voterId] ?? 'interested';
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.event_note_outlined), const SizedBox(width: 8), Expanded(child: Text('${m['title']}', style: Theme.of(context).textTheme.titleMedium)), const Chip(label: Text('مسودة'))]),
          if ('${m['description']}'.isNotEmpty) Text('${m['description']}'),
          Text('الموعد: ${m['startsAt']}'), Text('المكان المقترح: ${m['location']}'),
          Text('السعة المقترحة: ${m['capacity']} • سجلات الحضور المحلية: ${attendance.length} • سيحضر: ${_store.meetupGoingCount(m)}'),
          DropdownButton<String>(value: current, items: const [
            DropdownMenuItem(value: 'interested', child: Text('مهتم')),
            DropdownMenuItem(value: 'going', child: Text('سأحضر')),
            DropdownMenuItem(value: 'declined', child: Text('لن أحضر')),
          ], onChanged: _busy ? null : (value) { if (value != null) _run(() => _store.setDraftAttendance(meetupId: '${m['id']}', attendeeId: _voterId, status: value)); }),
          const Text('لا يتم نشر الفعالية أو حجز مقعد أو دفع أي مبلغ تلقائياً.'),
        ])));
      });
    });

  Widget _emptyState(String title, String subtitle) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.offline_bolt_outlined, size: 40), const SizedBox(height: 10),
      Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center),
    ])));
  Widget _errorState() => const Center(child: Text('تعذر قراءة البيانات المحلية. يمكنك المحاولة مجدداً.'));
}

class _Field {
  const _Field(this.label, {required this.maxLength, this.maxLines = 1, this.keyboardType, this.hint});
  final String label;
  final int maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? hint;
}
