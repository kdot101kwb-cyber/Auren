import 'package:flutter/material.dart';
class AurenNotificationsScreen extends StatelessWidget {
 const AurenNotificationsScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Notifications')),body:ListView(children:const [
 ListTile(leading:Icon(Icons.auto_awesome),title:Text('AUREN AI'),subtitle:Text('Your daily suggestions are ready.')),
 ListTile(leading:Icon(Icons.people),title:Text('Social'),subtitle:Text('New activity from your network.')),
 ListTile(leading:Icon(Icons.work_outline),title:Text('Opportunities'),subtitle:Text('New matches may be available.')),
 ])); 
}