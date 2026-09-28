import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenGamingTournamentScreen extends StatefulWidget { const AurenGamingTournamentScreen({super.key}); @override State<AurenGamingTournamentScreen> createState()=>_AurenGamingTournamentScreenState(); }
class _AurenGamingTournamentScreenState extends State<AurenGamingTournamentScreen>{
 final _api=AurenGameMultiplayer(); bool _loading=true; Map<String,dynamic>? _data; int _game=53;
 @override void initState(){super.initState();_load();}
 Future<void> _load() async { setState(()=>_loading=true); final d=await _api.getTournament(gameIndex:_game); if(mounted)setState(()=>{_data=d,_loading=false}); }
 @override Widget build(BuildContext context){
  final players=List<String>.from(_data?['players']??const <String>[]);
  return Scaffold(appBar:AppBar(title:const Text('🏆 AUREN Tournaments')),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
   DropdownButtonFormField<int>(value:_game,items:const [53,54,55,56,57,58,59].map((g)=>DropdownMenuItem(value:g,child:Text('Game'))).toList(),onChanged:(v){if(v!=null){setState(()=>_game=v);_load();}}),
   const SizedBox(height:16),Card(child:ListTile(title:Text('Tournament '+(_data?['tournamentId']?.toString()??'—')),subtitle:Text('Status: '+(_data?['status']?.toString()??'—')+' • '+players.length.toString()+'/'+(_data?['maxPlayers']??8).toString()+' players'))),
   const SizedBox(height:12),FilledButton.icon(onPressed:players.contains(_api.playerId)?null:()async{await _api.joinTournament(gameIndex:_game);_load();},icon:const Icon(Icons.login),label:const Text('Join Tournament')),
   OutlinedButton.icon(onPressed:players.contains(_api.playerId)?()async{await _api.leaveTournament(gameIndex:_game);_load();}:null,icon:const Icon(Icons.logout),label:const Text('Leave')),
   const SizedBox(height:12),const Text('Players',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
   for(var i=0;i<players.length;i++)ListTile(leading:CircleAvatar(child:Text((i+1).toString())),title:Text(players[i],maxLines:1,overflow:TextOverflow.ellipsis)),
  ])); } }