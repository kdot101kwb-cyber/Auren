import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/entertainment/entertainment_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

/// AUREN AI Series Studio
/// Series is an Entertainment content type, not a duplicate top-level system.
/// The screen creates a durable production brief/job and hands the orchestration
/// prompt to AUREN AI. Media generation providers can be attached later.
class AurenAiSeriesStudioScreen extends StatefulWidget {
  const AurenAiSeriesStudioScreen({super.key});

  @override
  State<AurenAiSeriesStudioScreen> createState() => _AurenAiSeriesStudioScreenState();
}

class _AurenAiSeriesStudioScreenState extends State<AurenAiSeriesStudioScreen> {
  final _idea = TextEditingController();
  final _repo = EntertainmentRepository();

  String _genre = 'دراما';
  String _tone = 'سينمائي';
  String _episodes = '8';
  String _episodeLength = '20 دقيقة';
  bool _saving = false;

  static const genres = ['دراما', 'كوميديا', 'أكشن', 'غموض', 'خيال علمي', 'أنمي', 'مغامرة', 'رومانسي'];
  static const tones = ['سينمائي', 'خفيف', 'غامض', 'ملهم', 'مظلم', 'عائلي'];
  static const episodeCounts = ['4', '6', '8', '10', '12'];
  static const lengths = ['5 دقائق', '10 دقائق', '20 دقيقة', '30 دقيقة', '45 دقيقة'];

  String get _prompt {
    final idea = _idea.text.trim().isEmpty
        ? 'قصة أصلية عن مجموعة شباب يكتشفون سراً يغير حياتهم.'
        : _idea.text.trim();

    return '''
أنت AUREN AI Series Studio، نظام إنتاج مسلسلات أصلي داخل AUREN.
حوّل الفكرة التالية إلى حزمة إنتاج لمسلسل كامل، مع الحفاظ على الأصالة وعدم نسخ أعمال موجودة.

الفكرة: $idea
النوع: $_genre
الطابع: $_tone
عدد الحلقات: $_episodes
مدة الحلقة: $_episodeLength

أخرج النتيجة بهذا الترتيب:
1) Series Concept: العنوان، Logline، الملخص، الجمهور، العالم والقواعد.
2) Characters: الشخصيات الرئيسية والثانوية، أهدافها، دوافعها، علاقاتها وأقواس تطورها.
3) Season Arc: بداية الموسم، التصعيد، نقطة التحول، الذروة والنهاية.
4) Episode Bible: لكل حلقة عنوان + ملخص + أحداث رئيسية + cliffhanger.
5) Episode 1 Script: مشاهد مرتبة، وصف بصري، حوار أصلي وملاحظات صوتية.
6) Visual Bible: أسلوب الشخصيات، المواقع، الإضاءة، الألوان والـshot language.
7) Audio Bible: أصوات أصلية، موسيقى ومؤثرات مطلوبة، بدون تقليد صوت فنان حقيقي.
8) Production Pipeline: script → character consistency → scene generation → voice → music/SFX → edit → QC.
9) Asset Manifest: كل صورة/صوت/فيديو/ملف مطلوب مع طريقة إنشائه أو ربط مزود خارجي.
10) Rights & Safety: فحص الأصالة، التشابه، حقوق الموسيقى والصوت والصور، ومراجعة قبل النشر.
11) MVP: نسخة منخفضة التكلفة تبدأ بحلقة تجريبية واحدة ثم تتوسع إلى الموسم.
12) JSON-friendly production metadata في نهاية الرد لتتمكن AUREN من حفظ المشروع واستكماله لاحقاً.

لا تدّعِ أن الفيديو أو الصوت تم إنشاؤهما إذا لم يتم تشغيل مزود إنتاج فعلي.
''';
  }

  Future<void> _start() async {
    if (_saving) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => _saving = true);

    try {
      if (uid != null) {
        final idea = _idea.text.trim().isEmpty
            ? 'قصة أصلية عن مجموعة شباب يكتشفون سراً يغير حياتهم.'
            : _idea.text.trim();
        final draftId = await _repo.saveEntertainmentDraft(
          uid,
          mode: 'مسلسل',
          mood: _tone,
          length: 'موسم $_episodes حلقات',
          idea: idea,
        );
        await _repo.createEntertainmentJob(
          uid,
          draftId: draftId,
          mode: 'مسلسل',
          mood: _tone,
          length: '$_episodes × $_episodeLength',
          idea: idea,
        );
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: _prompt)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر بدء مشروع المسلسل. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _chips(List<String> values, String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) => ChoiceChip(
        label: Text(v),
        selected: selected == v,
        onSelected: (_) => setState(() => onChanged(v)),
      )).toList(),
    );
  }

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN AI Series Studio'),
        actions: [
          IconButton(
            tooltip: 'ابدأ الإنتاج',
            onPressed: _saving ? null : _start,
            icon: const Icon(Icons.rocket_launch_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.live_tv_rounded, size: 36),
                SizedBox(height: 10),
                Text('فكرة → مسلسل كامل',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('ابنِ الموسم والشخصيات والحلقات والسيناريو وخطة الأصول من مكان واحد.'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('فكرة المسلسل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          TextField(
            controller: _idea,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'مثلاً: شاب سوداني يجد جهازاً قديماً يفتح له طريقاً إلى مدينة مستقبلية...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('النوع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          _chips(genres, _genre, (v) => _genre = v),
          const SizedBox(height: 20),
          const Text('الطابع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          _chips(tones, _tone, (v) => _tone = v),
          const SizedBox(height: 20),
          const Text('عدد الحلقات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          _chips(episodeCounts, _episodes, (v) => _episodes = v),
          const SizedBox(height: 20),
          const Text('مدة الحلقة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          _chips(lengths, _episodeLength, (v) => _episodeLength = v),
          const SizedBox(height: 22),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('خط الإنتاج',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  SizedBox(height: 12),
                  Text('📝 Concept & Bible → 👥 Characters → 🎬 Scenes → 🎙️ Voices → 🎵 Music/SFX → ✂️ Edit → 🔎 QC → 📺 Season'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _start,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('ابدأ بناء المسلسل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'الحفظ يتم كمشروع Entertainment من نوع مسلسل، وليس كنظام منفصل. توليد الفيديو/الصوت الفعلي يمر عبر مزودي الإنتاج بعد تجهيز الخطة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
