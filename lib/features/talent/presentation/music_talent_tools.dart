import 'package:flutter/material.dart';
import '../../../services/talent/music_talent_catalog.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenMusicTalentTools extends StatelessWidget {
  const AurenMusicTalentTools({super.key});

  static const prompts = <String>[
    'أنشئ لي Music Talent Profile كمغني أو عازف أو مؤلف أو منتج موسيقي، مع إبراز المهارات والإنجازات والأعمال والأهداف.',
    'راجع التسجيل الصوتي الذي سأرفقه كمراجعة أداء ظاهرة فقط: نقاط القوة، وضوح الأداء، الإيقاع أو التعبير المسموع، ومجالات التحسين، بدون تشخيص طبي أو ادعاء قياسات غير مؤكدة.',
    'راجع فيديو أو تسجيل أدائي على آلة موسيقية عند إرفاقه، واستخرج الملاحظات الفنية الظاهرة ونقاط القوة ومجالات التطوير بدون ادعاء قياسات لا يمكن إثباتها.',
    'ساعدني في تطوير فكرة أغنية: الفكرة، الموضوع، البناء، الكلمات أو الاتجاه الإبداعي بما يناسب أسلوبي.',
    'حوّل أغنياتي وتسجيلاتي وعروض الأداء والاعتمادات والإنجازات إلى Music Portfolio مرتب وقابل للمشاركة.',
    'ابنِ هويتي كفنان موسيقي: اسم/هوية فنية، نبذة، نقاط تميز، اتجاه بصري ورسالة للجمهور بدون مبالغة.',
    'أنشئ خطة عملية لإطلاق أغنية أو مشروع موسيقي تشمل التجهيز، المحتوى، العرض والمتابعة.',
    'أنشئ Setlist مناسباً لعرض موسيقي بناءً على نوع الموسيقى، مدة العرض، الجمهور والأغاني المتاحة.',
    'حدد المواهب الموسيقية التي تكملني للتعاون: مغنٍ، عازف، منتج، كاتب أغاني، مهندس صوت أو صانع محتوى، حسب احتياجي.',
    'قارن ملفي الموسيقي مع الفرصة التي أحددها مثل تجربة أداء أو Showcase أو تعاون، وحدد التوافق والفجوات.',
    'ابنِ لي Music Growth Roadmap لتطوير مهاراتي وأعمالي وعروضي وأدلتي وحضوري كموهبة موسيقية.',
    'أنشئ AI Music Talent Dossier يجمع هويتي الموسيقية، مهاراتي، أعمالي، إنجازاتي، أدلتي، أهدافي والفجوات والخطوات التالية.',
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
              '🎵 Music Talent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'أدوات متخصصة للمغنين والعازفين وكتاب الأغاني والملحنين والمنتجين والـDJ داخل Talent.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                AurenMusicTalentCatalog.all.length,
                (i) => ActionChip(
                  avatar: const Icon(Icons.music_note, size: 16),
                  label: Text(AurenMusicTalentCatalog.all[i].name),
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
