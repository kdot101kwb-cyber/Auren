import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenMoviesHubScreen extends StatefulWidget {
  const AurenMoviesHubScreen({super.key});
  @override State<AurenMoviesHubScreen> createState() => _AurenMoviesHubScreenState();
}

class _AurenMoviesHubScreenState extends State<AurenMoviesHubScreen> {
  final _repo = EntertainmentRepository();
  String _genre = 'الكل';
  static const _genres = ['الكل','Action','Comedy','Drama','Romance','Thriller','Documentary','Animation'];

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎬 AUREN Movies'), actions: [
      IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'أنت AUREN Movies AI. ساعدني في اختيار فيلم مناسب لوقتي ومزاجي ونوع المحتوى الذي أريده، مع احترام الحقوق وتوفر المحتوى.')))),
    ]),
    body: StreamBuilder<List<AurenEntertainmentItem>>(
      stream: _repo.watchItems(type: 'Movie'),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AurenEntertainmentItem>[];
        final filtered = _genre == 'الكل' ? items : items.where((x) => ('${x.title} ${x.description}').toLowerCase().contains(_genre.toLowerCase())).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Movie Universe', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${items.length} فيلم متاح • اكتشاف عالمي + توصيات ذكية'),
          ]))),
          const SizedBox(height: 14),
          SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _genres.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(_genres[i]), selected: _genre == _genres[i], onSelected: (_) => setState(() => _genre = _genres[i])))),
          const SizedBox(height: 16),
          if (snapshot.hasError) Text('تعذر تحميل الأفلام: ${snapshot.error}'),
          if (filtered.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد أفلام مضافة بعد. يمكن لـ AUREN استقبال المحتوى المرخص أو الذي يملكه المنشئ.')))),
          for (final item in filtered) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.movie)) : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)), title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.play_arrow), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntertainmentDetailScreen(itemId: item.id))))),
        ]);
      },
    ),
  );
}
