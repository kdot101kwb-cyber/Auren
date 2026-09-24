import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../talent/presentation/talent_agents_screen.dart';

class AurenAgentSuiteScreen extends StatelessWidget {
  const AurenAgentSuiteScreen({super.key});

  static const agents = <Map<String, String>>[
    {'category':'Personal','name':'Personal AI Agent','desc':'يفهم أهدافك وسياقك ويساعدك في تنظيم يومك وقراراتك.','prompt':'تصرف كـ Personal AI Agent في AUREN. ساعدني في تنظيم أهدافي وخطوتي التالية باستخدام السياق الذي أشاركه معك.'},
    {'category':'Talent','name':'Talent Discovery Agent','desc':'يبحث عن فرص ومشاريع وشراكات مناسبة لمهاراتك.','prompt':'تصرف كـ Talent Discovery Agent. حلل مهاراتي وأهدافي وما أشاركه، ثم اقترح فرصاً ومهارات ناقصة وخطوات للتواصل.'},
    {'category':'Business','name':'Business Growth Agent','desc':'يحوّل وضع النشاط التجاري إلى خطة نمو وعملاء وتسويق.','prompt':'تصرف كـ Business Growth Agent. ساعدني في تحليل نشاطي وبناء خطة نمو عملية تشمل العملاء والتسويق والشراكات.'},
    {'category':'Commerce','name':'Supplier & Export Agent','desc':'يساعد في البحث عن موردين وتجهيز خطط التصدير والتجارة.','prompt':'تصرف كـ Supplier & Export Agent. ساعدني في تحديد متطلبات الشراء والموردين وخطة التصدير، مع التحقق من التفاصيل قبل أي التزام.'},
    {'category':'Creator','name':'Creator Studio Agent','desc':'يساعد المبدع في الأفكار والمحتوى والجدولة وتحسين العرض.','prompt':'تصرف كـ Creator Studio Agent. ساعدني في تطوير أفكار محتوى وخطة نشر وهوية مناسبة لجمهوري.'},
    {'category':'Opportunity','name':'Opportunity Match Agent','desc':'يطابق المهارات والأهداف مع الفرص بطريقة قابلة للتفسير.','prompt':'تصرف كـ Opportunity Match Agent. قارن مهاراتي وأهدافي مع الفرص التي أشاركها، واذكر نقاط التطابق والفجوات بوضوح.'},
    {'category':'Learning','name':'Skill Coach Agent','desc':'يبني مسار تعلم عملي ويربط التعلم بالمشاريع والفرص.','prompt':'تصرف كـ Skill Coach Agent. حدد المهارات التي أحتاجها لهدفي وابنِ لي مسار تعلم عملياً مع تطبيقات ومشاريع.'},
    {'category':'Marketing','name':'Campaign Agent','desc':'يساعد في تصميم الحملات والمحتوى والجمهور وقياس النتائج.','prompt':'تصرف كـ Campaign Agent. ساعدني في بناء حملة تسويقية واضحة: الهدف، الجمهور، الرسائل، المحتوى، القنوات وقياس النتائج.'},
    {'category':'Partnerships','name':'Partnership Agent','desc':'يحدد فرص الشراكة ويجهز رسائل وعروض التعاون.','prompt':'تصرف كـ Partnership Agent. ساعدني في تحديد أنواع الشركاء المناسبين وصياغة عرض تعاون ورسالة تواصل.'},
    {'category':'Research','name':'Market Intelligence Agent','desc':'ينظم البحث والمقارنة واستخراج الإشارات المهمة قبل القرار.','prompt':'تصرف كـ Market Intelligence Agent. ساعدني في تحديد ما يجب بحثه ومقارنة الخيارات وتنظيم الأدلة قبل اتخاذ القرار.'},
    {'category':'Travel','name':'Travel Agent','desc':'يخطط الرحلات والميزانية والأنشطة مع مراعاة القيود التي أذكرها.','prompt':'تصرف كـ AUREN Travel Agent. ساعدني في بناء رحلة حسب الوجهة والميزانية والوقت والاهتمامات التي أشاركها.'},
    {'category':'Home','name':'Home & Life Agent','desc':'ينظم المهام المنزلية والاحتياجات والخدمات اليومية.','prompt':'تصرف كـ Home & Life Agent. ساعدني في تنظيم احتياجات المنزل والمهام والخدمات في خطة بسيطة.'},
  ];

  void _open(BuildContext context, String prompt) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Agent Suite')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Row(children: [Icon(Icons.auto_awesome), SizedBox(width: 10), Text('وكلاء AUREN', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))]),
            SizedBox(height: 8),
            Text('اختر الوكيل المناسب للمهمة. الوكلاء يقترحون ويخططون، وأي إجراء حساس يحتاج موافقة صريحة.'),
          ]),
        )),
        const SizedBox(height: 12),
        Card(child: ListTile(
          leading: const Icon(Icons.psychology_outlined),
          title: const Text('Talent Agents'),
          subtitle: const Text('إدارة الوكلاء المتخصصين للموهبة'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTalentAgentsScreen())),
        )),
        const SizedBox(height: 8),
        ...agents.map((a) => Card(child: ListTile(
          leading: CircleAvatar(child: Text(a['category']!.substring(0, 1))),
          title: Text(a['name']!),
          subtitle: Text(a['desc']!),
          trailing: const Icon(Icons.chat_outlined),
          onTap: () => _open(context, a['prompt']!),
        ))),
      ],
    ),
  );
}
