import 'package:flutter/material.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenExpansionFiveScreen extends StatelessWidget {
  const AurenExpansionFiveScreen({super.key});

  static const modules = <_ExpansionModule>[
    _ExpansionModule('Files / Browser / VPN','ملفات، تخزين، تصفح واتصال منخفض البيانات.',Icons.folder_outlined),
    _ExpansionModule('Health / Sports / Fitness','مدرب شخصي، نشاط، رياضة ومتابعة أهداف.',Icons.fitness_center_outlined),
    _ExpansionModule('Culture / News / Radio','أخبار، ثقافة، بودكاست وراديو ومحتوى محلي.',Icons.public_outlined),
    _ExpansionModule('Family / Kids / Women','مسارات وتجارب وأدوات عائلية آمنة.',Icons.family_restroom_outlined),
    _ExpansionModule('AUREN World','عوالم وتجارب ومحاكاة مرتبطة بسياق المستخدم.',Icons.public),
  ];

  void _open(BuildContext context, _ExpansionModule item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(
          initialPrompt:
              'ابدأ بناء وحدة ${item.title} في AUREN. '
              'اعرض ما هو موجود فعليًا، وحدد أول وظائف قابلة للتنفيذ، '
              'واربطها بـPersonal AI وSocial وBusiness وMarketplace وCreator '
              'بدون تكرار أي وظيفة موجودة.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AUREN Expansion 5')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'خمس وحدات التوسع التالية',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'بعد Core 5 وNext 5، نوسّع AUREN إلى أدوات الحياة والمحتوى والعوالم الرقمية.',
            ),
            const SizedBox(height: 16),
            ...modules.asMap().entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${entry.key + 1}')),
                      title: Row(
                        children: [
                          Icon(entry.value.icon, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(entry.value.description),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(context, entry.value),
                    ),
                  ),
                ),
          ],
        ),
      );
}

class _ExpansionModule {
  final String title;
  final String description;
  final IconData icon;

  const _ExpansionModule(this.title, this.description, this.icon);
}
