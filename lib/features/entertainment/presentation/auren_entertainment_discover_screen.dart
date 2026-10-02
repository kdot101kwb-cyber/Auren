import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_audio_player_screen.dart';
import 'entertainment_detail_screen.dart';
import 'watch_together_screen.dart';

class AurenEntertainmentDiscoverScreen extends StatefulWidget {
  const AurenEntertainmentDiscoverScreen({super.key});
  @override State<AurenEntertainmentDiscoverScreen> createState()=>_AurenEntertainmentDiscoverScreenState();
}

class _AurenEntertainmentDiscoverScreenState extends State<AurenEntertainmentDiscoverScreen> {
  final _repo=EntertainmentRepository();
  final _search=TextEditingController();
  String _query='';

  @override void dispose(){_search.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar:AppBar(title:const Text('اكتشف Entertainment'),actions:[if(_query.isNotEmpty)IconButton(tooltip:'مسح البحث',icon:const Icon(Icons.clear),onPressed:(){_search.clear();setState(()=>_query='');})]),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          TextField(
            controller:_search,
            onChanged:(v)=>setState(()=>_query=v),
            decoration:InputDecoration(
              prefixIcon:const Icon(Icons.search_rounded),
              hintText:'ابحث عن فيلم، مسلسل، أغنية...',
              border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height:20),
          if(_query.isEmpty&&uid!=null)...[
            const Text('مقترح لك بالذكاء الاصطناعي',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
            const SizedBox(height:8),
            StreamBuilder<List<AurenEntertainmentItem>>(
              stream:_repo.watchAiRecommendations(uid),
              builder:(c,s)=>_items(s.data??const []),
            ),
            const SizedBox(height:20),
          ],
          Text(
            _query.isEmpty?'استكشف المحتوى':'نتائج البحث • ${_query.trim()}',
            style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900),
          ),
          const SizedBox(height:8),
          StreamBuilder<List<AurenEntertainmentItem>>(
            stream:_repo.searchEntertainment(_query),
            builder:(c,s)=>_items(s.data??const []),
          ),
        ],
      ),
    );
  }

  Widget _items(List<AurenEntertainmentItem> items){
    if(items.isEmpty)return const Card(
      child:Padding(
        padding:EdgeInsets.all(18),
        child:Text('لا يوجد محتوى متاح حالياً.'),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('النتائج: ${items.length}', style: const TextStyle(fontWeight: FontWeight.w700))),
        ...items.take(20).map((item)=>Card(
        child:ListTile(
          onTap:()=>_openItem(item),
          leading:CircleAvatar(
            backgroundImage:item.imageUrl.isNotEmpty?NetworkImage(item.imageUrl):null,
            child:item.imageUrl.isEmpty
                ?Icon(item.isVideo?Icons.play_arrow_rounded:Icons.music_note_rounded)
                :null,
          ),
          title:Text(item.title,maxLines:1,overflow:TextOverflow.ellipsis),
          subtitle:Text(
            item.description,
            maxLines:2,
            overflow:TextOverflow.ellipsis,
          ),
          trailing:IconButton(
            icon:const Icon(Icons.groups_rounded),
            tooltip:'Watch Together',
            onPressed:()=>_createRoom(item),
          ),
        ),
      )).toList(),
    );
  }

  void _openItem(AurenEntertainmentItem item){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:(_)=>item.isAudio
            ? AurenAudioPlayerScreen(item:item)
            : AurenEntertainmentDetailScreen(itemId:item.id),
      ),
    );
  }

  Future<void> _createRoom(AurenEntertainmentItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AurenWatchTogetherScreen(
          title: item.title,
          mediaUrl: item.mediaUrl.isNotEmpty ? item.mediaUrl : null,
          mediaId: item.id,
        ),
      ),
    );
  }}
