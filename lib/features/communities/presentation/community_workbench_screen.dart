import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/social/community_workbench_store.dart';
import 'collaboration_spaces_screen.dart';

class AurenCommunityWorkbenchScreen extends StatefulWidget {
  const AurenCommunityWorkbenchScreen({super.key});
  @override
  State<AurenCommunityWorkbenchScreen> createState() => _AurenCommunityWorkbenchScreenState();
}

class _AurenCommunityWorkbenchScreenState extends State<AurenCommunityWorkbenchScreen>
    with SingleTickerProviderStateMixin {
  late AurenCommunityWorkbenchStore _store;
  StreamSubscription<User?>? _authSubscription;
  late final TabController _tabs;
  final TextEditingController _spaceIdController = TextEditingController();
  final TextEditingController _spaceTopicController = TextEditingController();
  final TextEditingController _spaceRulesController = TextEditingController();
  bool _busy = false;
  int _refresh = 0;
  int _accountGeneration = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    final auth = FirebaseAuth.instance;
    _store = AurenCommunityWorkbenchStore(
      scope: auth.currentUser?.uid ?? 'anonymous',
    );
    _authSubscription = auth.authStateChanges().listen((user) {
      if (!mounted) return;
      _accountGeneration++;
      // Never leave one account's unsaved private draft text visible after an
      // account switch on a shared device. Persisted records remain isolated
      // by the store scope; clear transient form contents as well.
      _spaceIdController.clear();
      _spaceTopicController.clear();
      _spaceRulesController.clear();
      setState(() {
        _store = AurenCommunityWorkbenchStore(scope: user?.uid ?? 'anonymous');
        _refresh++;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tabs.dispose();
    _spaceIdController.dispose();
    _spaceTopicController.dispose();
    _spaceRulesController.dispose();
    super.dispose();
  }

  String get _voterId => FirebaseAuth.instance.currentUser?.uid ?? 'local-device';

  String _proposalStatusLabel(Object? status) => switch (status) {
        'open' => 'مفتوح محلياً',
        'accepted' => 'مغلق محلياً: مؤيدون أكثر',
        'rejected' => 'مغلق محلياً: معارضون أكثر أو تعادل',
        'withdrawn' => 'مسحوب محلياً',
        _ => 'مسودة محلية',
      };

  Future<void> _run(Future<void> Function() action) async {
    final generation = _accountGeneration;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && generation == _accountGeneration) {
        setState(() => _refresh++);
      }
    } catch (error) {
      if (mounted && generation == _accountGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ التغيير محلياً: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLocalDelete({
    required String title,
    required String message,
    String confirmLabel = 'حذف محلي',
    required Future<void> Function() delete,
  }) async {
    // A confirmation dialog may remain open while a shared device changes
    // accounts. Never let a confirmation from the previous account execute
    // against the newly selected store.
    final generation = _accountGeneration;
    final requestedStore = _store;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        generation != _accountGeneration ||
        !identical(requestedStore, _store)) {
      return;
    }
    await _run(delete);
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

  Future<void> _loadSpaceGuidelines() async {
    final id = _spaceIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل معرّف مساحة التعاون أولاً.')),
      );
      return;
    }

    // A read can finish after sign-out/account-switch. Bind the request to the
    // initiating account and store so stale results/errors cannot repopulate
    // private form fields or show misleading feedback in the next account.
    final requestedStore = _store;
    final requestedUid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    bool requestStillBelongsToCurrentAccount() =>
        mounted &&
        identical(requestedStore, _store) &&
        (FirebaseAuth.instance.currentUser?.uid ?? 'anonymous') == requestedUid;

    try {
      final value = await requestedStore.readSpaceGuidelines(id);
      if (!requestStillBelongsToCurrentAccount()) return;
      _spaceTopicController.text = value['topic'] as String? ?? '';
      _spaceRulesController.text = value['rules'] as String? ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value.isEmpty ? 'لا توجد إرشادات محلية محفوظة لهذه المساحة.' : 'تم تحميل الإرشادات المحلية.'),
      ));
    } catch (error) {
      if (requestStillBelongsToCurrentAccount()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الإرشادات المحلية: $error')),
        );
      }
    }
  }

  Future<void> _saveSpaceGuidelines() async {
    final requestedStore = _store;
    final generation = _accountGeneration;
    final id = _spaceIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرّف مساحة التعاون مطلوب.')),
      );
      return;
    }
    if (generation != _accountGeneration || !identical(requestedStore, _store)) return;
    final topic = _spaceTopicController.text;
    final rules = _spaceRulesController.text;
    await _run(() => requestedStore.saveSpaceGuidelines(
      spaceId: id,
      topic: topic,
      rules: rules,
    ));
  }

  Future<void> _createProject() async {
    final generation = _accountGeneration;
    final p = await _ask('مشروع جماعي جديد', const [
      _Field('اسم المشروع', maxLength: 120),
      _Field('الوصف', maxLength: 2000, maxLines: 3),
      _Field('معرّف المجتمع (مطلوب)', maxLength: 160),
    ]);
    if (p == null || !mounted || generation != _accountGeneration) return;
    final requestedStore = _store;
    await _run(() async { await requestedStore.createProject(title: p[0], description: p[1], communityId: p[2]); });
  }

  Future<void> _addTask(String id) async {
    final generation = _accountGeneration;
    final requestedStore = _store;
    final p = await _ask('إضافة مهمة', const [
      _Field('اسم المهمة', maxLength: 160), _Field('المسؤول (اختياري)', maxLength: 128),
    ]);
    if (p == null || !mounted || generation != _accountGeneration) return;
    await _run(() => requestedStore.addProjectTask(projectId: id, title: p[0], assignee: p[1]));
  }

  Future<void> _editTaskAssignee(String projectId, String taskId) async {
    final generation = _accountGeneration;
    final requestedStore = _store;
    final result = await _ask('تعديل المسؤول عن المهمة', [
      _Field('معرّف المستخدم أو اسم المسؤول (اتركه فارغاً لإلغاء الإسناد)', maxLength: 128),
    ]);
    if (result == null || !mounted || generation != _accountGeneration) return;
    await _run(() => requestedStore.setProjectTaskAssignee(
      projectId: projectId,
      taskId: taskId,
      assignee: result[0],
    ));
  }

  Future<void> _addMilestone(String id) async {
    final generation = _accountGeneration;
    final requestedStore = _store;
    final p = await _ask('إضافة مرحلة', const [_Field('اسم المرحلة', maxLength: 160)]);
    if (p == null || !mounted || generation != _accountGeneration) return;
    await _run(() => requestedStore.addProjectMilestone(projectId: id, title: p[0]));
  }

  Future<void> _createProposal() async {
    final generation = _accountGeneration;
    final p = await _ask('اقتراح قاعدة للمجتمع', const [
      _Field('معرّف المجتمع', maxLength: 160),
      _Field('عنوان الاقتراح', maxLength: 120),
      _Field('نص القاعدة المقترحة', maxLength: 2000, maxLines: 4),
    ]);
    if (p == null || !mounted || generation != _accountGeneration) return;
    final requestedStore = _store;
    await _run(() async { await requestedStore.createRuleProposal(communityId: p[0], title: p[1], proposedRule: p[2]); });
  }

  Future<DateTime?> _pickMeetupStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'اختر تاريخ اللقاء المقترح',
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
      helpText: 'اختر وقت اللقاء المقترح',
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatMeetupStart(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(parsed)} • '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  Future<void> _createMeetup() async {
    final generation = _accountGeneration;
    final p = await _ask('مسودة لقاء مجتمعي', const [
      _Field('اسم اللقاء', maxLength: 120),
      _Field('الوصف', maxLength: 2000, maxLines: 3),
      _Field('المكان أو رابط مقترح (نص فقط)', maxLength: 160),
      _Field('السعة المقترحة (رقم)', maxLength: 5, keyboardType: TextInputType.number),
    ]);
    if (p == null || !mounted || generation != _accountGeneration) return;
    final startsAt = await _pickMeetupStart();
    if (startsAt == null || !mounted || generation != _accountGeneration) return;
    final capacity = int.tryParse(p[3].trim());
    if (capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل السعة المقترحة كرقم صحيح.')),
      );
      return;
    }
    final requestedStore = _store;
    await _run(() async {
      await requestedStore.createMeetupDraft(
        title: p[0],
        description: p[1],
        startsAt: startsAt.toUtc().toIso8601String(),
        location: p[2],
        capacity: capacity,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Community & Collaboration'),
      actions: [
        IconButton(
          key: const ValueKey('open-collaboration-spaces'),
          tooltip: 'مساحات التعاون',
          icon: const Icon(Icons.space_dashboard_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AurenCollaborationSpacesScreen()),
          ),
        ),
      ],
      bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [
        Tab(icon: Icon(Icons.groups_2_outlined), text: 'المشاريع'),
        Tab(icon: Icon(Icons.how_to_vote_outlined), text: 'الحوكمة'),
        Tab(icon: Icon(Icons.event_outlined), text: 'اللقاءات'),
        Tab(icon: Icon(Icons.rule_folder_outlined), text: 'إرشادات المساحات'),
      ])),
    body: Column(children: [
      Material(color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(padding: EdgeInsets.all(12), child: Row(children: [
          Icon(Icons.offline_bolt_outlined), SizedBox(width: 8),
          Expanded(child: Text('حفظ محلي أولاً. الاقتراحات والتصويت والحضور مسودات على هذا الجهاز؛ لا نشر أو حجز أو دفع تلقائي.')),
        ]))),
      Expanded(child: TabBarView(controller: _tabs, children: [_projectsTab(), _governanceTab(), _meetupsTab(), _spaceGuidelinesTab()])),
    ]),
    floatingActionButton: AnimatedBuilder(animation: _tabs, builder: (context, _) =>
      FloatingActionButton.extended(onPressed: _busy ? null : () {
        if (_tabs.index == 0) _createProject();
        if (_tabs.index == 1) _createProposal();
        if (_tabs.index == 2) _createMeetup();
        if (_tabs.index == 3) _saveSpaceGuidelines();
      }, icon: Icon(_tabs.index == 3 ? Icons.save_outlined : Icons.add), label: Text(_tabs.index == 0 ? 'مشروع' : _tabs.index == 1 ? 'اقتراح قاعدة' : _tabs.index == 2 ? 'لقاء' : 'حفظ الإرشادات'))),
  );

  Widget _spaceGuidelinesTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('موضوع وقواعد مساحة التعاون', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('هذه الإرشادات تُحفظ على هذا الجهاز فقط ولا تغيّر عضوية المساحة أو قواعد الخادم. استخدم معرّف مساحة موجودة لديك.'),
      const SizedBox(height: 16),
      TextField(
        controller: _spaceIdController,
        maxLength: 160,
        decoration: const InputDecoration(
          labelText: 'معرّف مساحة التعاون',
          helperText: 'معرّف السجل، وليس اسم المساحة',
          border: OutlineInputBorder(),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _loadSpaceGuidelines,
          icon: const Icon(Icons.download_outlined),
          label: const Text('تحميل الإرشادات المحلية'),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _spaceTopicController,
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'موضوع المساحة',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _spaceRulesController,
        maxLength: 2000,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'قواعد وإرشادات المجتمع',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy ? null : _saveSpaceGuidelines,
        icon: const Icon(Icons.save_outlined),
        label: const Text('حفظ على هذا الجهاز'),
      ),
    ],
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
          Row(children: [
            Expanded(child: Text('${project['title']}', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              tooltip: 'حذف المشروع من هذا الجهاز',
              onPressed: _busy ? null : () => _confirmLocalDelete(
                title: 'حذف المشروع المحلي؟',
                message: 'سيُحذف المشروع ومهامه ومراحله من هذا الجهاز فقط. لن يتغير أي سجل بعيد.',
                delete: () => _store.deleteProject('${project['id']}'),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ]),
          if ('${project['description']}'.isNotEmpty) Text('${project['description']}'),
          const SizedBox(height: 8), LinearProgressIndicator(value: progress / 100),
          Text('التقدم $progress% • ${tasks.length} مهام • ${milestones.length} مراحل'),
          Wrap(spacing: 8, children: [
            TextButton.icon(onPressed: _busy ? null : () => _addTask('${project['id']}'), icon: const Icon(Icons.add_task), label: const Text('مهمة')),
            TextButton.icon(onPressed: _busy ? null : () => _addMilestone('${project['id']}'), icon: const Icon(Icons.flag_outlined), label: const Text('مرحلة')),
          ]),
          for (final task in tasks) ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${task['title']}'),
            subtitle: Text('${task['assignee']}'.isEmpty ? 'غير مسندة' : 'المسؤول: ${task['assignee']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'تعديل المسؤول عن المهمة',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.person_outline),
                  onPressed: _busy ? null : () => _editTaskAssignee(
                    '${project['id']}', '${task['id']}'),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: const {'todo', 'doing', 'done'}.contains(task['status'])
                        ? task['status'] as String
                        : 'todo',
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'todo', child: Text('لم تبدأ')),
                      DropdownMenuItem(value: 'doing', child: Text('قيد التنفيذ')),
                      DropdownMenuItem(value: 'done', child: Text('مكتملة')),
                    ],
                    onChanged: _busy ? null : (status) {
                      if (status == null) return;
                      final requestedStore = _store;
                      _run(() => requestedStore.setProjectTaskStatus(
                        projectId: '${project['id']}', taskId: '${task['id']}', status: status));
                    },
                  ),
                ),
              ],
            ),
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
          Row(children: [
            Expanded(child: Text('${p['title']}', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              tooltip: 'حذف مسودة الاقتراح من هذا الجهاز',
              onPressed: _busy ? null : () => _confirmLocalDelete(
                title: 'حذف مسودة الاقتراح؟',
                message: 'سيُحذف الاقتراح وأصواته المحلية من هذا الجهاز فقط.',
                delete: () => _store.deleteProposal('${p['id']}'),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ]),
          Text('${p['proposedRule']}'),
          Text('المجتمع: ${p['communityId']} • مؤيد $yes • معارض $no • الحالة: ${_proposalStatusLabel(p['status'])}'),
          const Text('التصويت والأرقام محفوظة محلياً على هذا الجهاز وليست نتيجة رسمية للمجتمع.'),
          if (p['status'] == 'open') Wrap(children: [
            TextButton(onPressed: _busy || voted ? null : () => _run(() => _store.voteOnProposal(proposalId: '${p['id']}', voterId: _voterId, support: true)), child: const Text('أؤيد')),
            TextButton(onPressed: _busy || voted ? null : () => _run(() => _store.voteOnProposal(proposalId: '${p['id']}', voterId: _voterId, support: false)), child: const Text('أعارض')),
            TextButton(onPressed: _busy ? null : () => _confirmLocalDelete(
              title: 'إغلاق المسودة محلياً؟',
              message: 'سيُغلق هذا الاقتراح على جهازك فقط بناءً على الأصوات المحلية. لن تتغير قواعد المجتمع ولن يصدر قرار رسمي.',
              confirmLabel: 'إغلاق محلي',
              delete: () => _store.closeProposal(proposalId: '${p['id']}', status: yes > no ? 'accepted' : 'rejected'),
            ), child: const Text('إغلاق المسودة محلياً')),
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
          Row(children: [
            const Icon(Icons.event_note_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text('${m['title']}', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              tooltip: 'حذف مسودة اللقاء من هذا الجهاز',
              onPressed: _busy ? null : () => _confirmLocalDelete(
                title: 'حذف مسودة اللقاء؟',
                message: 'سيُحذف اللقاء وسجلات الاهتمام المحلية من هذا الجهاز فقط.',
                delete: () => _store.deleteMeetupDraft('${m['id']}'),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
            const Chip(label: Text('مسودة')),
          ]),
          if ('${m['description']}'.isNotEmpty) Text('${m['description']}'),
          Text('الموعد المقترح: ${_formatMeetupStart('${m['startsAt']}')}'), Text('المكان المقترح: ${m['location']}'),
          Text('السعة المقترحة محلياً: ${m['capacity']} • سجلات الاهتمام المحلية: ${attendance.length} • نوايا الحضور: ${_store.meetupGoingCount(m)}'),
          if (_store.meetupGoingCount(m) >= (m['capacity'] as int))
            const Text('وصلت مسودة اللقاء إلى السعة المقترحة؛ غيّر نية الحضور الحالية قبل إضافة نية حضور أخرى.'),
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
