import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenGamingTournamentScreen extends StatefulWidget { const AurenGamingTournamentScreen({super.key}); @override State<AurenGamingTournamentScreen> createState()=>_AurenGamingTournamentScreenState(); }
class _AurenGamingTournamentScreenState extends State<AurenGamingTournamentScreen>{
 final _api=AurenGameMultiplayer(); bool _loading=true; String? _actionMessage; Map<String,dynamic>? _data; Map<String,dynamic>? _bracket; int _game=53;
 @override void didChangeDependencies(){super.didChangeDependencies(); final g=widget.initialGameIndex; if(g!=null && g>=53 && g<=59 && _game!=g){_game=g; _load();}}
 @override void initState(){super.initState();_load();}
 String _gameName(int g)=>const {53:'🕵️ Crime Files',54:'⚽ Football Pro',55:'🏀 Basketball Pro',56:'🥊 Boxing Champion',57:'⚔️ Wars',58:'🥷 Samurai Legacy',59:'🏎️ Street Racing'}[g]??'Game';
 Future<void> _load() async { setState(()=>_loading=true); final d=await _api.getTournament(gameIndex:_game); final b=await _api.getTournamentBracket(gameIndex:_game); if(mounted)setState(()=>{_data=d,_bracket=b,_loading=false}); }
 @override Widget build(BuildContext context){
  final players=List<String>.from(_data?['players']??const <String>[]);
  return Scaffold(appBar:AppBar(title:const Text('🏆 AUREN Tournaments')),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
   DropdownButtonFormField<int>(value:_game,items:const [53,54,55,56,57,58,59].map((g)=>DropdownMenuItem(value:g,child:Text(_gameName(g))).toList(),onChanged:(v){if(v!=null){setState(()=>_game=v);_load();}}),
   const SizedBox(height:16),Card(child:ListTile(title:Text('Tournament '+(_data?['tournamentId']?.toString()??'—')),subtitle:Text('Status: '+(_data?['status']?.toString()??'—')+' • '+players.length.toString()+'/'+(_data?['maxPlayers']??8).toString()+' players'))),
   const SizedBox(height:12),FilledButton.icon(onPressed:players.contains(_api.playerId)?null:()async{await _api.joinTournament(gameIndex:_game);_load();},icon:const Icon(Icons.login),label:const Text('Join Tournament')),
   OutlinedButton.icon(onPressed:players.contains(_api.playerId)?()async{await _api.leaveTournament(gameIndex:_game);_load();}:null,icon:const Icon(Icons.logout),label:const Text('Leave')),
   const SizedBox(height:12),if((_data?['status']=='bracket_ready') || (_data?['status']=='registration' && players.length>=2))FilledButton.icon(onPressed:()async{await _api.startTournament(gameIndex:_game);_load();},icon:const Icon(Icons.play_arrow),label:const Text('Start Tournament')),if(_bracket?['bracket']!=null)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('🏆 Bracket',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),...List<Widget>.from(((_bracket?['matches'] as List?)??const []).map((m)=>ListTile(title:Text('${m['p1']??'BYE'}  vs  ${m['p2']??'BYE'}'),subtitle:Text('${m['round']} • ${m['status']}'))))]))),if(_actionMessage!=null) Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(_actionMessage!,style:const TextStyle(fontWeight:FontWeight.bold))),const SizedBox(height:12),const Text('Players',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
   for(var i=0;i<players.length;i++)ListTile(leading:CircleAvatar(child:Text((i+1).toString())),title:Text(players[i],maxLines:1,overflow:TextOverflow.ellipsis)),
  ])); } }