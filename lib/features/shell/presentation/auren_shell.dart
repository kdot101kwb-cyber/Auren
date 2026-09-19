import 'package:flutter/material.dart';
import '../../home/presentation/auren_home_v2.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../messenger/presentation/conversation_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../social/presentation/create_post_screen.dart';

class AurenShell extends StatefulWidget {
  const AurenShell({super.key});
  @override State<AurenShell> createState()=>_AurenShellState();
}
class _AurenShellState extends State<AurenShell>{
 int index=0;
 final pages=const[
   AurenHomeV2(),
   AurenTimelineScreen(),
   AurenDiscoverScreen(),
   AurenConversationListScreen(),
   AurenProfileScreen(),
 ];
 @override Widget build(BuildContext context)=>Scaffold(
   body:IndexedStack(index:index,children:pages),
   floatingActionButton:index==1?FloatingActionButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenCreatePostScreen())),child:const Icon(Icons.add)):null,
   bottomNavigationBar:NavigationBar(
     selectedIndex:index,
     onDestinationSelected:(i)=>setState(()=>index=i),
     destinations:const[
       NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
       NavigationDestination(icon:Icon(Icons.dynamic_feed_outlined),selectedIcon:Icon(Icons.dynamic_feed),label:'Pulse'),
       NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore),label:'Discover'),
       NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'Messenger'),
       NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile'),
     ],
   ),
 );
}