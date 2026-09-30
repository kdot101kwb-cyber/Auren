import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenEventsEntertainmentScreen extends StatefulWidget {
  const AurenEventsEntertainmentScreen({super.key});
  @override State<AurenEventsEntertainmentScreen> createState() => _AurenEventsEntertainmentScreenState();
}
class _AurenEventsEntertainmentScreenState extends State<AurenEventsEntertainmentScreen> {
  final _repo = EntertainmentRepository(); String _query = '';
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('AUREN Events')), body: StreamBuilder<List<AurenEntertainmentItem>>(stream: _repo.watchItems(), builder: (context, snapshot) {
    if (snapshot.hasError) return Center(child: Text('تعذر تحميل الفعاليات: '+snapshot.error.toString()));
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    final items = (snapshot.data ?? const <AurenEntertainmentItem>[]).where((item) {
      final text = ('${item.title} ${item.description} ${item.type} ${item.country}').toLowerCase(); final q = _query.trim().toLowerCase(); final type = item.type.toLowerCase();
      final event = type.contains('event') || type.contains('festival') || type.contains('concert') || text.contains('event') || text.contains('festival') || text.contains('concert');
      return event && (q.isEmpty || text.contains(q));
    }).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Events & Experiences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), SizedBox(height: 7), Text('حفلات • مهرجانات • عروض • فعاليات • تجارب ترفيهية')])),
      const SizedBox(height: 14), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن فعالية أو مهرجان أو حفلة'), onChanged: (v) => setState(() => _query = v)),
      const SizedBox(height: 14), if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد فعاليات منشورة حالياً. عند إضافة فعاليات إلى AUREN ستظهر هنا تلقائياً.'))) else ...items.map((item) => Card(child: ListTile(leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.event)) : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)), title: Text(item.title), subtitle: Text('${item.country.isEmpty ? 'Global' : item.country} • ${item.description}', maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id))))))
    ]);
  });
}