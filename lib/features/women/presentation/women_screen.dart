import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../safety/presentation/safety_center_screen.dart';
import '../../safety/presentation/emergency_contacts_screen.dart';

class AurenWomenScreen extends StatefulWidget {
  const AurenWomenScreen({super.key});
  @override State<AurenWomenScreen> createState() => _AurenWomenScreenState();
}

class _AurenWomenScreenState extends State<AurenWomenScreen> {
  int tab = 0;
  final sections = const <Map<String, Object>>[
    {'title':'Career & Skills','subtitle':'مهارات، عمل وفرص مهنية','icon':Icons.work_outline},
    {'title':'Business & Growth','subtitle':'مشاريع، تجارة ونمو الأعمال','icon':Icons.business_center_outlined},
    {'title':'Learning','subtitle':'تعلم مرن وربط المهارات بالفرص','icon':Icons.school_outlined},
    {'title':'Community','subtitle':'مجتمعات ودعم وتبادل خبرات','icon':Icons.groups_outlined},
    {'title':'Wellbeing','subtitle':'عادات صحية ورياضية ومعلومات عامة','icon':Icons.favorite_border},
  ];

  void _open(BuildContext context, String prompt) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)));

  void _openEducation(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AurenAURENEducationScreen()),
  );

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Women')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16,12,16,28), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مساحة تركّز على فرص وتجارب النساء', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('تجربة قابلة للتخصيص للتعلم والعمل والأعمال والمجتمع، مع أدوات AI تساعدك على تحويل الهدف إلى خطوات.'),
        const SizedBox(height: 16),
        SegmentedButton<int>(segments: const [ButtonSegment(value:0,label:Text('Explore')),ButtonSegment(value:1,label:Text('My Plan'))], selected:{tab}, onSelectionChanged:(v)=>setState(()=>tab=v.first)),
      ]))),
      const SizedBox(height: 12),
      if (tab == 1) Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('AI Personal Plan'), subtitle: const Text('حوّل هدفك إلى خطة أسبوعية قابلة للتنفيذ.'), trailing: const Icon(Icons.chevron_right), onTap: () => _open(context, 'أنشئ لي خطة أسبوعية شخصية لامرأة بناءً على هدفي ومهاراتي ووقتي المتاح، مع خطوات عملية وفرص مناسبة.'))),
      if (tab == 0) ...sections.map((item) => Card(child: ListTile(
        leading: Icon(item['icon'] as IconData),
        title: Text(item['title'] as String),
        subtitle: Text(item['subtitle'] as String),
        trailing: const Icon(Icons.chevron_right),
        onTap: item['title'] == 'Learning'
            ? () => _openEducation(context)
            : () => _open(context, 'استكشف في AUREN ' + (item['title'] as String) + ' للنساء، واقترح موارد وفرص وأنشطة مناسبة مع خطوات عملية.'),
      )))),
      const SizedBox(height: 12),
      Card(child: Column(children: [
        const ListTile(leading: Icon(Icons.shield_outlined), title: Text('Privacy & Safety'), subtitle: Text('الخصوصية والتحكم في المشاركة جزء أساسي من التجربة.')),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Safety Center'), subtitle: const Text('أدوات الحماية والخصوصية وإدارة الأمان.'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCenterScreen()))),
        ListTile(leading: const Icon(Icons.contact_phone_outlined), title: const Text('Emergency Contacts'), subtitle: const Text('إدارة جهات الطوارئ الموثوقة.'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()))),
        ListTile(leading: const Icon(Icons.report_outlined), title: const Text('Safety Help'), subtitle: const Text('معلومات عامة عن السلامة والدعم بدون مشاركة بيانات شخصية.'), onTap: () => _open(context, 'أحتاج معلومات عامة عن السلامة والدعم المحلي للنساء. اعرض خيارات موثوقة وخطوات واضحة بدون طلب بيانات شخصية.')),
      ])),
    ]),
  );
}