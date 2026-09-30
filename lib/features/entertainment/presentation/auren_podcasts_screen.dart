import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../data/auren_podcast_catalog.dart';
import 'auren_audio_player_screen.dart';

class AurenPodcastsScreen extends StatefulWidget {
  const AurenPodcastsScreen({super.key});

  @override
  State<AurenPodcastsScreen> createState() => _AurenPodcastsScreenState();
}

class _AurenPodcastsScreenState extends State<AurenPodcastsScreen> {
  String _category = 'الكل';
  String _query = '';

  List<String> get _categories => [
        'الكل',
        ...aurenPodcastCatalog.map((e) => e.category).toSet(),
      ];

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Podcasts'),
        actions: [
          IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Podcast'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المحتوى: ${snapshot.error}'));
          }

          final q = _query.trim().toLowerCase();
          final filteredCatalog = aurenPodcastCatalog.where((item) {
            final categoryMatch =
                _category == 'الكل' || item.category == _category;
            final text =
                '${item.name} ${item.host} ${item.category} ${item.description}'
                    .toLowerCase();
            return categoryMatch && (q.isEmpty || text.contains(q));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              _buildHero(context),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ابحث عن بودكاست، مؤثر، رائد أعمال أو موضوع...',
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = _categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) =>
                          setState(() => _category = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (items.isNotEmpty) ...[
                const Text(
                  'حلقات موجودة في AUREN',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: item.imageUrl.isEmpty
                          ? const CircleAvatar(
                              child: Icon(Icons.podcasts),
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(item.imageUrl),
                            ),
                      title: Text(item.title),
                      subtitle: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: uid == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () => repo.save(uid, item.id),
                            ),
                      onTap: item.mediaUrl.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AurenAudioPlayerScreen(item: item),
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Text(
                'بودكاست عالمي مقترح',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'كتالوج اكتشاف للأسماء والبرامج المتداولة. عند ربط مصدر رسمي، يستطيع AUREN جلب الحلقات وتشغيلها بدل تخزين روابط غير مرخصة.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (filteredCatalog.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('لا توجد نتائج مطابقة.'),
                  ),
                )
              else
                ...filteredCatalog.map(_catalogCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listen. Learn. Build.',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 7),
          Text(
            'حياة • أعمال • مؤثرون • مؤسسون • أفكار • قصص',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _catalogCard(AurenPodcastCatalogItem item) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.mic_external_on_rounded),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.host} • ${item.category}\n${item.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
