import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';
import 'auren_radio_screen.dart';

class AurenLiveEntertainmentScreen extends StatelessWidget {
  const AurenLiveEntertainmentScreen({super.key});
  @override Widget build(BuildContext context) {
    final repo = EntertainmentRepository();
    return Scaffold(appBar: AppBar(title: const Text('AUREN Live'), actions: [IconButton(icon: const Icon(Icons.radio), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenRadioScreen())))]),
      body: StreamBuilder<List<AurenEntertainmentItem>>(stream: repo.watchItems(), builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل البث المباشر حالياً. حاول مرة أخرى.'));
        final items = (snapshot.data ?? const <AurenEntertainmentItem>[]).where((i) { final t=i.type.toLowerCase(); final text=(i.title+' '+i.description+' '+i.genres.join(' ')).toLowerCase(); return i.mediaUrl.isNotEmpty && (t=='live'||t=='live video'||t=='broadcast'||text.contains('live')); }).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('بث فيديو مباشر • أحداث • عروض • رياضة • قنوات • Radio')])),
          const SizedBox(height: 16),
          if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('لا توجد بثوث فيديو مباشرة منشورة حالياً. يمكنك فتح Radio من الأعلى.')))
          else ...items.map((item) => Card(clipBehavior: Clip.antiAlias, child: ListTile(leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.live_tv)) : CircleAvatar(child: ClipOval(child: Image.network(item.imageUrl,width:40,height:40,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.live_tv)))), title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Chip(label: Text('LIVE')), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id))))),
        ]);
      }),
    );
  }
}