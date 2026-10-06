import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_coach_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentCoachScreen extends StatefulWidget {
  final String talentId;
  final String sport;
  final String level;
  final List<String> sports;
  const AurenTalentCoachScreen({super.key, required this.talentId, this.sport = '', this.level = '', this.sports = const []});
  @override State<AurenTalentCoachScreen> createState() => _AurenTalentCoachScreenState();
}

class _AurenTalentCoachScreenState extends State<AurenTalentCoachScreen> {
  final repo = TalentCoachRepository();
  final goal = TextEditingController();
  String mode = 'ai';
  int sessions = 3;
  bool saving = false;
  bool loading = true;

  String get primarySport => widget.sport.isNotEmpty ? widget.sport : (widget.sports.isNotEmpty ? widget.sports.first : 'رياضتي');

  @override void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      repo.watch(uid).first.then((data) {
        if (!mounted || data == null) return;
        setState(() {
          mode = data['coachMode']?.toString() == 'human' ? 'human' : 'ai';
          if ((data['goal']?.toString() ?? '').isNotEmpty) goal.text = data['goal'].toString();
          final saved = (data['weeklySessions'] as num?)?.toInt();
          if (saved != null && saved >= 1 && saved <= 7) sessions = saved;
          loading = false;
        });
      }).catchError((_) { if (mounted) setState(() => loading = false); });
    } else {
      loading = false;
    }
  }

  @override void dispose() { goal.dispose(); super.dispose(); }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      await repo.savePreferences(uid: uid, coachMode: mode, sport: primarySport, level: widget.level, goal: goal.text.trim(), weeklySessions: sessions);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات المدرب الشخصي.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _openCoach() {
    final prompt = mode == 'ai'
        ? 'أنت مدربي الشخصي في AUREN. الرياضة: ' + primarySport + '. المستوى: ' + (widget.level.isEmpty ? 'غير محدد' : widget.level) + '. الهدف: ' + (goal.text.trim().isEmpty ? 'تحسين مستواي' : goal.text.trim()) + '. ضع خطة أسبوعية عملية لعدد ' + sessions.toString() + ' حصص، مع أهداف كل حصة ومؤشرات متابعة.'
        : 'ساعدني في اختيار مدرب بشري مناسب لرياضتي ' + primarySport + '. مستواي ' + (widget.level.isEmpty ? 'غير محدد' : widget.level) + '، وهدفي ' + (goal.text.trim().isEmpty ? 'تطوير مستواي' : goal.text.trim()) + '. اقترح تخصص المدرب وأسئلة التحقق قبل الاتفاق.';
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مدربي الشخصي')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('مدربك مع AUREN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text('رياضتك: ' + primarySport),
        if (widget.level.isNotEmpty) Text('المستوى: ' + widget.level),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'ai', label: Text('AI Coach'), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: 'human', label: Text('مدرب بشري'), icon: Icon(Icons.person)),
          ],
          selected: {mode},
          onSelectionChanged: (v) => setState(() => mode = v.first),
        ),
        const SizedBox(height: 16),
        TextField(controller: goal, maxLines: 3, decoration: const InputDecoration(labelText: 'هدفك', hintText: 'تحسين مهارة، الاستعداد لمنافسة، تطوير مستوى...', border: OutlineInputBorder())),
        const SizedBox(height: 14), Text('الحصص الأسبوعية: ' + sessions.toString()),
        Slider(value: sessions.toDouble(), min: 1, max: 7, divisions: 6, label: sessions.toString(), onChanged: (v) => setState(() => sessions = v.round())),
        FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ إعدادات المدرب')),
      ]))),
      const SizedBox(height: 12),
      Card(child: ListTile(
        leading: Icon(mode == 'ai' ? Icons.auto_awesome : Icons.person_search),
        title: Text(mode == 'ai' ? 'ابدأ مع AI Coach' : 'اختيار مدرب بشري'),
        subtitle: Text(mode == 'ai' ? 'خطة ومراجعة أسبوعية حسب ملفك.' : 'جهّز متطلبات اختيار المدرب قبل الاتفاق.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openCoach,
      )),
    ]),
  );
}
