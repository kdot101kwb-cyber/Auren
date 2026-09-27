import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/content/content_platform_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenContentPlatformScreen extends StatefulWidget {
  const AurenContentPlatformScreen({super.key});
  @override State<AurenContentPlatformScreen> createState()=>_AurenContentPlatformScreenState();
}
class _AurenContentPlatformScreenState extends State<AurenContentPlatformScreen>{
  @override void initState(){super.initState(); final uid=FirebaseAuth.instance.currentUser?.uid; if(uid!=null) AurenContentPlatformService.instance.ensureStarterChannels(uid);}
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar:AppBar(title:const Text('AUREN Content'),actions:[IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ساعدني أجد قنوات ومحتوى يناسب اهتماماتي في AUREN.'))))]),body:StreamBuilder<List<AurenChannel>>(stream:AurenContentPlatformService.instance.watchChannels(),builder:(context,s){
      if(s.hasError)return const Center(child:Text('تعذر تحميل القنوات.'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final channels=s.data!; if(channels.isEmpty)return const Center(child:Text('لا توجد قنوات منشورة حالياً.'));
      return ListView.separated(padding:const EdgeInsets.all(16),itemCount:channels.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final c=channels[i];return Card(child:ListTile(leading:CircleAvatar(child:Text(c.name.isEmpty?'A':c.name[0].toUpperCase())),title:Text(c.name),subtitle:Text(c.description,maxLines:2,overflow:TextOverflow.ellipsis),trailing:uid==null?null:StreamBuilder<bool>(stream:AurenContentPlatformService.instance.watchSubscribed(uid,c.id),builder:(context,x)=>TextButton(onPressed:()=>AurenContentPlatformService.instance.subscribe(uid,c.id,!(x.data??false)),child:Text((x.data??false)?'مشترك':'اشتراك'))));});});
  }
}