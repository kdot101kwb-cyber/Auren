import 'package:flutter/material.dart';
class AurenDiscoverScreen extends StatelessWidget {
 const AurenDiscoverScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Discover')),body:GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(16),crossAxisSpacing:12,mainAxisSpacing:12,children:const [
 Card(child:Center(child:Text('People'))),Card(child:Center(child:Text('Places'))),Card(child:Center(child:Text('Creators'))),Card(child:Center(child:Text('Business'))),Card(child:Center(child:Text('Entertainment'))),Card(child:Center(child:Text('Opportunities'))),
 ])); 
}