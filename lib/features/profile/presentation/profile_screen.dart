import 'package:flutter/material.dart';
class AurenProfileScreen extends StatelessWidget {
 const AurenProfileScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(padding:const EdgeInsets.all(20),children:[
 const CircleAvatar(radius:42,child:Icon(Icons.person,size:42)),const SizedBox(height:16),
 const Text('AUREN User',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const Text('Connect. Create. Achieve.'),
 const SizedBox(height:24),
 Card(child:ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('AI Profile'),subtitle:const Text('Let AUREN adapt your profile to your goals.'))),
 Card(child:ListTile(leading:const Icon(Icons.tune),title:const Text('Profile Modes'),subtitle:const Text('Personal • Creator • Professional • Business'))),
 Card(child:ListTile(leading:const Icon(Icons.people_outline),title:const Text('Social Graph'),subtitle:const Text('Followers, following and communities'))),
 ])); 
}