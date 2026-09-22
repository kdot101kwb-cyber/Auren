import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenLegalAiScreen extends StatelessWidget {
  const AurenLegalAiScreen({super.key});

  static const actions = [
    ('Explain','اشرح لي هذا النص القانوني بلغة بسيطة وحدد النقاط المهمة.'),
    ('Checklist','أنشئ لي قائمة تحقق قبل توقيع هذا العقد أو الاتفاق.'),
    ('Risk Scan','راجع البنود التي أرسلها وحدد الأسئلة التي يجب أن أطرحها على محامٍ.'),
    ('Document Draft','ساعدني في إعداد مسودة أولية غير ملزمة للمراجعة القانونية.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Legal AI')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Legal Intelligence', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('مساعدة لفهم المستندات وصياغة المسودات مع إبقاء القرار والمراجعة القانونية عند المختص.'),
        const SizedBox(height: 18),
        ...actions.map((a) => Card(
          child: ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(a.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(a.$2),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: a.$2)),
            ),
          ),
        )),
      ],
    ),
  );
}
