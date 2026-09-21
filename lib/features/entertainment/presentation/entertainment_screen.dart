import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import '../../../core/models/entertainment.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenAURENEntertainmentScreen extends StatefulWidget {
  const AurenAURENEntertainmentScreen({super.key});
  @override State<AurenAURENEntertainmentScreen> createState() => _AurenEntertainmentState();
}
class _AurenEntertainmentState extends State<AurenAURENEntertainmentScreen> {
  final repo = EntertainmentRepository(); final Set<String> saved = {}; String? type;
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar: AppBar(title: const Text('AUREN Entertainment')), body: StreamBuilder<List<AurenEntertainmentItem>>(stream: repo.watchItems(type: type), builder: (context, snapshot) {
      if (snapshot.hasError) return _error(snapshot.error);
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data ?? const <AurenEntertainmentItem>[];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.movie, size: 34), title: Text('Entertainment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), subtitle: Text('Global Series، Anime، Podcasts، Books و AUREN World.')),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [null, 'Global Series', 'Anime', 'Podcast', 'Book'].map((x) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(x ?? 'All'), selected: type == x, onSelected: (_) => setState(() => type = x))).toList())),
        const SizedBox(height: 12), if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا يوجد محتوى منشور لهذا التصنيف حالياً.'))),
        ...items.map((item) => Card(child: ListTile(
          leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.play_arrow)) : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
          title: Text(item.title), subtitle: Text('${item.type}\n${item.description}'), isThreeLine: true,
          trailing: IconButton(icon: Icon(saved.contains(item.id) ? Icons.bookmark : Icons.bookmark_border), onPressed: uid == null ? null : () async { final next = !saved.contains(item.id); setState(() => next ? saved.add(item.id) : saved.remove(item.id)); if (next) await repo.save(uid, item.id); else await repo.unsave(uid, item.id); }),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: 'اقترح لي طريقة ممتعة للاستمتاع بـ${item.title}.'))),
        ))),
      ]);
    }));
  }
}
Widget _error(Object? e) => Center(child: Padding(padding: EdgeInsets.all(24), child: Text('تعذر تحميل المحتوى. $e')));
