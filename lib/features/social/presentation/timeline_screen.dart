import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../services/social/post_repository.dart';
class AurenTimelineScreen extends StatelessWidget {
 const AurenTimelineScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AUREN Pulse')),body:StreamBuilder<List<AurenPost>>(
 stream:PostRepository().watchFeed(),builder:(context,s){if(s.hasError)return Center(child:Text('Could not load Pulse: ${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());final posts=s.data!;if(posts.isEmpty)return const Center(child:Text('ابدأ أول Pulse في AUREN'));return ListView.separated(padding:const EdgeInsets.all(12),itemCount:posts.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(c,i){final p=posts[i];return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.authorId,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(p.text),const SizedBox(height:12),Row(children:[IconButton(onPressed:(){},icon:const Icon(Icons.favorite_border)),Text('${p.likes}'),const SizedBox(width:16),const Icon(Icons.comment_outlined),const SizedBox(width:4),Text('${p.comments}')])])));}}));}
}