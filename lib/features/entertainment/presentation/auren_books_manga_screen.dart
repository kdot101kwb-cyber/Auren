import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _unescoSearching = false;
  List<Map<String, dynamic>> _globalResults = const [];
  List<Map<String, dynamic>> _unescoResults = const [];
  List<Map<String, dynamic>> _subjects = const [];
  List<Map<String, dynamic>> _heritageStories = const [];
  bool _heritageLoading = false;
  List<String> _heritageCountries = const [];
  String _heritageCountry = '';
  String _heritageRegion = '';
  String _heritageType = '';
  String _heritageYear = '';
  List<Map<String, dynamic>> _heritageRegions = const [];
  List<String> _heritageTypes = const [];
  List<String> _heritageYears = const [];
  int _heritageTotal = 0;
  bool _worldLoading = false;
  List<Map<String, dynamic>> _worldResults = const [];
  List<String> _worldRegions = const [];
  List<String> _worldCountries = const [];
  List<String> _worldCategories = const [];
  String _worldRegion = '';
  String _worldCountry = '';
  String _worldCategory = '';
  String _worldYear = '';
  bool _magazineLoading = false;
  List<Map<String, dynamic>> _magazineResults = const [];
  bool _comicLoading=false; List<Map<String,dynamic>> _comicResults=const [];
  bool _researchLoading=false; List<Map<String,dynamic>> _researchResults=const [];
  Map<String,dynamic>? _graph;
  Future<void> _searchComics() async { final q=_query.trim(); if(q.length<2)return; setState(()=>_comicLoading=true); try { final r=await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('searchAurenComics').call({'query':q,'limit':30}); final d=Map<String,dynamic>.from(r.data as Map); if(mounted)setState(()=>_comicResults=(d['results'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()); } catch(_){if(mounted)setState(()=>_comicResults=const []);} finally{if(mounted)setState(()=>_comicLoading=false);} }
  Future<void> _searchResearch() async { final q=_query.trim(); if(q.length<2)return; setState(()=>_researchLoading=true); try { final r=await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('searchAurenResearch').call({'query':q,'limit':30}); final d=Map<String,dynamic>.from(r.data as Map); if(mounted)setState(()=>_researchResults=(d['results'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()); } catch(_){if(mounted)setState(()=>_researchResults=const []);} finally{if(mounted)setState(()=>_researchLoading=false);} }
  Future<void> _loadGraph(Map<String,dynamic> item) async { try { final r=await FirebaseFunctions.instanceFor(region:'us-central1').httpsCallable('getAurenLibraryGraph').call(item); final d=Map<String,dynamic>.from(r.data as Map); if(mounted)setState(()=>_graph=d); } catch(_){} }

  Future<void> _loadWorldHeritage() async {
    if (_worldLoading) return;
    setState(() => _worldLoading = true);
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getAurenWorldHeritageExplorer')
          .call({'region': _worldRegion, 'country': _worldCountry, 'category': _worldCategory, 'year': _worldYear, 'query': ''});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['results'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      if (mounted) setState(() {
        _worldResults=rows;
        _worldRegions=(data['regions'] as List? ?? const []).map((e)=>e.toString()).toList();
        _worldCountries=(data['countries'] as List? ?? const []).map((e)=>e.toString()).toList();
        _worldCategories=(data['categories'] as List? ?? const []).map((e)=>e.toString()).toList();
      });
    } catch (_) {
      if (mounted) setState(()=>_worldResults=const []);
    } finally {
      if (mounted) setState(()=>_worldLoading=false);
    }
  }

  Future<void> _searchMagazines() async {
    final q=_query.trim();
    if(q.length<2) return;
    setState(()=>_magazineLoading=true);
    try {
      final response=await FirebaseFunctions.instanceFor(region:'us-central1')
          .httpsCallable('searchAurenMagazines').call({'query':q,'limit':40});
      final data=Map<String,dynamic>.from(response.data as Map);
      final rows=(data['results'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      if(mounted) setState(()=>_magazineResults=rows);
    } catch (_) {
      if(mounted) setState(()=>_magazineResults=const []);
    } finally {
      if(mounted) setState(()=>_magazineLoading=false);
    }
  }

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
    setState(() { _globalSearching = true; _unescoSearching = true; });
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
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('searchAurenUNESCOHeritage')
          .call({'query': q, 'limit': 40});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['results'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) setState(() => _unescoResults = rows);
    } catch (_) {
      if (mounted) setState(() => _unescoResults = const []);
    } finally {
      if (mounted) setState(() => _unescoSearching = false);
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

  Future<void> _loadHeritage({String? country, String? query}) async {
    if (_heritageLoading) return;
    setState(() => _heritageLoading = true);
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getAurenGlobalHeritageStories').call({'country': country ?? _heritageCountry, 'region': _heritageRegion, 'type': _heritageType, 'year': _heritageYear, 'query': query ?? ''});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['results'] as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final countries = (data['countries'] as List? ?? const []).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toSet().toList()..sort();
      final regions = (data['regions'] as List? ?? const []).whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();
      final types = (data['types'] as List? ?? const []).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toSet().toList()..sort();
      final years = rows.map((e) => e['year']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort((a,b)=>b.compareTo(a));
      final total = (data['total'] as num?)?.toInt() ?? rows.length;
      if (mounted) setState(() { _heritageStories = rows; _heritageCountries = countries; _heritageRegions = regions; _heritageTypes = types; _heritageYears = years; _heritageTotal = total; });
    } catch (_) { if (mounted) setState(() => _heritageStories = const []); }
    finally { if (mounted) setState(() => _heritageLoading = false); }
  }

  Future<void> _openHeritage(Map<String, dynamic> item) async {
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getAurenGlobalHeritageStoryDetail').call({'id': item['id']});
      final data = Map<String, dynamic>.from(response.data as Map);
      final story = Map<String, dynamic>.from(data['story'] as Map? ?? item);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(story['title']?.toString() ?? 'Heritage'),
        content: SingleChildScrollView(child: Text([story['description'], 'الشخصيات: ' + ((data['characters'] as List? ?? const []).join(', ')), 'اللغات: ' + ((data['languages'] as List? ?? const []).join(', ')), 'الروايات: ' + ((data['variants'] as List? ?? const []).join(', ')), 'المصدر: ' + (story['source']?.toString() ?? '')].where((v)=>v.trim().length>0).join('\\n\\n'))),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إغلاق'))],
      ));
    } catch (_) { _openGlobalResult(item); }
  }

  void _searchSubject(String title) {
    setState(() => _query = title);
    _searchGlobalLibrary();
  }

  @override
  void initState() { super.initState(); _loadSubjects(); _loadHeritage(); _loadWorldHeritage(); }

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
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'ابحث: ماجد، ميكي، رجل المستحيل، مؤلف، ناشر، مجلة...'), onChanged:(v)=>setState(()=>_query=v), onSubmitted:(_){_searchGlobalLibrary();_searchMagazines();_searchComics();_searchResearch();}),
          const SizedBox(height:8),
          SizedBox(width:double.infinity, child:FilledButton.icon(onPressed:_globalSearching?null:(){_searchGlobalLibrary();_searchMagazines();_searchComics();_searchResearch();}, icon:_globalSearching?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.travel_explore_rounded), label:const Text('البحث في Global Library Index'))),
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
          if (_unescoResults.isNotEmpty || _unescoSearching) ...[
            const SizedBox(height:18),
            Row(children:[
              const Expanded(child:Text('UNESCO Heritage • التراث العالمي',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
              if (_unescoSearching) const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),
            ]),
            const Padding(
              padding: EdgeInsets.only(bottom:8),
              child: Text('بحث حي من UNESCO DataHub • المصدر الرسمي محفوظ مع كل نتيجة', style: TextStyle(fontSize:12)),
            ),
            ..._unescoResults.take(20).map((item)=>Card(child:ListTile(
              leading: item['imageUrl']?.toString().isNotEmpty == true
                  ? CircleAvatar(backgroundImage:NetworkImage(item['imageUrl'].toString()))
                  : const CircleAvatar(child:Icon(Icons.public_rounded)),
              title:Text(item['title']?.toString() ?? 'بدون عنوان',maxLines:2,overflow:TextOverflow.ellipsis),
              subtitle:Text([
                item['listName'], item['year'], item['countries'], item['concepts'],
              ].where((v)=>v!=null&&v.toString().trim().isNotEmpty).map((v)=>v.toString()).join(' • '),maxLines:3,overflow:TextOverflow.ellipsis),
              trailing:const Icon(Icons.open_in_new_rounded),
              onTap:()=>_openGlobalResult(item),
            ))),
          ],
          if (_worldResults.isNotEmpty || _worldLoading) ...[
            const SizedBox(height:18),
            Row(children:[
              const Expanded(child:Text('World Heritage Explorer • مواقع التراث العالمي',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
              if(_worldLoading) const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),
            ]),
            const Text('UNESCO World Heritage List • فلترة حسب المنطقة والدولة والنوع والسنة',style:TextStyle(fontSize:12)),
            const SizedBox(height:8),
            _heritageFilterRow('المنطقة', ['كل المناطق', ..._worldRegions], _worldRegion.isEmpty?'كل المناطق':_worldRegion, (v){setState(()=>_worldRegion=v=='كل المناطق'?'':v);_loadWorldHeritage();}),
            _heritageFilterRow('الدولة', ['كل الدول', ..._worldCountries], _worldCountry.isEmpty?'كل الدول':_worldCountry, (v){setState(()=>_worldCountry=v=='كل الدول'?'':v);_loadWorldHeritage();}),
            _heritageFilterRow('النوع', ['كل الأنواع', ..._worldCategories], _worldCategory.isEmpty?'كل الأنواع':_worldCategory, (v){setState(()=>_worldCategory=v=='كل الأنواع'?'':v);_loadWorldHeritage();}),
            const SizedBox(height:8),
            SizedBox(height:150,child:_worldLoading?const Center(child:CircularProgressIndicator()):ListView.separated(scrollDirection:Axis.horizontal,itemCount:_worldResults.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(context,index){
              final s=_worldResults[index];
              return SizedBox(width:250,child:Card(child:InkWell(onTap:()=>_openGlobalResult(s),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Icon(s['category']?.toString().toLowerCase().contains('natural')==true?Icons.landscape_rounded:Icons.account_balance_rounded,size:28),
                const SizedBox(height:7),Text(s['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
                const SizedBox(height:5),Text([s['category'],s['year'],s['region']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • '),maxLines:1,overflow:TextOverflow.ellipsis),
                const SizedBox(height:5),Text(s['countries']?.toString()??'',maxLines:1,overflow:TextOverflow.ellipsis),
              ]))));
            })),
          ],
          if (_magazineResults.isNotEmpty || _magazineLoading) ...[
            const SizedBox(height:18),
            Row(children:[
              const Expanded(child:Text('Magazines & Series • المجلات والسلاسل',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
              if(_magazineLoading) const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),
            ]),
            const Text('فهرس metadata وروابط المصادر • بدون استضافة نسخ محمية',style:TextStyle(fontSize:12)),
            const SizedBox(height:8),
            ..._magazineResults.take(15).map((m)=>Card(child:ListTile(
              leading:const CircleAvatar(child:Icon(Icons.article_rounded)),
              title:Text(m['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis),
              subtitle:Text([m['kind'],m['country'],m['publisher'],m['language'],m['source']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • '),maxLines:3,overflow:TextOverflow.ellipsis),
              trailing:const Icon(Icons.open_in_new_rounded),
              onTap:()=>_openGlobalResult(m),
            ))),
          ],
          if (_heritageStories.isNotEmpty || _heritageLoading) ...[
            const SizedBox(height:18),
            Row(children:[
              const Expanded(child:Text('Global Heritage • قصص الشعوب',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
              IconButton(tooltip:'تحديث',onPressed:_heritageLoading?null:()=>_loadHeritage(country:_heritageCountry),icon:const Icon(Icons.refresh_rounded)),
            ]),
            Padding(padding:const EdgeInsets.only(bottom:8),child:Text('$_heritageTotal records • القارات والدول واللغات والتقاليد',style:const TextStyle(fontSize:12))),
            _heritageFilterRow('القارة / المنطقة', _heritageRegions.map((e)=>e['title']?.toString() ?? '').toList(), _heritageRegion, (value){ setState(()=>_heritageRegion=value); _loadHeritage(); }),
            const SizedBox(height:6),
            _heritageFilterRow('الدولة', ['كل الدول', ..._heritageCountries], _heritageCountry.isEmpty?'كل الدول':_heritageCountry, (value){ final v=value=='كل الدول'?'':value; setState(()=>_heritageCountry=v); _loadHeritage(country:v); }),
            const SizedBox(height:6),
            _heritageFilterRow('نوع التراث', ['كل الأنواع', ..._heritageTypes], _heritageType.isEmpty?'كل الأنواع':_heritageType, (value){ final v=value=='كل الأنواع'?'':value; setState(()=>_heritageType=v); _loadHeritage(); }),
            const SizedBox(height:6),
            _heritageFilterRow('السنة', ['كل السنوات', ..._heritageYears], _heritageYear.isEmpty?'كل السنوات':_heritageYear, (value){ final v=value=='كل السنوات'?'':value; setState(()=>_heritageYear=v); _loadHeritage(); }),
            const SizedBox(height:8),
            SizedBox(height:150,child:_heritageLoading?const Center(child:CircularProgressIndicator()):ListView.separated(scrollDirection:Axis.horizontal,itemCount:_heritageStories.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(context,index){
              final s=_heritageStories[index];
              return SizedBox(width:230,child:Card(child:InkWell(onTap:()=>_openHeritage(s),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Icon(Icons.public_rounded,size:28),const SizedBox(height:8),
                Text(s['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
                const SizedBox(height:5),Text([s['country'],s['kind'],s['language']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • '),maxLines:1,overflow:TextOverflow.ellipsis),
                const SizedBox(height:5),Text(s['description']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11))
              ]))));
            }))
          ],
          if (_comicResults.isNotEmpty || _comicLoading) ...[
            const SizedBox(height:18), Row(children:[const Expanded(child:Text('Comics • Manga • Graphic Novels',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),if(_comicLoading)const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))]),
            ..._comicResults.take(12).map((m)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.auto_stories_rounded)),title:Text(m['title']?.toString()??''),subtitle:Text([m['kind'],m['country'],m['publisher'],m['language']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • ')),onTap:()=>_loadGraph(m)))),
          ],
          if (_researchResults.isNotEmpty || _researchLoading) ...[
            const SizedBox(height:18), Row(children:[const Expanded(child:Text('Research & References • الأبحاث والمراجع',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800))),if(_researchLoading)const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))]),
            ..._researchResults.take(12).map((m)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.science_rounded)),title:Text(m['title']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text([m['author'],m['journal'],m['year'],m['doi']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • ')),onTap:()=>_loadGraph(m)))),
          ],
          if (_graph != null) ...[
            const SizedBox(height:18), Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Knowledge Graph • شبكة المعرفة',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(((_graph!['nodes'] as List?)??const []).length.toString()+' nodes • '+(((_graph!['edges'] as List?)??const []).length.toString())+' relations'),const SizedBox(height:8),...((_graph!['nodes'] as List?)??const []).take(10).map((n)=>Text('• '+n['type'].toString()+': '+n['label'].toString()))]))),
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

  Widget _heritageFilterRow(String label, List<String> values, String selected, ValueChanged<String> onSelected) {
    final unique = values.where((v)=>v.trim().isNotEmpty).toSet().toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
      const SizedBox(height:4),
      SizedBox(height:38,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:unique.length,separatorBuilder:(_,__)=>const SizedBox(width:6),itemBuilder:(context,index){
        final value=unique[index];
        return ChoiceChip(label:Text(value,maxLines:1,overflow:TextOverflow.ellipsis),selected:selected==value,onSelected:(_)=>onSelected(value));
      })),
    ]);
  }

  void _openGlobalResult(Map<String, dynamic> item) {
    final url = item['sourceUrl']?.toString() ?? '';
    if (url.isEmpty) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(item['title']?.toString() ?? 'المصدر'),
      content: Text([item['description'], item['author'], item['publisher'], item['rights']].where((v)=>v!=null&&v.toString().trim().isNotEmpty).map((v)=>v.toString()).join('\\n\\n')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إغلاق')),TextButton.icon(icon:const Icon(Icons.open_in_new_rounded),label:const Text('المصدر'),onPressed:() async { final uri=Uri.tryParse(url); if (uri != null) await launchUrl(uri,mode:LaunchMode.externalApplication); })],
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