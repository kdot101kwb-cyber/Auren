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
  List<Map<String,dynamic>> related=[];
  bool loading=false;
  String tab='overview';

  Future<void> load(String resource) async {
    setState(()=>loading=true);
    try {
      final r=await FirebaseFunctions.instance.httpsCallable('searchAurenSports').call({
        'sport':widget.sport,'resource':resource,
        'leagueId':widget.data['id']?.toString()??'',
        'season':widget.data['season']?.toString()??'',
        'query':widget.data['name']?.toString()??widget.data['title']?.toString()??''
      });
      final m=Map<String,dynamic>.from(r.data as Map);
      if(m['status']=='ok' && mounted) setState(()=>related=List<Map<String,dynamic>>.from(m['results']??const []));
    } catch (_) {} finally { if(mounted)setState(()=>loading=false); }
  }

  @override void initState(){super.initState(); load('games');}

  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    final title=(widget.data['name']??widget.data['title']??'Sports').toString();
    final subtitle=[widget.data['country'],widget.data['season'],widget.data['source']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' • ');
    return Scaffold(
      body: CustomScrollView(slivers:[
        SliverAppBar.large(
          pinned:true,
          expandedHeight:230,
          title:Text(title,maxLines:1,overflow:TextOverflow.ellipsis),
          flexibleSpace:FlexibleSpaceBar(background:Container(
            decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[cs.primary,cs.secondary])),
            padding:const EdgeInsets.fromLTRB(20,110,20,20),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(title,style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),
              if(subtitle.isNotEmpty) Text(subtitle,style:TextStyle(color:Colors.white.withValues(alpha:.82)))
            ]),
          )),
        ),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Wrap(spacing:8,runSpacing:8,children:[
          _tab('overview','نظرة عامة',Icons.auto_awesome),
          _tab('games','المباريات',Icons.flash_on),
          _tab('teams','الفرق',Icons.groups),
          _tab('standings','الترتيب',Icons.leaderboard),
          _tab('players','اللاعبون',Icons.person),
        ]))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),child:Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(tab=='overview'?'ملخص سريع':tab=='games'?'المباريات':tab=='teams'?'الفرق':tab=='standings'?'الترتيب':'اللاعبون',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
          const SizedBox(height:12),
          if(loading) const Center(child:Padding(padding:EdgeInsets.all(20),child:CircularProgressIndicator()))
          else if(related.isEmpty) const Text('لا توجد بيانات متاحة حاليًا من المصدر لهذا القسم.')
          else ...related.take(20).map((x)=>_item(x)),
        ])))),
        const SliverToBoxAdapter(child:SizedBox(height:30))
      ])
    );
  }

  Widget _tab(String value,String label,IconData icon)=>ChoiceChip(avatar:Icon(icon,size:16),label:Text(label),selected:tab==value,onSelected:(_){setState(()=>tab=value);load(value=='games'||value=='overview'?'games':value=='teams'?'teams':value=='standings'?'standings':'players');});

  Widget _item(Map<String,dynamic> x){
    final title=(x['title']??x['name']??x['teams']??'بيانات رياضية').toString();
    final meta=[x['league'],x['country'],x['date'],x['status'],x['source']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' • ');
    return Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.45))),child:ListTile(leading:CircleAvatar(backgroundColor:Theme.of(context).colorScheme.primaryContainer,child:const Icon(Icons.sports)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:meta.isEmpty?null:Text(meta,maxLines:2,overflow:TextOverflow.ellipsis)));
  }
}
