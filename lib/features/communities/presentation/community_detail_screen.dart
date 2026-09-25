import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/community_service.dart';
import '../../../services/social/post_repository.dart';

class AurenCommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const AurenCommunityDetailScreen({super.key, required this.communityId});
  @override State<AurenCommunityDetailScreen> createState()=>_AurenCommunityDetailScreenState();
}
class _AurenCommunityDetailScreenState extends State<AurenCommunityDetailScreen>{
  final service=AurenCommunityService(); final repo=PostRepository(); final auth=FirebaseAurenAuthService();
  Future<void> _compose(AurenCommunity c) async {
    final text=TextEditingController(); String type='moment';
    final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(
      title:Text('نشر في ${c.name}'),
      content:SingleChildScrollView(child:Column(children:[
        DropdownButtonFormField<String>(value:type,items:const[DropdownMenuItem(value:'moment',child:Text('Moment')),DropdownMenuItem(value:'question',child:Text('Question')),DropdownMenuItem(value:'idea',child:Text('Idea')),DropdownMenuItem(value:'project',child:Text('Project'))],onChanged:(v){if(v!=null)setLocal(()=>type=v);},decoration:const InputDecoration(labelText:'النوع')),
        const SizedBox(height:10),TextField(controller:text,maxLines:6,maxLength:2200,decoration:const InputDecoration(hintText:'اكتب شيئاً للمجتمع…',border:OutlineInputBorder()))
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('نشر'))],
    )));
    final value=text.text.trim(); text.dispose(); if(result!=true||value.isEmpty)return;
    final uid=auth.currentUserId; if(uid==null)return;
    await repo.createCommunityPost(AurenPost(id:'post_${DateTime.now().microsecondsSinceEpoch}',authorId:uid,text:value,contentType:type,contextLabel:'Community • ${c.name}',communityId:c.id,createdAt:DateTime.now()));
  }
  @override Widget build(BuildContext context)=>StreamBuilder<AurenCommunity?>(
    stream:service.watch(widget.communityId),builder:(context,s){final c=s.data;if(!s.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));if(c==null)return const Scaffold(body:Center(child:Text('المجتمع غير موجود.')));final uid=auth.currentUserId;final joined=uid!=null&&c.memberIds.contains(uid);
      return Scaffold(appBar:AppBar(title:Text(c.name)),floatingActionButton:joined?FloatingActionButton.extended(onPressed:()=>_compose(c),icon:const Icon(Icons.edit),label:const Text('نشر')):null,
        body:ListView(padding:const EdgeInsets.all(16),children:[
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.topic.isEmpty?'Community':c.topic,style:Theme.of(context).textTheme.labelLarge),const SizedBox(height:6),Text(c.description.isEmpty?'لا يوجد وصف.':c.description),const SizedBox(height:10),Text('${c.memberCount} عضو'),if(!joined)const Padding(padding:EdgeInsets.only(top:8),child:Text('انضم للمجتمع حتى تقدر تنشر.'))]))),
          const SizedBox(height:12),
          StreamBuilder<List<AurenPost>>(stream:repo.watchCommunityFeed(c.id),builder:(context,p){if(p.hasError)return Text('تعذر تحميل المنشورات: ${p.error}');if(!p.hasData)return const Center(child:CircularProgressIndicator());if(p.data!.isEmpty)return const Card(child:Padding(padding:EdgeInsets.all(24),child:Text('لسه ما في منشورات. كن أول شخص ينشر.')));return Column(children:p.data!.map((post)=>Card(margin:const EdgeInsets.only(bottom:10),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(post.contentType.toUpperCase(),style:Theme.of(context).textTheme.labelSmall),const SizedBox(height:6),Text(post.text),const SizedBox(height:8),Text('${post.authorId} • ${post.likes} reactions',style:Theme.of(context).textTheme.bodySmall)])))).toList());})
        ]));
    });
}
