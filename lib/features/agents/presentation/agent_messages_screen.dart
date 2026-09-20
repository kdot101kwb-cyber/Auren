import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agents/agent_message_repository.dart';
class AgentMessagesScreen extends StatelessWidget {
 const AgentMessagesScreen({super.key});
 @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;if(uid==null)return const Scaffold(body:Center(child:Text('يجب تسجيل الدخول.')));return DefaultTabController(length:2,child:Scaffold(appBar:AppBar(title:const Text('Agent Messages'),bottom:const TabBar(tabs:[Tab(text:'الوارد'),Tab(text:'المرسل')])),body:TabBarView(children:[_list(AurenAgentMessageRepository().watchInbox(uid)),_list(AurenAgentMessageRepository().watchSent(uid))])));}
 Widget _list(Stream<List<Map<String,dynamic>>> stream)=>StreamBuilder<List<Map<String,dynamic>>>(stream:stream,builder:(context,s){final items=s.data??const [];if(items.isEmpty)return const Center(child:Text('لا توجد رسائل Agents.'));return ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.smart_toy_outlined)),title:Text(items[i]['type']?.toString()??'agent.message'),subtitle:Text((items[i]['payload'] as Map?)?.toString()??''),));});
}
