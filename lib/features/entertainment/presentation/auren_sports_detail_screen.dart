import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AurenSportsDetailScreen extends StatefulWidget {
  final String sport;
  final String resource;
  final Map<String,dynamic> data;
  const AurenSportsDetailScreen({super.key, required this.sport, required this.resource, required this.data});
  @override State<AurenSportsDetailScreen> createState()=>_AurenSportsDetailScreenState();
}

class _AurenSportsDetailScreenState extends State<AurenSportsDetailScreen> {
  String tab='overview';
  bool loading=false;
  List<dynamic> rows=[];
  List<dynamic> h2h=[];
  String? error;

  String get gameId => (widget.data['id']??widget.data['fixtureId']??'').toString();
  String get homeId => (widget.data['homeTeamId']??widget.data['teams']?['home']?['id']??'').toString();
  String get awayId => (widget.data['awayTeamId']??widget.data['teams']?['away']?['id']??'').toString();

  @override void initState(){super.initState(); _load('overview');}

  Future<void> _load(String value) async {
    setState(()=>loading=true);
    try {
      final resource=value=='overview'?'game_details':value;
      final r=await FirebaseFunctions.instance.httpsCallable('searchAurenSports').call({
        'sport':widget.sport,'resource':resource,'gameId':gameId,'fixtureId':gameId,
        'homeTeamId':homeId,'awayTeamId':awayId,
      });
      final m=Map<String,dynamic>.from(r.data as Map);
      if(m['status']!='ok') throw Exception('unavailable');
      if(mounted)setState(()=>rows=List<dynamic>.from(m['results']??const []));
      if(value=='overview' && homeId.isNotEmpty && awayId.isNotEmpty) {
        try {
          final h=await FirebaseFunctions.instance.httpsCallable('searchAurenSports').call({
            'sport':'football','resource':'h2h','homeTeamId':homeId,'awayTeamId':awayId,
          });
          final hm=Map<String,dynamic>.from(h.data as Map);
          if(mounted)setState(()=>h2h=List<dynamic>.from(hm['results']??const []));
        } catch (_) {}
      }
      if(mounted)setState(()=>error=null);
    } catch(e) {
      if(mounted)setState(()=>error=e.toString());
    } finally { if(mounted)setState(()=>loading=false); }
  }

  @override Widget build(BuildContext context) {
    final title=(widget.data['title']??widget.data['name']??'المباراة').toString();
    final home=(widget.data['home']??widget.data['teams']?['home']?['name']??'الفريق الأول').toString();
    final away=(widget.data['away']??widget.data['teams']?['away']?['name']??'الفريق الثاني').toString();
    final status=(widget.data['status']??widget.data['fixture']?['status']?['long']??'').toString();
    final score=(widget.data['score']??'').toString();
    return Scaffold(
      body: CustomScrollView(slivers:[
        SliverAppBar.large(
          pinned:true,
          title:Text(title,maxLines:1,overflow:TextOverflow.ellipsis),
          flexibleSpace:FlexibleSpaceBar(background:Container(
            decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[
              Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.secondary,
            ])),
            child:Padding(padding:const EdgeInsets.fromLTRB(20,125,20,18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(home+'  ×  '+away,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
              const SizedBox(height:6),
              Text([score,status,widget.data['date']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' • '),style:const TextStyle(color:Colors.white70)),
            ])),
          )),
        ),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          _tab('overview','المباراة',Icons.sports_score),
          _tab('match_events','الأحداث',Icons.bolt),
          _tab('match_lineups','التشكيل',Icons.groups),
          _tab('match_stats','الإحصائيات',Icons.analytics),
          _tab('match_players','اللاعبون',Icons.person),
        ])))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),child:_content())),
        const SliverToBoxAdapter(child:SizedBox(height:30)),
      ]),
    );
  }

  Widget _tab(String value,String label,IconData icon)=>Padding(
    padding:const EdgeInsetsDirectional.only(end:8),
    child:ChoiceChip(avatar:Icon(icon,size:16),label:Text(label),selected:tab==value,onSelected:(_){setState(()=>tab=value);_load(value);}),
  );

  Widget _content() {
    if(loading)return const Card(elevation:0,child:Padding(padding:EdgeInsets.all(28),child:Center(child:CircularProgressIndicator())));
    if(error!=null && rows.isEmpty)return Card(elevation:0,child:Padding(padding:const EdgeInsets.all(22),child:Column(children:[
      const Icon(Icons.info_outline,size:40),const SizedBox(height:10),const Text('لم تتوفر هذه البيانات من المصدر حاليًا',textAlign:TextAlign.center),
      const SizedBox(height:12),FilledButton.icon(onPressed:()=>_load(tab),icon:const Icon(Icons.refresh),label:const Text('إعادة المحاولة')),
    ])));
    if(tab=='overview')return _overview();
    return Card(elevation:0,child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
      if(rows.isEmpty)const Padding(padding:EdgeInsets.all(18),child:Text('لا توجد بيانات متاحة حاليًا.')),
      ...rows.take(30).map((x)=>_row(x)),
    ])));
  }

  Widget _overview()=>Column(children:[
    _scoreCard(),
    if(h2h.isNotEmpty)Card(elevation:0,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('آخر المواجهات',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),...h2h.take(5).map((x)=>_row(x)),
    ]))),
  ]);

  Widget _scoreCard(){
    final x=rows.isNotEmpty && rows.first is Map ? Map<String,dynamic>.from(rows.first as Map):widget.data;
    final teams=x['teams']; final goals=x['goals']; final fixture=x['fixture'];
    final home=(teams is Map?teams['home']?['name']:null)??widget.data['home']??'Home';
    final away=(teams is Map?teams['away']?['name']:null)??widget.data['away']??'Away';
    final hg=goals is Map?goals['home']:null;
    final ag=goals is Map?goals['away']:null;
    final venue=fixture is Map?fixture['venue']?['name']:null;
    return Card(elevation:0,child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      Text(home.toString()+'  •  '+away.toString(),textAlign:TextAlign.center,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
      const SizedBox(height:10),Text((hg??'-').toString()+'  —  '+(ag??'-').toString(),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900)),
      if(venue!=null&&venue.toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(venue.toString())),
    ])));
  }

  Widget _row(dynamic raw){
    if(raw is! Map)return const SizedBox.shrink();
    final x=Map<String,dynamic>.from(raw);
    String val(dynamic v)=>v==null?'':v.toString();
    final title=val(x['title']).isNotEmpty?val(x['title']):val(x['name']).isNotEmpty?val(x['name']):val(x['detail']).isNotEmpty?val(x['detail']):val(x['type']).isNotEmpty?val(x['type']):'بيانات رياضية';
    final player=x['player'] is Map?x['player']['name']:null;
    final meta=[x['date'],x['time'],x['status'],x['league'],x['source'],player].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • ');
    return Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.4))),child:ListTile(leading:CircleAvatar(backgroundColor:Theme.of(context).colorScheme.primaryContainer,child:const Icon(Icons.sports)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:meta.isEmpty?null:Text(meta,maxLines:2,overflow:TextOverflow.ellipsis)));
  }
}
