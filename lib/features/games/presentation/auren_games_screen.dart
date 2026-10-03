import 'dart:math';
import 'package:flutter/material.dart';
import '../../../services/gaming/auren_games_catalog.dart';

class AurenGamesScreen extends StatefulWidget {
  const AurenGamesScreen({super.key});
  @override State<AurenGamesScreen> createState() => _AurenGamesScreenState();
}

class _AurenGamesScreenState extends State<AurenGamesScreen> {
  String query = '';
  List<AurenGameDefinition> get games => AurenGamesCatalog.all.where((g) {
    final q=query.trim().toLowerCase();
    return q.isEmpty || ('${g.title} ${g.subtitle}').toLowerCase().contains(q);
  }).toList();

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Games'), actions: [
      IconButton(onPressed: () => showSearch(context: context, delegate: _GameSearchDelegate()), icon: const Icon(Icons.search)),
    ]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('AUREN Gaming', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${AurenGamesCatalog.all.length} لعبة • Multiplayer-ready • Achievements • Wins • Ranking',
          style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        const Text('العالم الرئيسي: AUREN: Lost World — مغامرة أصلية مستوحاة من فكرة ألعاب المغامرة داخل عالم غامض، وليست نسخة من أي عمل آخر.'),
      ]))),
      const SizedBox(height: 12),
      TextField(onChanged:(v)=>setState(()=>query=v), decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'ابحث عن لعبة', border:OutlineInputBorder())),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap:true, physics:const NeverScrollableScrollPhysics(), itemCount:games.length,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.05),
        itemBuilder:(context,i){final g=games[i];return Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>AurenGameRoom(game:g))),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(g.icon,size:34),const SizedBox(height:10),Text(g.title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),const SizedBox(height:5),Text(g.subtitle,maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:8),const Text('PLAY ›')]))));},
      )
    ]),
  );
}

class AurenGameRoom extends StatefulWidget {
  final AurenGameDefinition game;
  const AurenGameRoom({super.key,required this.game});
  @override State<AurenGameRoom> createState()=>_AurenGameRoomState();
}
class _AurenGameRoomState extends State<AurenGameRoom> {
  final rng=Random();
  int score=0, turns=0, position=0, energy=3;
  final List<String> log=[];
  void action(){
    final roll=rng.nextInt(6)+1;
    setState(() {
      turns++;
      if(widget.game.id=='lost_world'){
        position=min(100,position+roll);
        score += roll*10;
        energy=max(0,energy-(roll==1?1:0));
        log.insert(0,'🎲 $roll — وصلت إلى $position% من الرحلة');
        if(position>=100) log.insert(0,'🏆 انتهت الرحلة! الكنز لك.');
      } else {
        score += roll*10;
        log.insert(0,'🎲 $roll — +${roll*10} نقطة');
      }
      if(log.length>6) log.removeLast();
    });
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.game.title)),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      Icon(widget.game.icon,size:70),
      const SizedBox(height:12),
      Text(widget.game.title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:8),
      Text(widget.game.subtitle,textAlign:TextAlign.center),
      const SizedBox(height:24),
      if(widget.game.id=='lost_world') ...[
        LinearProgressIndicator(value:position/100,minHeight:12),
        const SizedBox(height:10),
        Text('التقدم: $position% • الطاقة: $energy',textAlign:TextAlign.center),
        const SizedBox(height:20),
        const Text('كل رمية تغيّر الطريق. واجه أحداثًا عشوائية، اجمع الموارد، وأنهِ الرحلة قبل نفاد الطاقة.',textAlign:TextAlign.center),
      ] else
        const Text('نسخة لعب أولية تعمل محليًا الآن. نظام المباريات والنتائج والترتيب يمكن ربطه بالخادم دون تغيير واجهة اللعبة.',textAlign:TextAlign.center),
      const SizedBox(height:24),
      FilledButton.icon(onPressed:action,icon:const Icon(Icons.casino),label:Text(widget.game.id=='lost_world'?'ارمِ النرد وواصل المغامرة':'ابدأ الجولة')),
      const SizedBox(height:18),
      Text('Score: $score • Turns: $turns',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      ...log.map((e)=>ListTile(leading:const Icon(Icons.bolt),title:Text(e))),
    ]),
  );
}

class _GameSearchDelegate extends SearchDelegate<AurenGameDefinition?> {
  @override List<Widget>? buildActions(BuildContext context)=>[IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear))];
  @override Widget? buildLeading(BuildContext context)=>IconButton(onPressed:()=>close(context,null),icon:const Icon(Icons.arrow_back));
  @override Widget buildResults(BuildContext context)=>_results();
  @override Widget buildSuggestions(BuildContext context)=>_results();
  Widget _results()=>ListView(children:AurenGamesCatalog.all.where((g)=>('${g.title} ${g.subtitle}').toLowerCase().contains(query.toLowerCase())).map((g)=>ListTile(leading:Icon(g.icon),title:Text(g.title),subtitle:Text(g.subtitle),onTap:()=>close(context,g))).toList());
}
