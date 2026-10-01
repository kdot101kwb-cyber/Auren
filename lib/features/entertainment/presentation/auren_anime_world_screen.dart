import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenAnimeWorldScreen extends StatefulWidget {
  const AurenAnimeWorldScreen({super.key});

  @override
  State<AurenAnimeWorldScreen> createState() => _AurenAnimeWorldScreenState();
}

class _AurenAnimeWorldScreenState extends State<AurenAnimeWorldScreen> {
  final EntertainmentRepository _repo = EntertainmentRepository();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Anime World')),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: _repo.watchItems(type: 'Anime'),
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? const <AurenEntertainmentItem>[];
          final query = _query.trim().toLowerCase();
          final items = query.isEmpty
              ? allItems
              : allItems.where((item) {
                  final haystack =
                      '${item.title} ${item.description}'.toLowerCase();
                  return haystack.contains(query);
                }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _hero(context),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث في Anime...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Anime داخل AUREN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text('${items.length} عمل', style: Theme.of(context).textTheme.bodySmall),
                  if (query.isNotEmpty)
                    Text(
                      '${items.length} نتيجة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                _errorCard(snapshot.error)
              else if (items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      query.isEmpty
                          ? 'لا توجد أعمال Anime منشورة بعد. ستظهر هنا الأعمال المتاحة والمرخّصة داخل AUREN.'
                          : 'لا توجد نتائج لـ “$_query”. جرّب عنوانًا أو كلمة أخرى.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...items.map(_itemCard),
            ],
          );
        },
      ),
    );
  }

  Widget _itemCard(AurenEntertainmentItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: item.imageUrl.isEmpty
            ? const CircleAvatar(child: Icon(Icons.animation_rounded))
            : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id),
          ),
        ),
      ),
    );
  }

  Widget _errorCard(Object? error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'تعذر تحميل Anime الآن. حاول مرة أخرى لاحقًا.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.tertiaryContainer],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.animation_rounded, size: 42),
          SizedBox(height: 8),
          Text(
            'Anime World',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'اكتشف الأنمي، ابحث عن أعمالك، وافتح التفاصيل والقنوات المتاحة داخل AUREN.',
          ),
        ],
      ),
    );
  }
}
