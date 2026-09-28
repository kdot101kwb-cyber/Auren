import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';
import 'auren_gaming_notifications_screen.dart';

class AurenGamingProfileScreen extends StatefulWidget {
  const AurenGamingProfileScreen({super.key});
  @override State<AurenGamingProfileScreen> createState() => _AurenGamingProfileScreenState();
}

class _AurenGamingProfileScreenState extends State<AurenGamingProfileScreen> {
  final _api = AurenGameMultiplayer();
  bool _season = false, _loading = true;
  Map<String,dynamic>? _profile, _gameStats;
  List<Map<String,dynamic>> _achievements = const []; List<Map<String,dynamic>> _seasonRewards = const [];
  int _gameIndex = 53;

  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    setState(()=>_loading=true);
    final r=await Future.wait([_api.getPlayerGamingProfile(season:_season),_api.getGamingAchievements(season:_season),_api.getGamingGameStats(gameIndex:_gameIndex,season:_season),_api.getGamingSeasonRewards()]);
    if(!mounted)return;
    setState((){_profile=r[0] as Map<String,dynamic>?;_achievements=r[1] as List<Map<String,dynamic>>;_gameStats=r[2] as Map<String,dynamic>?;_seasonRewards=r[3] as List<Map<String,dynamic>>;_loading=false;});
  }

  Future<void> _showTournamentHistory() async { final items=await _api.getTournamentHistory(); if(!mounted)return; showModalBottomSheet(context:context,builder:(_)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('🏆 Tournament History',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),if(items.isEmpty)const Text('لا توجد بطولات مسجلة بعد'),...items.map((x){final placement=(x['placement'] as num?)?.toInt()??0;return ListTile(leading:Text(placement==1?'🥇':placement==2?'🥈':'🏆',style:const TextStyle(fontSize:24)),title:Text('Game #${x['gameIndex']??'—'} • ${placement==1?'Champion':'Placement $placement'}'),subtitle:Text('+${x['coins']??0} coins • +${x['xp']??0} XP'));})])); }
  @override Widget build(BuildContext context){
    final p=_profile??const <String,dynamic>{};
    final games=const [(53,'Crime'),(54,'Football'),(55,'Basketball'),(56,'Boxing'),(57,'Wars'),(58,'Samurai'),(59,'Racing')];
    return Scaffold(appBar:AppBar(title:const Text('🎮 Gaming Profile'),actions:[IconButton(onPressed:(){setState(()=>_season=!_season);_load();},icon:Icon(_season?Icons.calendar_month:Icons.public))]),
      body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Player ${p['playerId']??'—'}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text('⭐ Rating ${p['rating']??1000} • 🏆 ${p['wins']??0} wins'),Text('🎮 ${p['matches']??0} matches • 📈 ${p['winRate']??0}% win rate')]))),
        const SizedBox(height:12),const Text('Game Stats',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Wrap(spacing:8,children:[for(final g in games)ChoiceChip(label:Text(g.$2),selected:_gameIndex==g.$1,onSelected:(_){setState(()=>_gameIndex=g.$1);_load();})]),
        if(_gameStats!=null)Card(child:ListTile(title:Text('Game $_gameIndex'),subtitle:Text('⭐ ${_gameStats!['rating']??1000} • 🏆 ${_gameStats!['wins']??0} • ❌ ${_gameStats!['losses']??0} • ➖ ${_gameStats!['draws']??0}'),trailing:Text('${_gameStats!['winRate']??0}%'))),
        const SizedBox(height:12),FilledButton.icon(onPressed:_showTournamentHistory,icon:const Icon(Icons.emoji_events),label:const Text('Tournament History')),FutureBuilder<List<Map<String,dynamic>>>(future:_api.getGamingNotifications(),builder:(context,s){final n=(s.data??const <Map<String,dynamic>>[]).where((x)=>x['readAt']==null).length;return FilledButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AurenGamingNotificationsScreen())).then((_)=>setState((){})),icon:Badge(isLabelVisible:n>0,label:Text(n>99?'99+':n.toString()),child:const Icon(Icons.notifications)),label:Text(n>0?'Gaming Notifications ($n)':'Gaming Notifications'));}),const SizedBox(height:12),const SizedBox(height:12),const Text('Match History',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),FutureBuilder<Map<String,dynamic>?>(future:_api.getGamingMatchHistory(),builder:(context,s){final raw=s.data?['history'];final hs=raw is List?List<Map<String,dynamic>>.from(raw.map((x)=>Map<String,dynamic>.from(x))):<Map<String,dynamic>>[];return Column(children:[for(final x in hs)ListTile(leading:const Icon(Icons.history),title:Text('Game '+(x['gameIndex']?.toString()??'—')),subtitle:Text('${x['wins']??0}W • ${x['losses']??0}L • ${x['draws']??0}D'),trailing:Text('${x['rating']??1000}'))]);}),const SizedBox(height:12),const SizedBox(height:12),const Text('Gaming Rivals',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),FutureBuilder<Map<String,dynamic>?>(future:_api.getGamingRivals(),builder:(context,s){final rs=List<Map<String,dynamic>>.from((s.data?['rivals'] as List?)??const []);return Column(children:[for(final x in rs.take(5))ListTile(leading:CircleAvatar(child:Text(x['rating']?.toString()??'1000')),title:Text('Game '+(x['gameIndex']?.toString()??'—')),subtitle:Text((x['wins']?.toString()??'0')+' wins • '+(x['matches']?.toString()??'0')+' matches'))]);}),const SizedBox(height:12),const SizedBox(height:12),const Text('Season Champion 🏆',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),FutureBuilder<Map<String,dynamic>?>(future:_api.getSeasonChampion(gameIndex:_gameIndex),builder:(context,s)=>Text(s.data?['champion']==null?'No champion yet':'Champion: ${s.data?['champion']}')),const SizedBox(height:12),const Text('Season Rewards',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),for(final r in _seasonRewards)Card(child:ListTile(leading:Icon(r['claimed']==true?Icons.check_circle:Icons.card_giftcard),title:Text('Rank ${r['rank']??'—'} • ${r['reward']??0} Coins'),subtitle:Text('${r['seasonId']??''} • Game ${r['gameIndex']??''}'),trailing:r['claimed']==true?const Text('Claimed'):TextButton(onPressed:()async{if(await _api.claimGamingSeasonReward(r['id'].toString()))_load();},child:const Text('Claim')))),const SizedBox(height:12),Text('Achievements' ${_achievements.where((x)=>x['unlocked']==true).length}/${_achievements.length}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        for(final a in _achievements)Card(child:ListTile(leading:Icon(a['unlocked']==true?Icons.emoji_events:Icons.lock_outline),title:Text(a['title']?.toString()??'Achievement'),subtitle:Text('${a['description']??''} ${a['progress']??0}/${a['target']??1}'))),
      ])));
  }
}