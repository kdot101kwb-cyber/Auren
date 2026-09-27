import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/entertainment.dart';
import '../../../services/content/content_platform_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import '../../entertainment/presentation/entertainment_detail_screen.dart';

class AurenContentPlatformScreen extends StatefulWidget {
  const AurenContentPlatformScreen({super.key});
  @override State<AurenContentPlatformScreen> createState()=>_AurenContentPlatformScreenState();
}
class _AurenContentPlatformScreenState extends State<AurenContentPlatformScreen>{
  String query='';
  String? selectedChannelId;
  @override Widget build(BuildContext context){
    final uid=FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar:AppBar(title:const Text('AUREN Content'),actions:[
        if(uid!=null) IconButton(icon:const Icon(Icons.add_box_outlined),tooltip:'نشر فيديو',onPressed:()=>_publish(uid)),
        if(uid!=null) IconButton(icon:const Icon(Icons.add_to_queue),tooltip:'إنشاء قناة',onPressed:()=>_createChannel(uid)),
        IconButton(icon:const Icon(Icons.auto_awesome),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const MessengerScreen(initialPrompt:'ساعدني أجد قنوات ومحتوى يناسب اهتماماتي في AUREN.'))))
      ]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن فيديو أو محتوى'),onChanged:(v)=>setState(()=>query=v))),
        SizedBox(height:52,child:StreamBuilder<List<AurenChannel>>(stream:AurenContentPlatformService.instance.watchChannels(),builder:(context,s){
          final channels=s.data??const <AurenChannel>[];
          return ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:channels.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){
            final c=channels[i];
            return FilterChip(label:Text(c.name),selected:selectedChannelId==c.id,onSelected:(_)=>setState(()=>selectedChannelId=selectedChannelId==c.id?null:c.id));
          });
        })),
        Expanded(child:StreamBuilder<List<AurenEntertainmentItem>>(stream:AurenContentPlatformService.instance.watchPublicVideos(query:query),builder:(context,s){
          if(s.hasError)return const Center(child:Text('تعذر تحميل المحتوى.'));
          if(!s.hasData)return const Center(child:CircularProgressIndicator());
          final videos=s.data!.where((v)=>selectedChannelId==null||v.channelId==selectedChannelId).toList();
          if(videos.isEmpty)return const Center(child:Text('لا توجد فيديوهات منشورة حالياً.'));
          return ListView.separated(padding:const EdgeInsets.all(16),itemCount:videos.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){
            final v=videos[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: v.imageUrl.isEmpty
                    ? const CircleAvatar(child: Icon(Icons.play_arrow))
                    : CircleAvatar(backgroundImage: NetworkImage(v.imageUrl)),
                title: Text(v.title),
                subtitle: Text('${v.type} • ${v.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.play_circle_fill),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AurenEntertainmentDetailScreen(itemId: v.id)),
                ),
              ),
            );
          });
        }))
      ])
    );
  }

  Future<void> _createChannel(String uid) async {
    final name=TextEditingController(), description=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('إنشاء قناة'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'اسم القناة')),TextField(controller:description,decoration:const InputDecoration(labelText:'الوصف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('إنشاء'))]));
    if(ok!=true)return;
    try{await AurenContentPlatformService.instance.createChannel(uid:uid,name:name.text,description:description.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء القناة 🔥')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }

  Future<void> _publish(String uid) async {
    final channels=await AurenContentPlatformService.instance.watchChannels().first;
    final mine=channels.where((c)=>c.ownerId==uid).toList();
    if(!mounted)return;
    if(mine.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أنشئ قناة أولاً.')));return;}
    final title=TextEditingController(),description=TextEditingController(),media=TextEditingController(),image=TextEditingController();
    String channelId=mine.first.id;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(title:const Text('نشر فيديو'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:channelId,items:mine.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name))).toList(),onChanged:(v){if(v!=null)setDialog(()=>channelId=v);},decoration:const InputDecoration(labelText:'القناة')),
      TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),TextField(controller:description,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:media,decoration:const InputDecoration(labelText:'رابط الفيديو MP4/M3U8')),TextField(controller:image,decoration:const InputDecoration(labelText:'رابط الصورة المصغرة'))
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),ElevatedButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('نشر'))])));
    if(ok!=true)return;
    try{await AurenContentPlatformService.instance.publishVideo(uid:uid,channelId:channelId,title:title.text,description:description.text,mediaUrl:media.text,imageUrl:image.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر الفيديو 🔥')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
}
