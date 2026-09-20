import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../social/presentation/user_search_screen.dart';

class AurenDiscoverScreen extends StatefulWidget {
  const AurenDiscoverScreen({super.key});
  @override
  State<AurenDiscoverScreen> createState() => _AurenDiscoverScreenState();
}

class _AurenDiscoverScreenState extends State<AurenDiscoverScreen> {
  String query = '';

  static const _items = <_DiscoverItem>[
    _DiscoverItem('People', 'اكتشف أشخاصًا واهتمامات جديدة', Icons.people_outline),
    _DiscoverItem('Places', 'أماكن وتجارب حول العالم', Icons.place_outlined),
    _DiscoverItem('Creators', 'مبدعون ومحتوى يستحق المتابعة', Icons.movie_creation_outlined),
    _DiscoverItem('Business', 'شركات ومتاجر وخدمات', Icons.storefront_outlined),
    _DiscoverItem('Entertainment', 'Series • Music • Gaming • Live', Icons.play_circle_outline),
    _DiscoverItem('Opportunities', 'عمل • مواهب • مشاريع • تعلم', Icons.work_outline),
  ];

  void _open(BuildContext context, _DiscoverItem item) {
    if (item.title == 'People') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenUserSearchScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(
          initialPrompt:
              'استكشف لي ' + item.title + ' في AUREN، واعرض لي اقتراحات مناسبة مع سبب ترشيح كل واحد.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          actions: [
            IconButton(
              tooltip: 'Global Search',
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AurenGlobalSearchScreen(),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'اكتشف عالمك',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'AUREN يتكيف مع ما يهمك — أشخاص، أماكن، محتوى وفرص.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            TextField(
              onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.tune),
                hintText: 'Filter Discover…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                title: const Text('اسأل AUREN'),
                subtitle: const Text('قل ما تريد اكتشافه وسأقترح لك الخطوة التالية.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessengerScreen(
                      initialPrompt:
                          'ساعدني أكتشف شيئًا جديدًا يناسب اهتماماتي وأهدافي اليوم.',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(child: ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('Trending now'),
              subtitle: const Text('شوف المواضيع والأفكار التي تتحرك الآن في AUREN.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'ما الأشياء الرائجة الآن في AUREN؟ اعرضها كمواضيع وأفكار قابلة للاستكشاف.'))),
            )),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.where((item) => query.isEmpty || ('${item.title} ${item.subtitle}').toLowerCase().contains(query)).length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = _items.where((item) => query.isEmpty || ('${item.title} ${item.subtitle}').toLowerCase().contains(query)).toList()[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _open(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
}

class _DiscoverItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DiscoverItem(this.title, this.subtitle, this.icon);
}
