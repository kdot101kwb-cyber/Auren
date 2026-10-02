import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';
import 'entertainment_shorts_screen.dart';

class AurenVideosScreen extends StatefulWidget {
  const AurenVideosScreen({super.key});
  @override State<AurenVideosScreen> createState() => _AurenVideosScreenState();
}

class _AurenVideosScreenState extends State<AurenVideosScreen> {
  final repo = EntertainmentRepository();
  Stream<Set<String>>? _savedStream;
  String? _uid;
  String _category = 'الكل';
  String _query = '';
  static const categories = ['الكل', 'فيديوهات', 'Shorts', 'Movies', 'Global Series', 'Anime', 'Kids'];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) _savedStream = repo.watchSavedIds(_uid!);
  }

  Future<void> _toggleSave(String itemId, bool saved) async {
    final uid = _uid;
    if (uid == null) return;
    if (saved) {
      await repo.unsave(uid, itemId);
    } else {
      await repo.save(uid, itemId);
    }
  }

  bool _matches(AurenEntertainmentItem item) {
    final hay = (item.title + ' ' + item.description + ' ' + item.type + ' ' + item.genres.join(' ')).toLowerCase();
    if (_query.isNotEmpty && !hay.contains(_query.toLowerCase())) return false;
    if (_category == 'الكل' || _category == 'فيديوهات') return item.isVideo;
    if (_category == 'Shorts') return item.type.toLowerCase() == 'short';
    if (_category == 'Kids') return hay.contains('kids') || hay.contains('children') || hay.contains('أطفال') || hay.contains('cartoon');
    return item.type.toLowerCase() == _category.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Videos'), actions: [if (_query.isNotEmpty || _category != 'الكل') IconButton(tooltip: 'مسح الفلاتر', icon: const Icon(Icons.filter_alt_off_rounded), onPressed: () => setState(() { _query = ''; _category = 'الكل'; })), IconButton(icon: const Icon(Icons.video_library_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenEntertainmentShortsScreen())))]),
      body: StreamBuilder<List<AurenEntertainmentItem>>(
        stream: repo.watchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الفيديوهات حالياً. حاول مرة أخرى.'));
          final items = (snapshot.data ?? const <AurenEntertainmentItem>[]).where((i) => i.isVideo && i.mediaUrl.isNotEmpty).where(_matches).toList();
          return StreamBuilder<Set<String>>(
            stream: _savedStream ?? Stream.value(const <String>{}),
            builder: (context, savedSnapshot) {
              final savedIds = savedSnapshot.data ?? const <String>{};
              return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('فيديوهات AUREN', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), SizedBox(height: 7), Text('فيديوهات طويلة • Shorts • أفلام • مسلسلات • أنمي • محتوى أطفال')])),
            const SizedBox(height: 14),
            TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'ابحث في الفيديوهات…', suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = ''))), onChanged: (v) => setState(() => _query = v.trim())),
            const SizedBox(height: 10),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.map((c) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)))).toList())),
            const SizedBox(height: 16),
            Text('النتائج: ${items.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد فيديوهات مطابقة حالياً.'))))
            else ...items.map((item) => Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: item.id))), child: Row(children: [
              SizedBox(width: 132, height: 86, child: item.imageUrl.isEmpty ? const ColoredBox(color: Colors.black12, child: Icon(Icons.play_circle_outline, size: 38)) : Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image_outlined)))),
              Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(item.type + (item.country.isEmpty ? '' : ' • ' + item.country), maxLines: 1, overflow: TextOverflow.ellipsis), if (item.description.isNotEmpty) Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis)]))),
              IconButton(
                tooltip: savedIds.contains(item.id) ? 'إزالة من المحفوظات' : 'حفظ',
                icon: Icon(savedIds.contains(item.id) ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _uid == null ? null : () => _toggleSave(item.id, savedIds.contains(item.id)),
              ),
              const Padding(padding: EdgeInsetsDirectional.only(end: 6), child: Icon(Icons.play_arrow_rounded)),
            ]))))
              ]);
            },
          );
        },
      ),
    );
  }
}