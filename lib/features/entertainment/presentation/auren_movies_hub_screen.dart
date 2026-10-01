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
  String _country = 'الكل';
  String _language = 'الكل';
  String _search = '';
  bool _lowData = false;
  static const _genres = ['الكل','Action','Comedy','Drama','Romance','Thriller','Documentary','Animation'];
  String _norm(String v) => v.trim().toLowerCase();

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎬 AUREN Movies'), actions: [
      IconButton(icon: const Icon(Icons.auto_awesome), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessengerScreen(initialPrompt: 'أنت AUREN Movies AI. ساعدني في اختيار فيلم مناسب لوقتي ومزاجي ونوع المحتوى الذي أريده، مع احترام الحقوق وتوفر المحتوى.')))),
    ]),
    body: StreamBuilder<List<AurenEntertainmentItem>>(
      stream: _repo.watchItems(type: 'Movie'),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AurenEntertainmentItem>[];
        final countries = ['الكل', ...{for (final x in items) if (x.country.trim().isNotEmpty) x.country.trim()}];
        final languages = ['الكل', ...{for (final x in items) if (x.language.trim().isNotEmpty) x.language.trim()}];
        final filtered = items.where((x) {
          final text = _norm('${x.title} ${x.description} ${x.genres.join(' ')}');
          final genreOk = _genre == 'الكل' || x.genres.any((g) => _norm(g) == _norm(_genre)) || text.contains(_norm(_genre));
          final countryOk = _country == 'الكل' || _norm(x.country) == _norm(_country);
          final languageOk = _language == 'الكل' || _norm(x.language) == _norm(_language);
          final searchOk = _search.isEmpty || text.contains(_norm(_search)) || _norm(x.country).contains(_norm(_search)) || _norm(x.language).contains(_norm(_search));
          return genreOk && countryOk && languageOk && searchOk;
        })\n          .toList()\n          ..sort((a, b) {\n            final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());\n            return byTitle != 0 ? byTitle : a.id.compareTo(b.id);\n          });
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Movie Universe', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${items.length} فيلم متاح • اكتشاف عالمي + توصيات ذكية'),
          ]))),
          const SizedBox(height: 14),
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن فيلم، دولة أو لغة'), onChanged: (v) => setState(() => _search = v)),
          const SizedBox(height: 12),
          SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: countries.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(countries[i]), selected: _country == countries[i], onSelected: (_) => setState(() => _country = countries[i])))),
          const SizedBox(height: 8),
          SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: languages.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(languages[i]), selected: _language == languages[i], onSelected: (_) => setState(() => _language = languages[i])))),
          const SizedBox(height: 12),
          SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _genres.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ChoiceChip(label: Text(_genres[i]), selected: _genre == _genres[i], onSelected: (_) => setState(() => _genre = _genres[i])))),
          const SizedBox(height: 12),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Low Data'), subtitle: const Text('عرض الصور بشكل أخف عند ضعف الإنترنت'), value: _lowData, onChanged: (v) => setState(() => _lowData = v)),
          const SizedBox(height: 8),
          if (snapshot.hasError) Text('تعذر تحميل الأفلام: ${snapshot.error}'),
          if (filtered.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد أفلام مضافة بعد. يمكن لـ AUREN استقبال المحتوى المرخص أو الذي يملكه المنشئ.')))),
          for (final item in filtered) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: _lowData || item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.movie)) : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl), onBackgroundImageError: (_, __) {}), title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.play_arrow), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntertainmentDetailScreen(itemId: item.id))))),
        ]);
      },
    ),
  );
}
