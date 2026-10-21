import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/health/auren_wellbeing_local_store.dart';

/// Offline-first personal wellbeing workspace. No health content is sent to AI,
/// Firestore, analytics, or other remote services from this screen.
class AurenHealthWellbeingScreen extends StatefulWidget {
  const AurenHealthWellbeingScreen({
    super.key,
    this.store,
    this.userId,
  });

  final AurenWellbeingLocalStore? store;
  final String? userId;

  @override
  State<AurenHealthWellbeingScreen> createState() =>
      _AurenHealthWellbeingScreenState();
}

class _AurenHealthWellbeingScreenState extends State<AurenHealthWellbeingScreen> {
  late final AurenWellbeingLocalStore _store =
      widget.store ?? AurenWellbeingLocalStore();
  AurenWellbeingData _data = const AurenWellbeingData();
  bool _loading = true;
  String? _error;

  String? get _uid => widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null || uid.trim().isEmpty) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'يلزم تسجيل الدخول محلياً لفتح مساحة العافية الخاصة بك.';
      });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _store.load(uid);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'تعذّر قراءة بيانات العافية المحفوظة. لم يتم استبدالها.';
      });
    }
  }

  Future<void> _save(AurenWellbeingData next) async {
    final uid = _uid;
    if (uid == null || uid.trim().isEmpty) return;
    final issue = next.validate();
    if (issue != null) {
      _message(issue);
      return;
    }
    try {
      await _store.save(uid, next);
      if (mounted) setState(() { _data = next; _error = null; });
    } catch (_) {
      _message('تعذّر الحفظ محلياً. بياناتك السابقة لم تُستبدل بنجاح.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  Future<String?> _textDialog({
    required String title,
    required String label,
    String initial = '',
    int maxLines = 1,
  }) async {
    var value = initial;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          autofocus: true,
          initialValue: initial,
          maxLines: maxLines,
          maxLength: maxLines > 1 ? 2000 : 120,
          decoration: InputDecoration(labelText: label),
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, value),
            child: const Text('حفظ محلي'),
          ),
        ],
      ),
    );
  }

  Future<int?> _numberDialog({
    required String title,
    required String label,
    required int initial,
    required int min,
    required int max,
  }) async {
    var value = initial.toString();
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          autofocus: true,
          initialValue: initial.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, helperText: '$min–$max'),
          onChanged: (next) => value = next,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed < min || parsed > max) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('حفظ محلي'),
          ),
        ],
      ),
    );
  }

  Future<void> _addJournal() async {
    final mood = await _numberDialog(
      title: 'سجل الشعور اليومي',
      label: 'المزاج من 1 إلى 5',
      initial: 3, min: 1, max: 5,
    );
    if (mood == null || !mounted) return;
    final note = await _textDialog(
      title: 'ملاحظة اختيارية',
      label: 'كيف كان يومك؟',
      maxLines: 4,
    );
    if (note == null || !mounted) return;
    await _save(AurenWellbeingData(
      journal: [..._data.journal, AurenWellnessEntry(
        id: _id(), day: _today(), mood: mood, note: note.trim(),
      )].take(365).toList(),
      fitnessGoals: _data.fitnessGoals, sleepEntries: _data.sleepEntries,
      habits: _data.habits, careNotes: _data.careNotes,
    ));
  }

  Future<void> _addFitnessGoal() async {
    final title = await _textDialog(title: 'هدف حركة تدريجي', label: 'مثلاً: المشي');
    if (title == null || title.trim().isEmpty || !mounted) return;
    final target = await _numberDialog(
      title: 'الهدف الأسبوعي', label: 'دقائق في الأسبوع',
      initial: 90, min: 1, max: 10080,
    );
    if (target == null || !mounted) return;
    await _save(AurenWellbeingData(
      journal: _data.journal,
      fitnessGoals: [..._data.fitnessGoals, AurenFitnessGoal(
        id: _id(), title: title.trim(), weeklyTargetMinutes: target,
      )].take(100).toList(),
      sleepEntries: _data.sleepEntries, habits: _data.habits,
      careNotes: _data.careNotes,
    ));
  }

  Future<void> _addMovement(AurenFitnessGoal goal) async {
    final minutes = await _numberDialog(
      title: 'تسجيل حركة', label: 'دقائق النشاط',
      initial: 10, min: 1, max: 1440,
    );
    if (minutes == null || !mounted) return;
    final updated = _data.fitnessGoals.map((g) => g.id == goal.id
      ? AurenFitnessGoal(
          id: g.id, title: g.title, weeklyTargetMinutes: g.weeklyTargetMinutes,
          completedMinutes: (g.completedMinutes + minutes).clamp(0, 10080).toInt(),
          active: g.active,
        ) : g).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: updated,
      sleepEntries: _data.sleepEntries, habits: _data.habits,
      careNotes: _data.careNotes,
    ));
  }

  Future<void> _addSleep() async {
    final duration = await _numberDialog(
      title: 'تسجيل النوم', label: 'مدة النوم بالدقائق',
      initial: 480, min: 0, max: 1440,
    );
    if (duration == null || !mounted) return;
    final quality = await _numberDialog(
      title: 'جودة النوم', label: 'من 1 إلى 5',
      initial: 3, min: 1, max: 5,
    );
    if (quality == null || !mounted) return;
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: [..._data.sleepEntries, AurenSleepEntry(
        id: _id(), day: _today(), durationMinutes: duration, quality: quality,
      )].take(365).toList(),
      habits: _data.habits, careNotes: _data.careNotes,
    ));
  }

  Future<void> _addHabit() async {
    final title = await _textDialog(title: 'عادة صحية صغيرة', label: 'مثلاً: تمدد 5 دقائق');
    if (title == null || title.trim().isEmpty || !mounted) return;
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries,
      habits: [..._data.habits, AurenHealthyHabit(id: _id(), title: title.trim())].take(100).toList(),
      careNotes: _data.careNotes,
    ));
  }

  Future<void> _toggleHabit(AurenHealthyHabit habit) async {
    final today = _today();
    final days = [...habit.completedDays];
    if (days.contains(today)) { days.remove(today); } else { days.add(today); }
    final updated = _data.habits.map((h) => h.id == habit.id
      ? AurenHealthyHabit(
          id: h.id, title: h.title, active: h.active,
          reminderEnabled: h.reminderEnabled, reminderTime: h.reminderTime,
          completedDays: days,
        ) : h).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries, habits: updated,
      careNotes: _data.careNotes,
    ));
  }

  Future<void> _toggleReminder(AurenHealthyHabit habit) async {
    final enabled = !habit.reminderEnabled;
    String? time = habit.reminderTime;
    if (enabled) {
      time = await _textDialog(
        title: 'وقت التذكير المحلي',
        label: 'اكتب الوقت بصيغة HH:mm',
        initial: time ?? '08:00',
      );
      if (time == null || !mounted) return;
      if (!RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]).hasMatch(time.trim())) {
        _message('اكتب الوقت بصيغة 24 ساعة مثل 08:00.');
        return;
      }
      time = time.trim();
    }
    final updated = _data.habits.map((h) => h.id == habit.id
      ? AurenHealthyHabit(
          id: h.id, title: h.title, active: h.active,
          reminderEnabled: enabled, reminderTime: time,
          completedDays: h.completedDays,
        ) : h).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries, habits: updated,
      careNotes: _data.careNotes,
    ));
    if (enabled) _message('حُفظ تفضيل التذكير محلياً؛ جدولة إشعارات النظام ليست مفعّلة بعد.');
  }

  Future<void> _addCareNote() async {
    final appointmentDay = await _textDialog(
      title: 'تاريخ موعد الرعاية',
      label: 'التاريخ بصيغة YYYY-MM-DD',
      initial: _today(),
    );
    if (appointmentDay == null || !mounted) return;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(appointmentDay.trim())) {
      _message('اكتب التاريخ بصيغة YYYY-MM-DD.');
      return;
    }
    final provider = await _textDialog(
      title: 'تنظيم موعد الرعاية', label: 'اسم عام أو وصف مقدم الرعاية (اختياري)',
    );
    if (provider == null || !mounted) return;
    final questions = await _textDialog(
      title: 'أسئلة للموعد', label: 'اكتب الأسئلة وافصل بينها بسطر',
      maxLines: 5,
    );
    if (questions == null || !mounted) return;
    final notes = await _textDialog(
      title: 'ملاحظات شخصية', label: 'ملاحظات ترغب بمناقشتها',
      maxLines: 5,
    );
    if (notes == null || !mounted) return;
    final questionList = questions.split('\n').map((q) => q.trim()).where((q) => q.isNotEmpty).take(20).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries, habits: _data.habits,
      careNotes: [..._data.careNotes, AurenCareNote(
        id: _id(), day: appointmentDay.trim(), providerLabel: provider.trim(),
        questions: questionList, notes: notes.trim(),
      )].take(100).toList(),
    ));
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ])),
          IconButton(tooltip: 'إضافة', onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
        ]),
        if (children.isNotEmpty) const Divider(),
        ...children,
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AUREN Health & Wellbeing')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ]),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Health & Wellbeing')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('مساحة خاصة للعافية اليومية. البيانات تحفظ محلياً في التخزين الآمن ولا تُرسل إلى خدمات خارجية من هذه الشاشة. لا تقدم تشخيصاً أو تعدّل علاجاً أو جرعات.'),
        )),
        _section(
          title: 'Wellness Journal', subtitle: 'المزاج والعادات وملاحظات اليوم',
          icon: Icons.book_outlined, onAdd: _addJournal,
          children: _data.journal.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day} • المزاج ${e.mood}/5'),
            subtitle: e.note.isEmpty ? null : Text(e.note, maxLines: 2, overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
        _section(
          title: 'Fitness & Movement', subtitle: 'أهداف حركة تدريجية وتسجيل النشاط',
          icon: Icons.directions_walk, onAdd: _addFitnessGoal,
          children: _data.fitnessGoals.where((g) => g.active).map((g) => ListTile(
            dense: true, title: Text(g.title),
            subtitle: Text('${g.completedMinutes} / ${g.weeklyTargetMinutes} دقيقة'),
            trailing: IconButton(tooltip: 'تسجيل حركة', icon: const Icon(Icons.add_task), onPressed: () => _addMovement(g)),
          )).toList(),
        ),
        _section(
          title: 'Sleep Routine', subtitle: 'مدة النوم وجودته — دون استنتاج طبي',
          icon: Icons.bedtime_outlined, onAdd: _addSleep,
          children: _data.sleepEntries.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day} • ${(e.durationMinutes / 60).toStringAsFixed(1)} ساعة'),
            subtitle: Text('جودة النوم: ${e.quality}/5'),
          )).toList(),
        ),
        _section(
          title: 'Healthy Habits Coach', subtitle: 'عادات بسيطة وتفضيلات تذكير قابلة للتحكم',
          icon: Icons.check_circle_outline, onAdd: _addHabit,
          children: _data.habits.where((h) => h.active).map((h) => ListTile(
            dense: true,
            leading: Checkbox(value: h.completedDays.contains(_today()), onChanged: (_) => _toggleHabit(h)),
            title: Text(h.title),
            subtitle: Text(h.reminderEnabled ? 'تفضيل تذكير: ${h.reminderTime} (محلي)' : 'التذكير متوقف'),
            trailing: IconButton(tooltip: h.reminderEnabled ? 'إيقاف التذكير' : 'ضبط التذكير', icon: Icon(h.reminderEnabled ? Icons.notifications_active_outlined : Icons.notifications_none), onPressed: () => _toggleReminder(h)),
          )).toList(),
        ),
        _section(
          title: 'Care Coordination', subtitle: 'أسئلة وملاحظات لمناقشتها مع مقدم الرعاية',
          icon: Icons.event_note_outlined, onAdd: _addCareNote,
          children: _data.careNotes.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day}${e.providerLabel.isEmpty ? '' : ' • ${e.providerLabel}'}'),
            subtitle: Text([
              if (e.questions.isNotEmpty) 'الأسئلة: ${e.questions.join('، ')}',
              if (e.notes.isNotEmpty) e.notes,
            ].join('\n'), maxLines: 3, overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('ملاحظة: تفضيلات التذكير تُحفظ فقط؛ إشعارات النظام غير مجدولة في هذه النسخة. احذف بيانات التطبيق أو امسح سجلات العافية من الإعدادات المناسبة إذا أردت إزالة البيانات المحلية.'),
        ),
      ]),
    );
  }
}
).hasMatch(time.trim())) {
        _message('اكتب الوقت بصيغة 24 ساعة مثل 08:00.');
        return;
      }
      time = time.trim();
    }
    final updated = _data.habits.map((h) => h.id == habit.id
      ? AurenHealthyHabit(
          id: h.id, title: h.title, active: h.active,
          reminderEnabled: enabled, reminderTime: time,
          completedDays: h.completedDays,
        ) : h).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries, habits: updated,
      careNotes: _data.careNotes,
    ));
    if (enabled) _message('حُفظ تفضيل التذكير محلياً؛ جدولة إشعارات النظام ليست مفعّلة بعد.');
  }

  Future<void> _addCareNote() async {
    final provider = await _textDialog(
      title: 'تنظيم موعد الرعاية', label: 'اسم عام أو وصف مقدم الرعاية (اختياري)',
    );
    if (provider == null || !mounted) return;
    final questions = await _textDialog(
      title: 'أسئلة للموعد', label: 'اكتب الأسئلة وافصل بينها بسطر',
      maxLines: 5,
    );
    if (questions == null || !mounted) return;
    final notes = await _textDialog(
      title: 'ملاحظات شخصية', label: 'ملاحظات ترغب بمناقشتها',
      maxLines: 5,
    );
    if (notes == null || !mounted) return;
    final questionList = questions.split('\n').map((q) => q.trim()).where((q) => q.isNotEmpty).take(20).toList();
    await _save(AurenWellbeingData(
      journal: _data.journal, fitnessGoals: _data.fitnessGoals,
      sleepEntries: _data.sleepEntries, habits: _data.habits,
      careNotes: [..._data.careNotes, AurenCareNote(
        id: _id(), day: _today(), providerLabel: provider.trim(),
        questions: questionList, notes: notes.trim(),
      )].take(100).toList(),
    ));
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ])),
          IconButton(tooltip: 'إضافة', onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
        ]),
        if (children.isNotEmpty) const Divider(),
        ...children,
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AUREN Health & Wellbeing')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ]),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Health & Wellbeing')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('مساحة خاصة للعافية اليومية. البيانات تحفظ محلياً في التخزين الآمن ولا تُرسل إلى خدمات خارجية من هذه الشاشة. لا تقدم تشخيصاً أو تعدّل علاجاً أو جرعات.'),
        )),
        _section(
          title: 'Wellness Journal', subtitle: 'المزاج والعادات وملاحظات اليوم',
          icon: Icons.book_outlined, onAdd: _addJournal,
          children: _data.journal.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day} • المزاج ${e.mood}/5'),
            subtitle: e.note.isEmpty ? null : Text(e.note, maxLines: 2, overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
        _section(
          title: 'Fitness & Movement', subtitle: 'أهداف حركة تدريجية وتسجيل النشاط',
          icon: Icons.directions_walk, onAdd: _addFitnessGoal,
          children: _data.fitnessGoals.where((g) => g.active).map((g) => ListTile(
            dense: true, title: Text(g.title),
            subtitle: Text('${g.completedMinutes} / ${g.weeklyTargetMinutes} دقيقة'),
            trailing: IconButton(tooltip: 'تسجيل حركة', icon: const Icon(Icons.add_task), onPressed: () => _addMovement(g)),
          )).toList(),
        ),
        _section(
          title: 'Sleep Routine', subtitle: 'مدة النوم وجودته — دون استنتاج طبي',
          icon: Icons.bedtime_outlined, onAdd: _addSleep,
          children: _data.sleepEntries.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day} • ${(e.durationMinutes / 60).toStringAsFixed(1)} ساعة'),
            subtitle: Text('جودة النوم: ${e.quality}/5'),
          )).toList(),
        ),
        _section(
          title: 'Healthy Habits Coach', subtitle: 'عادات بسيطة وتفضيلات تذكير قابلة للتحكم',
          icon: Icons.check_circle_outline, onAdd: _addHabit,
          children: _data.habits.where((h) => h.active).map((h) => ListTile(
            dense: true,
            leading: Checkbox(value: h.completedDays.contains(_today()), onChanged: (_) => _toggleHabit(h)),
            title: Text(h.title),
            subtitle: Text(h.reminderEnabled ? 'تفضيل تذكير: ${h.reminderTime} (محلي)' : 'التذكير متوقف'),
            trailing: IconButton(tooltip: h.reminderEnabled ? 'إيقاف التذكير' : 'ضبط التذكير', icon: Icon(h.reminderEnabled ? Icons.notifications_active_outlined : Icons.notifications_none), onPressed: () => _toggleReminder(h)),
          )).toList(),
        ),
        _section(
          title: 'Care Coordination', subtitle: 'أسئلة وملاحظات لمناقشتها مع مقدم الرعاية',
          icon: Icons.event_note_outlined, onAdd: _addCareNote,
          children: _data.careNotes.reversed.take(5).map((e) => ListTile(
            dense: true, title: Text('${e.day}${e.providerLabel.isEmpty ? '' : ' • ${e.providerLabel}'}'),
            subtitle: Text([
              if (e.questions.isNotEmpty) 'الأسئلة: ${e.questions.join('، ')}',
              if (e.notes.isNotEmpty) e.notes,
            ].join('\n'), maxLines: 3, overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('ملاحظة: تفضيلات التذكير تُحفظ فقط؛ إشعارات النظام غير مجدولة في هذه النسخة. احذف بيانات التطبيق أو امسح سجلات العافية من الإعدادات المناسبة إذا أردت إزالة البيانات المحلية.'),
        ),
      ]),
    );
  }
}
