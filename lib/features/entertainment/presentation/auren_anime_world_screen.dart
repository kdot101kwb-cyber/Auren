import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenAnimeWorldScreen extends StatelessWidget {
  const AurenAnimeWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Anime World')),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(type: 'Anime'),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <AurenEntertainmentItem>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _hero(context),
              const SizedBox(height: 16),
              const Text('Anime داخل AUREN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (snapshot.hasError)
                Text('تعذر تحميل Anime: ' + snapshot.error.toString())
              else if (items.isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'لا توجد أعمال Anime منشورة بعد. ستظهر هنا الأعمال المتاحة والمرخّصة داخل AUREN.',
                    textAlign: TextAlign.center,
                  ),
                ))
              else
                ...items.map((item) => Card(
                  child: ListTile(
                    leading: item.imageUrl.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.animation_rounded))
                        : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
                    title: Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(item.description, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id),
                    )),
                  ),
                )),
            ],
          );
        },
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
          Text('Anime World',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('اكتشف الأنمي، تابع أعمالك، واستكشف قنوات Anime داخل AUREN.'),
        ],
      ),
    );
  }
}
