import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentGeneralAiTools extends StatelessWidget {
  const AurenTalentGeneralAiTools({super.key});

  static const titles = <String>[
    'Talent Passport',
    'Skill Graph',
    'Portfolio Builder',
    'Showcase Story',
    'Talent Brand',
    'Growth Plan',
    'Gap Radar',
    'Evidence Plan',
    'Opportunity Match',
    'Collaboration Match',
    'Talent Snapshot',
    'AI Talent Dossier',
  ];

  static const prompts = <String>[
    'أنشئ لي Talent Passport يختصر هويتي كموهبة، مجالي، مهاراتي، إنجازاتي، أهدافي، وأفضل أعمالي أو أدلتي.',
    'حلّل موهبتي وابنِ خريطة مهارات توضح نقاط قوتي، المهارات المرتبطة، الفجوات، وأهم مهارة أقترح تطويرها تالياً.',
    'حوّل مهاراتي ومشاريعي وإنجازاتي وأدلتي إلى Portfolio مرتب ومقنع لموهبتي.',
    'حوّل رحلتي وموهبتي وإنجازاتي إلى قصة عرض قصيرة وجذابة تناسب مجالي وجمهوري.',
    'ابنِ هويتي كموهبة: نبذة، نقاط تميز، رسالة شخصية، وطريقة مناسبة لعرض موهبتي بدون مبالغة.',
    'ابنِ لي خطة تطوير لموهبتي حسب مستواي الحالي وأهدافي ووقتي، مع مراحل ومؤشرات متابعة واضحة.',
    'اكتشف الفجوات في مهاراتي وملفي وأدلتي مقارنة بالهدف الذي أريده، ورتبها حسب الأولوية.',
    'حدد أفضل أنواع الأدلة التي أستطيع إضافتها لإثبات مهاراتي وإنجازاتي، مثل المشاريع والنتائج والشهادات والروابط والعينات.',
    'قارن ملف موهبتي مع الفرصة التي أحددها، واشرح نقاط التوافق والفجوات وما الذي أحتاج لتحسينه قبل التقديم.',
    'حدد أنواع المواهب التي تكمل مهاراتي ويمكنني التعاون معها لإنشاء مشروع أو محتوى أو عمل إبداعي.',
    'أنشئ لقطة مختصرة لحالتي الحالية: المجال، المهارات، الإنجازات، الأدلة، الأهداف، والخطوة التالية.',
    'أنشئ ملفاً تحليلياً شاملاً لموهبتي يجمع الهوية والمهارات والإنجازات والأهداف والأدلة والفجوات وخطة التطوير.',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI لكل المواهب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('أدوات عامة للموسيقى والفن والتصميم والبرمجة والكتابة والـCreator والألعاب والرياضة وغيرها.'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                titles.length,
                (i) => ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(titles[i]),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessengerScreen(initialPrompt: prompts[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
