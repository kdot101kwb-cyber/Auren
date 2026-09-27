import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/content/content_platform_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenContentPlatformScreen extends StatefulWidget {
  const AurenContentPlatformScreen({super.key});
  @override State<AurenContentPlatformScreen> createState()=>_AurenContentPlatformScreenState();
}
class _AurenContentPlatformScreenState extends State<AurenContentPlatformScreen>{
  String query='';
  @override void initState(){super.initState(); final uid=FirebaseAuth.instance.currentUser?.uid; if(uid!=null) AurenContentPlatformService.instance.ensureStarterChannels(uid);}
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar:AppBar(title:const Text('AUREN Content'),actions:[IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ساعدني أجد قنوات ومحتوى يناسب اهتماماتي في AUREN.'))))]),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن فيديو أو محتوى'),onChanged:(v)=>setState(()=>query=v))),Expanded(child:StreamBuilder<List<AurenEntertainmentItem>>(stream:AurenContentPlatformService.instance.watchPublicVideos(query:query),builder:(context,s){
      if(s.hasError)return const Center(child:Text('تعذر تحميل القنوات.'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final videos=s.data!; if(videos.isEmpty)return const Center(child:Text('لا توجد فيديوهات منشورة حالياً.'));
      return ListView.separated(padding:const EdgeInsets.all(16),itemCount:videos.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final v=videos[i];return Card(child:ListTile(leading:v.imageUrl.isEmpty?const CircleAvatar(child:Icon(Icons.play_arrow)):CircleAvatar(backgroundImage:NetworkImage(v.imageUrl)),title:Text(v.title),subtitle:Text(v.type+' • '+v.description,maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.play_circle_fill)));});});
  }
}