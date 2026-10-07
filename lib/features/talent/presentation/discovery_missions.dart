import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../../services/talent/talent_repository.dart';

class AurenDiscoveryMissions extends StatefulWidget {
  const AurenDiscoveryMissions({super.key});
  @override
  State<AurenDiscoveryMissions> createState() => _AurenDiscoveryMissionsState();
}

class _AurenDiscoveryMissionsState extends State<AurenDiscoveryMissions> {
  final _missions = const <_Mission>[
    _Mission('ملاحظة الإبداع', 'اختر مشكلة يومية واكتب 5 حلول مختلفة خلال 10 دقائق.', 'إبداع'),
    _Mission('صانع القصة', 'حوّل موقفاً حقيقياً إلى قصة قصيرة من 150 كلمة.', 'كتابة'),
    _Mission('حل سريع', 'اختر مشكلة حقيقية وابنِ حلاً أولياً لها خلال 20 دقيقة.', 'حل المشكلات'),
    _Mission('عين المصمم', 'أعد تصميم شاشة أو منتج تعرفه واشرح 3 قرارات اتخذتها.', 'تصميم'),
    _Mission('قائد الفريق', 'ضع خطة من 5 خطوات لتنفيذ مشروع صغير مع توزيع الأدوار.', 'قيادة'),
    _Mission('تحليل الأداء', 'حلل أداءك في نشاط تعرفه واستخرج 3 نقاط قوة و3 فرص تحسين.', 'تحليل'),
    _Mission('صانع المحتوى', 'أنشئ فكرة محتوى واحدة بثلاث زوايا مختلفة لجمهورين مختلفين.', 'محتوى'),
    _Mission('المهارة الخفية', 'جرّب نشاطاً جديداً لمدة 15 دقيقة وسجل ما تعلمته وما جاءك بشكل طبيعي.', 'اكتشاف'),
  ];

  final _done = <int>{};
  final _notes = <int, String>{};
  final _evidence = <int, String>{};

  Future<void> _submit(int index) async {
    final controller = TextEditingController(text: _notes[index] ?? '');
    final evidenceController = TextEditingController(text: _evidence[index] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_missions[index].title),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'ماذا فعلت؟ وما النتيجة أو الدليل الذي خرجت به؟',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('حفظ المهمة')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) { evidenceController.dispose(); return; }
    evidenceController.dispose();
    setState(() {
      _done.add(index);
      _notes[index] = result;
      _evidence[index] = evidenceController.text.trim();
    });
    await _saveEvidence(index);
  }

  Future<void> _saveEvidence(int index) async {
    final uid = (await TalentRepository().currentUserId()).trim();
    if (uid.isEmpty) return;
    await TalentRepository().saveMissionEvidence(ownerId: uid, mission: _missions[index].title, category: _missions[index].category, result: _notes[index] ?? '', evidence: _evidence[index] ?? '');
  }

  void _review() {
    final completed = _done.map((i) => '${_missions[i].title}: ${_notes[i] ?? ''} | الدليل: ${_evidence[i] ?? ''}').join('\n');
    final prompt = completed.isEmpty
        ? 'أريد بدء Discovery Missions في AUREN Talent. اقترح لي أول 3 مهمات عملية قصيرة لاكتشاف مواهب محتملة عندي، ولكل مهمة طريقة واضحة لتسجيل النتيجة والدليل.'
        : 'راجع نتائج Discovery Missions التالية:\n${completed}\nاستخرج الأنماط التي قد تشير إلى مهارات أو مواهب، افصل الأدلة عن الاستنتاجات، ثم اقترح مهمة واحدة فقط كخطوة تالية.';
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }

  @override
  Widget build(BuildContext context) {
    final completed = _done.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.explore_outlined),
            const SizedBox(width: 8),
            const Expanded(child: Text('Discovery Missions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            Text('${completed}/${_missions.length}'),
          ]),
          const SizedBox(height: 6),
          const Text('اختبارات عملية قصيرة لاكتشاف الموهبة من الفعل والنتيجة، وليس من التقييم النظري فقط.'),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: completed / _missions.length),
          const SizedBox(height: 10),
          ...List.generate(_missions.length, (index) {
            final mission = _missions[index];
            final done = _done.contains(index);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(done ? Icons.check : Icons.flag_outlined)),
              title: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${mission.category} • ${mission.description}${done && (_evidence[index] ?? '').isNotEmpty ? '\nدليل: ${_evidence[index]}' : ''}'),
              trailing: IconButton(
                tooltip: done ? 'تعديل النتيجة' : 'ابدأ المهمة',
                icon: Icon(done ? Icons.edit_outlined : Icons.play_arrow),
                onPressed: () => _submit(index),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _review,
              icon: const Icon(Icons.auto_awesome),
              label: Text(completed == 0 ? 'ابدأ مع AUREN AI' : 'حلّل النتائج مع AUREN AI'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Mission {
  final String title;
  final String description;
  final String category;
  const _Mission(this.title, this.description, this.category);
}
