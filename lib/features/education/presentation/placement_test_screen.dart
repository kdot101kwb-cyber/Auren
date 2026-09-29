import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/education/placement_service.dart';

class PlacementTestScreen extends StatefulWidget {
  final String subject;
  const PlacementTestScreen({super.key, this.subject = 'General'});
  @override State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  final service = PlacementService();
  late final List<int?> answers = List<int?>.filled(PlacementService.questions.length, null);
  int index = 0;

  Future<void> _finish() async {
    final result = service.evaluate(answers);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await service.saveResult(uid: uid, subject: widget.subject, result: result);
    if (!mounted) return;
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('نتيجة تحديد المستوى'),
      content: Text('مستواك المقترح: ${result.level}\nالنتيجة: ${result.score}/${result.total}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
    ));
    if (mounted) Navigator.pop(context, result.level);
  }

  @override Widget build(BuildContext context) {
    final q = PlacementService.questions[index];
    final answered = answers[index] != null;
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار تحديد المستوى')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        LinearProgressIndicator(value: (index + 1) / PlacementService.questions.length),
        const SizedBox(height: 24),
        Text('السؤال ${index + 1} من ${PlacementService.questions.length}', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Text(q.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(q.options.length, (i) => Card(
          child: RadioListTile<int>(value: i, groupValue: answers[index], title: Text(q.options[i]), onChanged: (v) => setState(() => answers[index] = v)),
        )),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: !answered ? null : () {
            if (index == PlacementService.questions.length - 1) { _finish(); } else { setState(() => index++); }
          },
          icon: Icon(index == PlacementService.questions.length - 1 ? Icons.check : Icons.arrow_forward),
          label: Text(index == PlacementService.questions.length - 1 ? 'إنهاء الاختبار' : 'التالي'),
        ),
      ]),
    );
  }
}
