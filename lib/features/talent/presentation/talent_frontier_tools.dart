import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentFrontierTools extends StatelessWidget {
  const AurenTalentFrontierTools({super.key});

  static const _items = <({String title, String prompt})>[
    (
      title: 'Talent Blindspot',
      prompt: 'ابحث عن قدرات أو مواهب محتملة عندي لا أستخدمها بوضوح، واستخرج الأدلة التي تدعم كل احتمال، ثم اقترح تجربة صغيرة للتحقق منها. لا تخترع أدلة غير موجودة.'
    ),
    (
      title: 'Talent Collision',
      prompt: 'ابحث عن دمج غير تقليدي بين مهارتين أو أكثر عندي يمكن أن يصنع تخصصاً أو فرصة جديدة، واشرح لماذا الدمج منطقي وكيف أختبره.'
    ),
    (
      title: 'Talent Mutation',
      prompt: 'حلل كيف يمكن أن تنتقل موهبتي من مجالها الحالي إلى مجال آخر قريب أو بعيد، وما المهارات القابلة للنقل وما التجربة التي تثبت الانتقال.'
    ),
    (
      title: 'Discovery Missions',
      prompt: 'صمم لي مهمات قصيرة وعملية لاختبار مواهب محتملة عندي بدلاً من الاكتفاء بالتقييم النظري، مع نتيجة يمكنني تسجيلها بعد كل مهمة.'
    ),
    (
      title: 'Cross-Domain Transfer',
      prompt: 'حدد مهارات عندي يمكن نقلها إلى مجال مختلف تماماً، واقترح تطبيقاً واقعياً لكل انتقال وماذا أحتاج لتعلمه.'
    ),
    (
      title: 'Talent Emergence Radar',
      prompt: 'ابحث في ملفي وسجل تطوري عن إشارات موهبة ناشئة: تحسن متكرر، اهتمام مستمر، نتائج غير متوقعة، أو نمط تعلم سريع. افصل الإشارة عن التخمين.'
    ),
    (
      title: 'Opportunity Counterfactual',
      prompt: 'قارن مسارات بديلة لموهبتي: ماذا قد يحدث لو ركزت على المسار A بدلاً من B؟ اعرض الفوائد والمخاطر والمهارات والفرص والتجربة الأقل تكلفة لاختبار كل مسار.'
    ),
    (
      title: 'Talent Network Effects',
      prompt: 'حدد أنواع الأشخاص أو الفرق التي قد تجعل موهبتي أقوى عند التعاون معها، ولماذا، وما نوع المشروع أو التجربة التي تكشف قيمة هذا التعاون.'
    ),
    (
      title: 'Talent Proof Chain',
      prompt: 'ابنِ سلسلة إثبات لمهاراتي من الأدلة المتاحة: عمل، نتيجة، شهادة، فيديو، مشروع أو تجربة. بيّن ما هو مثبت وما يحتاج دليلاً إضافياً.'
    ),
    (
      title: 'Talent-to-Reality',
      prompt: 'حوّل اكتشاف موهبتي إلى دورة عملية: اكتشاف، اختبار، تطوير، إثبات، عرض، فرصة، ثم نتيجة قابلة للقياس. اختر الخطوة التالية فقط كبداية.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUREN Talent Frontier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'طبقة لاكتشاف الإمكانات غير الواضحة وتحويل الموهبة إلى تجارب وأدلة وفرص، بدون تكرار أدوات Talent الأساسية.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in _items)
                  ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(item.title),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessengerScreen(initialPrompt: item.prompt),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
