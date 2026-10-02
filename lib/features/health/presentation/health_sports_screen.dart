import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../../entertainment/presentation/auren_sports_entertainment_screen.dart';

class AurenHealthSportsScreen extends StatelessWidget {
  const AurenHealthSportsScreen({super.key});

  void _ask(BuildContext context, String prompt) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_HealthCard>[
      _HealthCard('Daily Wellness', 'عادات يومية للصحة، الحركة، الماء والنوم.', Icons.favorite_outline, 'أنشئ لي خطة عافية يومية بسيطة تناسب وقتي ومستواي.'),
      _HealthCard('Fitness & Activity', 'تمارين وحركة وتتبع للتقدم بدون تعقيد.', Icons.fitness_center_outlined, 'خطط لي تمرينًا آمنًا للمبتدئ اليوم مع إحماء وتهدئة.'),
      _HealthCard('Nutrition', 'أفكار وجبات وعادات غذائية عملية.', Icons.restaurant_menu_outlined, 'اقترح لي خطة وجبات عملية ومنخفضة التكلفة مع خيارات محلية.'),
      _HealthCard('Sleep & Recovery', 'روتين نوم واستشفاء وتحسين العادات.', Icons.bedtime_outlined, 'ساعدني أبني روتين نوم واستشفاء واقعي هذا الأسبوع.'),
      _HealthCard('Wellbeing', 'مزاج، ضغط يومي، تنفس وروتين توازن.', Icons.self_improvement_outlined, 'اعمل لي روتين wellbeing قصير لليوم.'),
      _HealthCard('Health Coach', 'اسأل AUREN عن العادات الصحية وخطتك اليومية.', Icons.auto_awesome, 'راجع أهدافي الصحية وساعدني أحولها إلى خطوات صغيرة قابلة للتنفيذ.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Health & Sports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('صحتك وحركتك', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('AUREN يجمع العافية اليومية مع الرياضة في مساحة واحدة، مع AI يساعدك على تحويل الهدف إلى خطوات.'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.sports_soccer)),
              title: const Text('Sports Hub'),
              subtitle: const Text('مباريات، دوريات، نتائج وتفاصيل الرياضات العالمية — عبر نظام الرياضة الموجود في AUREN.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSportsEntertainmentScreen())),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI Health Coach'),
              subtitle: const Text('حوّل هدفك إلى خطة يومية، وتابع التقدم معك خطوة بخطوة.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ask(context, 'أريد تحسين صحتي ولياقتي. اسألني عن هدفي ووقتي ومستواي ثم ابنِ لي خطة بسيطة قابلة للتنفيذ.'),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _ask(context, card.prompt),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(card.icon, size: 30),
                      const SizedBox(height: 10),
                      Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(card.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Expanded(child: Text('هذه المساحة للعافية واللياقة العامة وليست بديلًا عن الطبيب أو خدمات الطوارئ. عند وجود أعراض خطيرة أو حالة طارئة استخدم خدمات الطوارئ المناسبة.')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final String prompt;
  const _HealthCard(this.title, this.subtitle, this.icon, this.prompt);
}