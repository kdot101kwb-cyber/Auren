import 'package:flutter/material.dart';
import '../data/auren_game_multiplayer.dart';

class AurenGamingNotificationsScreen extends StatefulWidget {
  const AurenGamingNotificationsScreen({super.key});
  @override State<AurenGamingNotificationsScreen> createState()=>_AurenGamingNotificationsScreenState();
}
class _AurenGamingNotificationsScreenState extends State<AurenGamingNotificationsScreen>{
 final _api=AurenGameMultiplayer(); bool _loading=true; List<Map<String,dynamic>> _items=[];
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{setState(()=>_loading=true);final items=await _api.getGamingNotifications();if(!mounted)return;setState((){_items=items;_loading=false;});}
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('🔔 Gaming Notifications')),
  body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
   onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
    if(_items.isEmpty)const ListTile(title:const Text('No gaming notifications yet.')),
    for(final x in _items)Card(child:ListTile(
     leading:const Icon(Icons.emoji_events),
     title:Text('Season Reward • Rank '+(x['rank']?.toString()??'—')),
     subtitle:Text((x['reward']?.toString()??'0')+' Coins'),
     trailing:Icon(x['claimed']==true?Icons.check_circle:Icons.card_giftcard),
    )),
   ]),
  ),
 );
}