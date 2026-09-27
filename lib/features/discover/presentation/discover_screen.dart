import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../../search/presentation/global_search_screen.dart';
import '../../social/presentation/user_search_screen.dart';
import '../../talent/presentation/talent_screen.dart';
import '../../education/presentation/education_screen.dart';
import '../../talent/presentation/talent_agents_screen.dart';
import '../../communities/presentation/communities_screen.dart';
import '../../entertainment/presentation/entertainment_screen.dart';
import '../../profile/presentation/adaptive_profile_surface.dart';
import '../../../services/social/adaptive_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _DiscoverItem('Education', 'تعلّم المهارات واربطها بالفرص', Icons.school_outlined),
    _DiscoverItem('Talent', 'مواهب ووكلاء AI للمسار المهني', Icons.psychology_outlined),
    _DiscoverItem('Communities', 'مجتمعات حول الاهتمامات والأهداف والمشاريع', Icons.groups_outlined),
  ];

  List<_DiscoverItem> get _filteredItems {
    final q = query.trim().toLowerCase();
    final source = q.isEmpty
        ? List<_DiscoverItem>.from(_items)
        : _items.where((item) {
            final haystack = (item.title + ' ' + item.subtitle).toLowerCase();
            return haystack.contains(q);
          }).toList();

    // Context changes presentation priority, not the underlying Discover data.
    final priority = <String>[];
    if (_hasAny(q, const ['business', 'company', 'shop', 'product', 'خدمة', 'شركة', 'تجارة', 'منتج'])) {
      priority.addAll(['Business', 'Creators', 'People', 'Places', 'Opportunities']);
    } else if (_hasAny(q, const ['creator', 'content', 'video', 'music', 'محتوى', 'فيديو', 'موسيقى'])) {
      priority.addAll(['Creators', 'Entertainment', 'Communities', 'People', 'Business']);
    } else if (_hasAny(q, const ['job', 'career', 'skill', 'work', 'وظيفة', 'مهنة', 'مهارة', 'فرصة'])) {
      priority.addAll(['Opportunities', 'Talent', 'People', 'Communities', 'Business']);
    } else if (_hasAny(q, const ['travel', 'place', 'hotel', 'سفر', 'مكان', 'فندق', 'رحلة'])) {
      priority.addAll(['Places', 'Entertainment', 'People', 'Communities', 'Business']);
    } else {
      priority.addAll(['People', 'Places', 'Creators', 'Entertainment', 'Communities', 'Opportunities', 'Talent', 'Business']);
    }

    source.sort((a, b) {
      final ai = priority.indexOf(a.title);
      final bi = priority.indexOf(b.title);
      return (ai < 0 ? 999 : ai).compareTo(bi < 0 ? 999 : bi);
    });
    return source;
  }

  bool _hasAny(String text, List<String> terms) =>
      terms.any((term) => text.contains(term));

  void _open(BuildContext context, _DiscoverItem item) {
    if (item.title == 'Education') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenEducationScreen()));
      return;
    }
    if (item.title == 'Talent') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenTalentScreen()));
      return;
    }
    if (item.title == 'Entertainment') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenAURENEntertainmentScreen()));
      return;
    }
    if (item.title == 'Communities') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCommunitiesScreen()));
      return;
    }
    if (item.title == 'People') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenUserSearchScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessengerScreen(
          initialPrompt: 'استكشف لي ' + item.title +
              ' في AUREN، واعرض لي اقتراحات مناسبة مع سبب ترشيح كل واحد.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Global Search',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AurenGlobalSearchScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'اكتشف عالمك',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'AUREN يتكيف مع ما يهمك — أشخاص، أماكن، محتوى وفرص.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          if (uid != null) ...[
            AurenAdaptiveProfileSurface(
              uid: uid,
              context: AurenProfileContext.unknown,
              intent: query.isEmpty ? 'اكتشاف أشخاص وأماكن ومحتوى وفرص' : query,
            ),
            const SizedBox(height: 6),
            AurenAdaptiveActionRail(
              uid: uid,
              context: AurenProfileContext.unknown,
              intent: query.isEmpty ? 'اكتشاف أشخاص وأماكن ومحتوى وفرص' : query,
              onPrompt: (prompt) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Filter Discover…',
              border: const OutlineInputBorder(),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () => setState(() => query = ''),
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 18),
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
                    initialPrompt: 'ساعدني أكتشف شيئًا جديدًا يناسب اهتماماتي وأهدافي اليوم.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: const Text('Talent Agents'),
              subtitle: const Text('وكلاء AI متخصصون للمواهب: Career • Discovery • Portfolio • Brand • Negotiation'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AurenTalentAgentsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('Trending now'),
              subtitle: const Text('شوف المواضيع والأفكار التي تتحرك الآن في AUREN.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessengerScreen(
                    initialPrompt: 'ما الأشياء الرائجة الآن في AUREN؟ اعرضها كمواضيع وأفكار قابلة للاستكشاف.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 42),
                    const SizedBox(height: 10),
                    const Text('ما لقينا قسم مطابق.', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'جرّب People أو Places أو Business أو Opportunities.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => query = ''),
                      icon: const Icon(Icons.refresh),
                      label: const Text('عرض الكل'),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
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
                          Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(item.subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
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
}

class _DiscoverItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DiscoverItem(this.title, this.subtitle, this.icon);
}
