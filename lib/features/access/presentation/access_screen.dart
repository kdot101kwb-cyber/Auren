import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';

class AurenAccessScreen extends StatelessWidget {
  const AurenAccessScreen({super.key});

  void _ask(BuildContext context, String prompt) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));
  }

  @override
  Widget build(BuildContext context) {
    final items = <_AccessItem>[
      _AccessItem('Vision Support', 'أدوات ووصف المحتوى بطريقة أكثر قابلية للوصول.', Icons.visibility_outlined, 'ساعدني أستخدم AUREN بطريقة مناسبة لضعف البصر.'),
      _AccessItem('Hearing & Communication', 'خيارات تواصل ونصوص وشرح واضح للمحتوى.', Icons.hearing_outlined, 'اقترح لي إعدادات تواصل مناسبة لضعف السمع.'),
      _AccessItem('Mobility', 'خطط وخيارات تراعي سهولة الحركة والوصول.', Icons.accessible_outlined, 'ساعدني أبحث عن خيارات وخدمات تراعي سهولة الحركة.'),
      _AccessItem('Cognitive Support', 'تبسيط المعلومات وتحويلها إلى خطوات قصيرة.', Icons.psychology_outlined, 'بسّط لي هذه المهمة إلى خطوات واضحة وسهلة التنفيذ.'),
      _AccessItem('Accessibility Map', 'أماكن وخدمات يمكن تقييمها حسب احتياجات الوصول.', Icons.map_outlined, 'ساعدني أبني معايير لخريطة أماكن صديقة لإمكانية الوصول.'),
      _AccessItem('AI Accessibility Coach', 'خصص تجربة AUREN حسب احتياجك.', Icons.auto_awesome, 'راجع احتياجات الوصول عندي واقترح إعدادات وتجربة استخدام مناسبة.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Access AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('AUREN للجميع', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('إمكانية الوصول ليست ميزة جانبية. الهدف أن تكون تجربة AUREN قابلة للتخصيص حسب احتياجات كل شخص.'),
          const SizedBox(height: 16),
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.auto_awesome)), title: const Text('Personalize my experience'), subtitle: const Text('دع AI يساعدك في اختيار إعدادات وتدفق استخدام مناسب.'), trailing: const Icon(Icons.chevron_right), onTap: () => _ask(context, 'أريد تجربة AUREN بإمكانية وصول أفضل. اسألني عن احتياجي ثم اقترح إعدادات مناسبة.'))),
          const SizedBox(height: 14),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.03), itemBuilder: (context, index) {
            final item = items[index];
            return Card(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => _ask(context, item.prompt), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, size: 30), const SizedBox(height: 10), Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 5), Text(item.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis)]))));
          }),
          const SizedBox(height: 14),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lock_outline), SizedBox(width: 10), Expanded(child: Text('لا تطلب AUREN معلومات حساسة إلا عند الحاجة. تحكم في تفضيلات الوصول والبيانات التي تختار حفظها.'))]))),
        ],
      ),
    );
  }
}

class _AccessItem {
  final String title, subtitle, prompt;
  final IconData icon;
  const _AccessItem(this.title, this.subtitle, this.icon, this.prompt);
}