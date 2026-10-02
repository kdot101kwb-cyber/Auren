import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenEventsEntertainmentScreen extends StatefulWidget {
  const AurenEventsEntertainmentScreen({super.key});
  @override State<AurenEventsEntertainmentScreen> createState() => _AurenEventsEntertainmentScreenState();
}
class _AurenEventsEntertainmentScreenState extends State<AurenEventsEntertainmentScreen> {
  final _repo = EntertainmentRepository(); String _query = ''; String _country = '';
  bool _loadingRemote = false;
  List<Map<String,dynamic>> _remote = [];
  Future<void> _loadRemote() async { setState(() => _loadingRemote = true); try { final r = await FirebaseFunctions.instance.httpsCallable('searchAurenEvents').call({'query': _query, 'countryCode': _country}); final data = Map<String,dynamic>.from(r.data as Map); if (data['status'] == 'ok') setState(() => _remote = List<Map<String,dynamic>>.from(data['results'] ?? const [])); if (data['status'] == 'not_configured' && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مصدر الفعاليات يحتاج API key في Firebase Functions.'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر جلب الفعاليات: $e'))); } finally { if (mounted) setState(() => _loadingRemote = false); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('AUREN Events'), actions: [if (_query.isNotEmpty || _country.isNotEmpty) IconButton(tooltip: 'مسح الفلاتر', icon: const Icon(Icons.filter_alt_off_rounded), onPressed: () { setState(() { _query = ''; _country = ''; _remote = []; }); })]), body: StreamBuilder<List<AurenEntertainmentItem>>(stream: _repo.watchItems(), builder: (context, snapshot) {
    if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الفعاليات حالياً. حاول مرة أخرى.'));
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    final items = (snapshot.data ?? const <AurenEntertainmentItem>[]).where((item) {
      final text = ('${item.title} ${item.description} ${item.type} ${item.country}').toLowerCase(); final q = _query.trim().toLowerCase(); final type = item.type.toLowerCase();
      final event = type.contains('event') || type.contains('festival') || type.contains('concert') || text.contains('event') || text.contains('festival') || text.contains('concert');
      return event && (q.isEmpty || text.contains(q));
    }).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Events & Experiences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), SizedBox(height: 7), Text('حفلات • مهرجانات • عروض • فعاليات • تجارب ترفيهية')])),
      const SizedBox(height: 14), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن فعالية أو مهرجان أو حفلة'), onChanged: (v) => setState(() => _query = v)),
      const SizedBox(height: 10), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final c in const {'Global':'','Egypt':'EG','UAE':'AE','South Africa':'ZA','Kenya':'KE','Uganda':'UG','UK':'GB','US':'US'})
          Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(c.key), selected: _country == c.value, onSelected: (_) { setState(() => _country = c.value); if (!_loadingRemote) _loadRemote(); })),
      ])),
      const SizedBox(height: 10), FilledButton.icon(onPressed: _loadingRemote ? null : _loadRemote, icon: _loadingRemote ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.cloud_download), label: const Text('جلب الفعاليات من المصدر الموثوق')), if (_remote.isNotEmpty) ...[const SizedBox(height:12), Text('فعاليات من المصدر الموثوق (${_remote.length})',style:const TextStyle(fontWeight:FontWeight.w800)), ..._remote.map((x)=>Card(child:ListTile(title:Text(x['title']?.toString()??''),subtitle:Text('${x['venue']??''} • ${x['city']??''} • ${x['date']??''}'),leading:const Icon(Icons.event))))],
      const SizedBox(height: 14), Text('النتائج المحلية: ${items.length}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد فعاليات منشورة حالياً. عند إضافة فعاليات إلى AUREN ستظهر هنا تلقائياً.'))) else ...items.map((item) => Card(child: ListTile(leading: item.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.event)) : CircleAvatar(child: ClipOval(child: Image.network(item.imageUrl,width:40,height:40,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.event)))), title: Text(item.title), subtitle: Text('${item.country.isEmpty ? 'Global' : item.country} • ${item.description}', maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id))))))
    ]);
  });
}