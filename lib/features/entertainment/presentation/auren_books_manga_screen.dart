import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'entertainment_detail_screen.dart';

class AurenBooksMangaScreen extends StatefulWidget {
  const AurenBooksMangaScreen({super.key});
  @override State<AurenBooksMangaScreen> createState() => _AurenBooksMangaScreenState();
}

class _AurenBooksMangaScreenState extends State<AurenBooksMangaScreen> {
  final repo = EntertainmentRepository();
  String _type = 'Book';
  String _query = '';
  bool _seeding = false;
  bool _globalSearching = false;
  List<Map<String, dynamic>> _globalResults = const [];
  List<Map<String, dynamic>> _subjects = const [];

  Future<void> _ensureLibrarySeeded() async {
    if (_seeding) return;
    setState(() => _seeding = true);
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('seedAurenEntertainmentLibrary')
          .call();
    } catch (_) {
      // The catalog can still be browsed if seeding is unavailable.
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }
  Future<void> _searchGlobalLibrary() async {
    final q = _query.trim();
    if (q.length < 2) return;
    setState(() => _globalSearching = true);
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('searchAurenGlobalLibrary').call({'query': q, 'page': 1});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['results'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) setState(() => _globalResults = rows);
    } catch (_) {
      if (mounted) setState(() => _globalResults = const []);
    } finally {
      if (mounted) setState(() => _globalSearching = false);
    }
  }

  static const _types = <String, String>{'Book':'Books','Manga':'Manga','Anime':'Anime','Journal':'Journals & Magazines'};

  Future<void> _loadSubjects() async {
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getAurenGlobalLibrarySubjects').call();
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['subjects'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() => _subjects = rows);
    } catch (_) {}
  }

  void _searchSubject(String title) {
    setState(() => _query = title);
    _searchGlobalLibrary();
  }

  @override
  void initState() { super.initState(); _loadSubjects(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Library')),
    body: StreamBuilder<List<AurenEntertainmentItem>>(
      stream: repo.watchItems(type: _type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AurenEntertainmentItem>[];
        if (items.isEmpty && snapshot.connectionState == ConnectionState.active && !_seeding) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLibrarySeeded());
        }
        final q = _query.trim().toLowerCase();
        final filtered = items.where((item) => q.isEmpty || (item.title + ' ' + item.description).toLowerCase().contains(q)).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16,12,16,28), children: [
          _hero(context),
          if (_seeding) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator()),
          const SizedBox(height:16),
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'ابحث: ماجد، ميكي، رجل المستحيل، مؤلف، ناشر، مجلة...'), onChanged:(v)=>setState(()=>_query=v), onSubmitted:(_)=>_searchGlobalLibrary()),
          const SizedBox(height:8),
          SizedBox(width:double.infinity, child:FilledButton.icon(onPressed:_globalSearching?null:_searchGlobalLibrary, icon:_globalSearching?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.travel_explore_rounded), label:const Text('البحث في Global Library Index'))),
          if (_globalResults.isNotEmpty) ...[
            const SizedBox(height:16),
            const Text('Global Library Index', style: TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            ..._globalResults.take(20).map((item)=>Card(child:ListTile(
              leading: item['imageUrl']?.toString().isNotEmpty == true ? CircleAvatar(backgroundImage:NetworkImage(item['imageUrl'].toString())) : const CircleAvatar(child:Icon(Icons.library_books_rounded)),
              title:Text(item['title']?.toString() ?? 'بدون عنوان',maxLines:2,overflow:TextOverflow.ellipsis),
              subtitle:Text([item['kind'],item['author'],item['publisher'],item['year'],item['source']].where((v)=>v!=null&&v.toString().trim().isNotEmpty).map((v)=>v.toString()).join(' • '),maxLines:3,overflow:TextOverflow.ellipsis),
              trailing:const Icon(Icons.open_in_new_rounded),
              onTap:()=>_openGlobalResult(item),
            ))),
          ],
          if (_subjects.isNotEmpty) ...[
            const SizedBox(height:18),
            const Text('Explore the World Library', style: TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
            const SizedBox(height:10),
            SizedBox(height:118, child: ListView.separated(scrollDirection:Axis.horizontal, itemCount:_subjects.length, separatorBuilder:(_,__)=>const SizedBox(width:10), itemBuilder:(context,index){
              final s=_subjects[index];
              return SizedBox(width:170, child:Card(child:InkWell(borderRadius:BorderRadius.circular(12), onTap:()=>_searchSubject(s['title']?.toString() ?? ''), child:Padding(padding:const EdgeInsets.all(12), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                Icon(_subjectIcon(s['id']?.toString() ?? ''), size:28), const SizedBox(height:8),
                Text(s['title']?.toString() ?? '', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(fontWeight:FontWeight.w800)),
                const SizedBox(height:4), Text(s['description']?.toString() ?? '', maxLines:2, overflow:TextOverflow.ellipsis, style:const TextStyle(fontSize:11)),
              ]))));
            })),
          ],
          const SizedBox(height:12),
          SingleChildScrollView(scrollDirection:Axis.horizontal, child:Row(children:_types.entries.map((e)=>Padding(padding:const EdgeInsetsDirectional.only(end:8), child:ChoiceChip(label:Text(e.value), selected:_type==e.key, onSelected:(_)=>setState(()=>_type=e.key)))).toList())),
          const SizedBox(height:16),
          if(snapshot.connectionState==ConnectionState.waiting) const Center(child:Padding(padding:EdgeInsets.all(24),child:CircularProgressIndicator()))
          else if(snapshot.hasError) Text('تعذر تحميل المكتبة: ' + snapshot.error.toString())
          else if(filtered.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('لا توجد عناصر منشورة في هذا القسم بعد. ستظهر هنا عندما تتم إضافة محتوى مرخّص إلى AUREN.',textAlign:TextAlign.center)))
          else ...filtered.map((item)=>Card(clipBehavior:Clip.antiAlias, child:ListTile(contentPadding:const EdgeInsets.all(10), leading:item.imageUrl.isEmpty?CircleAvatar(child:Icon(_iconFor(_type))):CircleAvatar(backgroundImage:NetworkImage(item.imageUrl)), title:Text(item.title,style:const TextStyle(fontWeight:FontWeight.w800)), subtitle:Text(item.description,maxLines:2,overflow:TextOverflow.ellipsis), trailing:const Icon(Icons.chevron_right_rounded), onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenEntertainmentDetailScreen(itemId:item.id))))))
        ]);
      },
    ),
  );

  void _openGlobalResult(Map<String, dynamic> item) {
    final url = item['sourceUrl']?.toString() ?? '';
    if (url.isEmpty) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(item['title']?.toString() ?? 'المصدر'),
      content: Text([item['description'], item['author'], item['publisher'], item['rights']].where((v)=>v!=null&&v.toString().trim().isNotEmpty).map((v)=>v.toString()).join('\\n\\n')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),TextButton(onPressed:(){Navigator.pop(context);},child:const Text('المصدر'))],
    ));
  }

  Widget _hero(BuildContext context) => Container(padding:const EdgeInsets.all(22), decoration:BoxDecoration(borderRadius:BorderRadius.circular(24), gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primaryContainer,Theme.of(context).colorScheme.tertiaryContainer])), child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.menu_book_rounded,size:42),SizedBox(height:8),Text('Read. Explore. Discover.',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),SizedBox(height:6),Text('Books • Manga • Anime • One smart library')]));
  IconData _iconFor(String type)=>type=='Manga'?Icons.auto_stories_rounded:type=='Anime'?Icons.animation_rounded:type=='Journal'?Icons.article_rounded:Icons.menu_book_rounded;

  IconData _subjectIcon(String id) {
    if (id.contains('literature') || id.contains('fiction')) return Icons.auto_stories_rounded;
    if (id.contains('history')) return Icons.account_balance_rounded;
    if (id.contains('arts')) return Icons.palette_rounded;
    if (id.contains('children')) return Icons.child_care_rounded;
    if (id.contains('science')) return Icons.science_rounded;
    if (id.contains('philosophy')) return Icons.psychology_rounded;
    if (id.contains('biography')) return Icons.person_rounded;
    if (id.contains('magazine')) return Icons.article_rounded;
    if (id.contains('arabic')) return Icons.public_rounded;
    return Icons.library_books_rounded;
  }
}