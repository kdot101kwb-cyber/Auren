import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../home/presentation/auren_home_v2.dart';
import '../../social/presentation/timeline_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../messenger/presentation/conversation_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../social/presentation/create_post_screen.dart';
import '../../social/presentation/random_call_screen.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/random_call_service.dart';
import '../../../services/social/notification_service.dart';
import '../../notifications/presentation/notification_center_screen.dart';
import '../../education/presentation/education_screen.dart';

class AurenShell extends StatefulWidget{const AurenShell({super.key});@override State<AurenShell> createState()=>_AurenShellState();}
class _AurenShellState extends State<AurenShell>{
 int index=0; final pages=const[AurenHomeV2(),AurenTimelineScreen(),AurenDiscoverScreen(),AurenConversationListScreen(),AurenProfileScreen()];
 final auth=FirebaseAurenAuthService(),callService=AurenRandomCallService(),notificationService=AurenNotificationService(); StreamSubscription<QuerySnapshot<Map<String,dynamic>>>? incomingSub; final Set<String> handledIncomingCalls=<String>{};
 @override void initState(){super.initState();_listenForIncomingCalls();}
 void _listenForIncomingCalls(){final uid=auth.currentUserId;if(uid==null)return;incomingSub=FirebaseFirestore.instance.collection('random_calls').where('calleeUid',isEqualTo:uid).limit(20).snapshots().listen((snapshot){for(final change in snapshot.docChanges){if(change.type==DocumentChangeType.removed)continue;final data=change.doc.data();if(data==null||data['status']!='ringing'||handledIncomingCalls.contains(change.doc.id))continue;handledIncomingCalls.add(change.doc.id);_showIncomingCall(change.doc.id,data);}});}
 Future<void> _showIncomingCall(String callId,Map<String,dynamic> data)async{if(!mounted)return;final kind=data['kind'] as String? ?? 'video';final accepted=await showDialog<bool>(context:context,barrierDismissible:false,builder:(context)=>AlertDialog(title:Text(kind=='video'?'مكالمة فيديو واردة':'مكالمة صوتية واردة'),content:const Text('مكالمة عشوائية واردة من مستخدم AUREN'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('رفض')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('قبول'))]));if(!mounted)return;if(accepted==true){await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>AurenRandomCallScreen(callId:callId,caller:false,kind:kind,otherName:'AUREN User')));}else{try{await callService.end(callId,auth.currentUserId??'unknown');}catch(_){}}}
 @override void dispose(){incomingSub?.cancel();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(body:Stack(children:[IndexedStack(index:index,children:pages),Positioned(top:8,right:12,child:SafeArea(child:StreamBuilder<int>(stream:auth.currentUserId==null?const Stream<int>.empty():notificationService.watchUnreadCount(auth.currentUserId!),builder:(context,snapshot){final count=snapshot.data??0;return Material(color:Theme.of(context).colorScheme.surface.withOpacity(.92),shape:const CircleBorder(),child:InkWell(customBorder:const CircleBorder(),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenNotificationCenterScreen())),child:SizedBox(width:48,height:48,child:Stack(alignment:Alignment.center,children:[const Icon(Icons.notifications_outlined),if(count>0)Positioned(right:4,top:3,child:Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration:BoxDecoration(color:Theme.of(context).colorScheme.error,borderRadius:BorderRadius.circular(10)),child:Text(count>99?'99+':'$count',style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))))]))));}))),]),floatingActionButton:index==1?FloatingActionButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AurenCreatePostScreen())),child:const Icon(Icons.add)):null,bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.dynamic_feed_outlined),selectedIcon:Icon(Icons.dynamic_feed),label:'Pulse'),NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore),label:'Discover'),NavigationDestination(icon:Icon(Icons.chat_bubble_outline),selectedIcon:Icon(Icons.chat_bubble),label:'Messenger'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile')]));
}
