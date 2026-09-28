import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenGamingProfileScreen extends StatefulWidget {
  const AurenGamingProfileScreen({super.key});
  @override State<AurenGamingProfileScreen> createState() => _AurenGamingProfileScreenState();
}

class _AurenGamingProfileScreenState extends State<AurenGamingProfileScreen> {
  final _api = AurenGameMultiplayer();
  bool _season = false, _loading = true;
  Map<String,dynamic>? _profile, _gameStats;
  List<Map<String,dynamic>> _achievements = const [];
  int _gameIndex = 53;

  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    setState(()=>_loading=true);
    final r=await Future.wait([_api.getPlayerGamingProfile(season:_season),_api.getGamingAchievements(season:_season),_api.getGamingGameStats(gameIndex:_gameIndex,season:_season)]);
    if(!mounted)return;
    setState(()=>({_profile=r[0] as Map<String,dynamic>?,_achievements=r[1] as List<Map<String,dynamic>>,_gameStats=r[2] as Map<String,dynamic>?,_loading=false});
  }
  @override Widget build(BuildContext context){
    final p=_profile??const <String,dynamic>{};
    final games=const [(53,'Crime'),(54,'Football'),(55,'Basketball'),(56,'Boxing'),(57,'Wars'),(58,'Samurai'),(59,'Racing')];
    return Scaffold(appBar:AppBar(title:const Text('🎮 Gaming Profile'),actions:[IconButton(onPressed:(){setState(()=>_season=!_season);_load();},icon:Icon(_season?Icons.calendar_month:Icons.public))]),
      body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Player ${p['playerId']??'—'}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:12),Text('⭐ Rating ${p['rating']??1000} • 🏆 ${p['wins']??0} wins'),Text('🎮 ${p['matches']??0} matches • 📈 ${p['winRate']??0}% win rate')]))),
        const SizedBox(height:12),const Text('Game Stats',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Wrap(spacing:8,children:[for(final g in games)ChoiceChip(label:Text(g.$2),selected:_gameIndex==g.$1,onSelected:(_){setState(()=>_gameIndex=g.$1);_load();})]),
        if(_gameStats!=null)Card(child:ListTile(title:Text('Game $_gameIndex'),subtitle:Text('⭐ ${_gameStats!['rating']??1000} • 🏆 ${_gameStats!['wins']??0} • ❌ ${_gameStats!['losses']??0} • ➖ ${_gameStats!['draws']??0}'),trailing:Text('${_gameStats!['winRate']??0}%'))),
        const SizedBox(height:12),Text('Achievements ${_achievements.where((x)=>x['unlocked']==true).length}/${_achievements.length}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        for(final a in _achievements)Card(child:ListTile(leading:Icon(a['unlocked']==true?Icons.emoji_events:Icons.lock_outline),title:Text(a['title']?.toString()??'Achievement'),subtitle:Text('${a['description']??''} ${a['progress']??0}/${a['target']??1}'))),
      ])));
  }
}