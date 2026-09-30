import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/education/education_gamification_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class EducationActivityScreen extends StatefulWidget {
  const EducationActivityScreen({super.key, required this.mode});
  final String mode;
  @override
  State<EducationActivityScreen> createState() => _EducationActivityScreenState();
}

class _EducationActivityScreenState extends State<EducationActivityScreen> {
  final _gamification = EducationGamificationService();
  int _quizIndex = 0;
  int _quizScore = 0;
  bool _busy = false;
  bool _completed = false;

  static const _questions = [
    ('Which action best supports active learning?', ['Practice and feedback', 'Only reading', 'Skipping exercises'], 0),
    ('What should a good learning goal include?', ['A clear outcome', 'No deadline or outcome', 'Only a long title'], 0),
    ('Why review mistakes?', ['To improve future performance', 'To hide progress', 'To avoid practice'], 0),
  ];

  String get _title {
    switch (widget.mode) {
      case 'quiz': return 'Learning Quiz';
      case 'language': return 'Language Practice';
      default: return 'Voice Tutor';
    }
  }

  Future<void> _finish(String activityId, {String? sourceId}) async {
    if (_busy || _completed) return;
    setState(() => _busy = true);
    try {
      final result = widget.mode == 'quiz'
          ? await _gamification.recordQuiz(quizId: activityId, courseId: sourceId)
          : widget.mode == 'language'
              ? await _gamification.recordLanguage(activityId: activityId, language: sourceId)
              : await _gamification.recordVoiceTutor(sessionId: activityId, lessonId: sourceId);
      if (!mounted) return;
      setState(() => _completed = true);
      final xp = result['xpAwarded'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(xp == 0 ? 'تم تسجيل النشاط بدون XP إضافي بسبب الحد اليومي.' : '+$xp XP')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: widget.mode == 'quiz' ? _quizBody() : widget.mode == 'language' ? _languageBody() : _voiceTutorBody(),
    );
  }

  Widget _quizBody() {
    if (_completed) return _doneCard('Quiz completed', 'نتيجتك: \${_quizScore}/\${_questions.length}');
    final q = _questions[_quizIndex];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Question \${_quizIndex + 1}/\${_questions.length}', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Text(q.\$1, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        ...List.generate(q.\$2.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton.tonal(
            onPressed: _busy ? null : () => _answerQuiz(i == q.\$3),
            child: Align(alignment: Alignment.centerLeft, child: Text(q.\$2[i])),
          ),
        )),
      ]),
    );
  }

  void _answerQuiz(bool correct) {
    if (correct) _quizScore++;
    if (_quizIndex + 1 < _questions.length) {
      setState(() => _quizIndex++);
    } else {
      _finish('quiz:education:\${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  Widget _languageBody() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Practice one short language activity.'),
      const SizedBox(height: 16),
      const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Translate: “Together, we build.” into a language you are learning.'),
      )),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy || _completed ? null : () => _finish('language:practice:\${DateTime.now().millisecondsSinceEpoch}', sourceId: 'general'),
        icon: const Icon(Icons.check),
        label: const Text('Complete practice'),
      ),
    ]),
  );

  Widget _voiceTutorBody() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('استخدم المدرّس الذكي للتحدث والتعلّم، ثم سجّل جلسة مكتملة للحصول على XP.'),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const MessengerScreen(initialPrompt: 'ابدأ معي جلسة Voice Tutor تعليمية قصيرة، اسألني 3 أسئلة وتابع أخطائي.'),
        )),
        icon: const Icon(Icons.record_voice_over),
        label: const Text('Start Voice Tutor'),
      ),
      const SizedBox(height: 12),
      FilledButton.tonal(
        onPressed: _busy || _completed ? null : () => _finish('voiceTutor:session:\${DateTime.now().millisecondsSinceEpoch}'),
        child: const Text('Mark session complete'),
      ),
    ]),
  );

  Widget _doneCard(String title, String subtitle) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Card(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events, size: 56),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle),
        ]),
      )),
    ),
  );
}
