import 'package:flutter/material.dart';

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
  static const _types = <String, String>{'Book':'Books','Manga':'Manga','Anime':'Anime'};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Library')),
    body: StreamBuilder<List<AurenEntertainmentItem>>(
      stream: repo.watchItems(type: _type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AurenEntertainmentItem>[];
        final q = _query.trim().toLowerCase();
        final filtered = items.where((item) => q.isEmpty || (item.title + ' ' + item.description).toLowerCase().contains(q)).toList();
        return ListView(padding: const EdgeInsets.fromLTRB(16,12,16,28), children: [
          _hero(context), const SizedBox(height:16),
          TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'ابحث في الكتب أو المانجا أو الأنمي'), onChanged:(v)=>setState(()=>_query=v)),
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

  Widget _hero(BuildContext context) => Container(padding:const EdgeInsets.all(22), decoration:BoxDecoration(borderRadius:BorderRadius.circular(24), gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primaryContainer,Theme.of(context).colorScheme.tertiaryContainer])), child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.menu_book_rounded,size:42),SizedBox(height:8),Text('Read. Explore. Discover.',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),SizedBox(height:6),Text('Books • Manga • Anime • One smart library')]));
  IconData _iconFor(String type)=>type=='Manga'?Icons.auto_stories_rounded:type=='Anime'?Icons.animation_rounded:Icons.menu_book_rounded;
}