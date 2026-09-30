import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/entertainment/entertainment_repository.dart';
import 'auren_sports_detail_screen.dart';
import 'entertainment_detail_screen.dart';

class AurenSportsEntertainmentScreen extends StatefulWidget {
  const AurenSportsEntertainmentScreen({super.key});
  @override State<AurenSportsEntertainmentScreen> createState() => _AurenSportsEntertainmentScreenState();
}
class _AurenSportsEntertainmentScreenState extends State<AurenSportsEntertainmentScreen> {
  final repo = EntertainmentRepository();
  final query = TextEditingController(), country = TextEditingController(), league = TextEditingController(), season = TextEditingController();
  static const sports = ['الكل','Football','Basketball','Tennis','Cricket','Baseball','Hockey','Handball','Volleyball','Rugby','MMA','Formula 1','NFL'];
  static const resources = {'games':'المباريات','leagues':'البطولات','teams':'الفرق','standings':'الترتيب','players':'اللاعبون','team_stats':'إحصائيات الفريق','game_details':'تفاصيل المباراة'};
  String sport='الكل', resource='games';
  bool loading=false;
  List<Map<String,dynamic>> remote=[];
  String get apiSport => sport=='الكل' ? 'football' : sport.toLowerCase().replaceAll(' ','');
  @override void dispose(){query.dispose();country.dispose();league.dispose();season.dispose();super.dispose();}
  Future<void> searchRemote() async {
    setState(()=>loading=true);
    try {
      final r=await FirebaseFunctions.instance.httpsCallable('searchAurenSports').call({
        'query':query.text.trim(),'sport':apiSport,'resource':resource,
        'country':country.text.trim(),'leagueId':league.text.trim(),'season':season.text.trim(),
      });
      final d=Map<String,dynamic>.from(r.data as Map);
      if(mounted)setState(()=>remote=List<Map<String,dynamic>>.from(d['results']??const []));
      if(mounted&&d['status']=='not_configured'&&remote.isEmpty)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مفاتيح مصادر الرياضة في Firebase Functions.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر جلب بيانات الرياضة: $e')));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    return Scaffold(body:StreamBuilder<List<AurenEntertainmentItem>>(stream:repo.watchItems(),builder:(context,snapshot){
      final q=query.text.trim().toLowerCase();
      final published=(snapshot.data??const <AurenEntertainmentItem>[]).where((x){
        final h=(x.title+' '+x.description+' '+x.type+' '+x.genres.join(' ')).toLowerCase();
        final isSports=h.contains('sport')||h.contains('football')||h.contains('soccer')||h.contains('basketball')||h.contains('tennis')||h.contains('cricket');
        return isSports&&(sport=='الكل'||h.contains(sport.toLowerCase()))&&(q.isEmpty||h.contains(q));
      }).toList();
      return CustomScrollView(slivers:[
        SliverToBoxAdapter(child:_Hero(cs)),
        SliverToBoxAdapter(child:_Explorer(query:query,country:country,league:league,season:season,sport:sport,resource:resource,loading:loading,onSport:(v){setState((){sport=v;remote=[];});},onResource:(v)=>setState(()=>resource=v),onSearch:searchRemote)),
        if(remote.isNotEmpty)SliverToBoxAdapter(child:_Section(title:'من المصدر',icon:Icons.public,child:Column(children:remote.take(30).map((x)=>ListTile(
          leading:CircleAvatar(backgroundColor:cs.primaryContainer,child:const Icon(Icons.sports)),
          title:Text((x['title']??x['name']??'بيانات رياضية').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text([x['league'],x['country'],x['date'],x['status'],x['source']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • '),maxLines:2,overflow:TextOverflow.ellipsis),
          trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenSportsDetailScreen(sport:apiSport,resource:resource,data:x))),
        )).toList()))),
        if(published.isNotEmpty)SliverToBoxAdapter(child:_Section(title:'داخل AUREN',icon:Icons.auto_awesome,child:Column(children:published.map((x)=>ListTile(
          leading:x.imageUrl.isEmpty?const CircleAvatar(child:Icon(Icons.sports)):CircleAvatar(backgroundImage:NetworkImage(x.imageUrl)),
          title:Text(x.title),subtitle:Text(x.type+' • '+x.description,maxLines:2,overflow:TextOverflow.ellipsis),
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenEntertainmentDetailScreen(itemId:x.id))),
        )).toList()))),
        if(remote.isEmpty&&published.isEmpty)const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(24),child:_Empty())),
        const SliverToBoxAdapter(child:SizedBox(height:28)),
      ]);
    }));
  }
}
class _Hero extends StatelessWidget{
  final ColorScheme cs;const _Hero(this.cs);
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.fromLTRB(16,16,16,10),padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[cs.primary,cs.secondary])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(Icons.sports_score,color:Colors.white,size:34),SizedBox(height:18),
    Text('كل الرياضة في مكان واحد',style:TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),SizedBox(height:7),
    Text('مباريات • بطولات • فرق • لاعبين • ترتيب • إحصائيات',style:TextStyle(color:Colors.white70,fontSize:14)),
  ]));
}
class _Explorer extends StatelessWidget{
  final TextEditingController query,country,league,season;final String sport,resource;final bool loading;final ValueChanged<String> onSport,onResource;final Future<void> Function() onSearch;
  const _Explorer({required this.query,required this.country,required this.league,required this.season,required this.sport,required this.resource,required this.loading,required this.onSport,required this.onResource,required this.onSearch});
  @override Widget build(BuildContext context)=>_Section(title:'استكشف',icon:Icons.explore_rounded,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    TextField(controller:query,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'فريق، لاعب، مباراة أو بطولة',border:OutlineInputBorder())),
    const SizedBox(height:12),const Text('الرياضة',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),
    _chips(sports,sport,onSport),const SizedBox(height:14),const Text('المحتوى',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),
    _chips(resources.keys.toList(),resource,onResource,resources),const SizedBox(height:12),
    Row(children:[Expanded(child:_field(country,'الدولة')),const SizedBox(width:8),Expanded(child:_field(league,'League ID')),const SizedBox(width:8),Expanded(child:_field(season,'الموسم'))]),const SizedBox(height:14),
    SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:loading?null:onSearch,icon:loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.public),label:Text(loading?'جاري البحث…':'ابحث في المصادر'))),
  ]));
  Widget _chips(List<String> values,String selected,ValueChanged<String> tap,[Map<String,String>? labels])=>SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:values.map((v)=>Padding(padding:const EdgeInsetsDirectional.only(end:8),child:ChoiceChip(label:Text(labels?[v]??v),selected:selected==v,onSelected:(_)=>tap(v)))).toList()));
  Widget _field(TextEditingController c,String label)=>TextField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()));
}
class _Section extends StatelessWidget{
  final String title;final IconData icon;final Widget child;const _Section({required this.title,required this.icon,required this.child});
  @override Widget build(BuildContext context)=>Card(margin:const EdgeInsets.fromLTRB(16,8,16,8),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon),const SizedBox(width:8),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900))]),const SizedBox(height:12),child])));
}
class _Empty extends StatelessWidget{const _Empty();@override Widget build(BuildContext context)=>Card(elevation:0,child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[Icon(Icons.sports_score,size:44,color:Theme.of(context).colorScheme.primary),const SizedBox(height:12),const Text('ابدأ بالبحث عن رياضة أو فريق أو بطولة.',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w700))])));}
