import 'package:flutter/material.dart';
import '../../../services/social/match_everything_service.dart';

class AurenContentDetailScreen extends StatelessWidget {
  final AurenMatchItem item;
  final String intent;
  const AurenContentDetailScreen({super.key,required this.item,required this.intent});

  @override Widget build(BuildContext context) {
    final d=item.data;
    final author=(d['authorName']??d['displayName']??d['creatorName'])?.toString()??'';
    final text=(d['text']??d['description']??d['caption'])?.toString()??'';
    return Scaffold(
      appBar:AppBar(title:const Text('Content')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Icon(Icons.play_circle_outline,size:44),const SizedBox(height:12),
          Text(item.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          if(author.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(author)),
          const SizedBox(height:14),Text(text.isEmpty?'لا يوجد وصف متاح.':text),
        ]))),
        if(intent.trim().isNotEmpty)Card(child:ListTile(leading:const Icon(Icons.search),title:const Text('طلبك'),subtitle:Text(intent))),
        if(item.reasons.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('سبب المطابقة',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),
          ...item.reasons.map((x)=>Padding(padding:const EdgeInsets.only(bottom:6),child:Text('• $x')))
        ]))),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فتح المشاهدة المباشرة سيُربط بوحدة المحتوى.'))),icon:const Icon(Icons.play_arrow),label:const Text('فتح المحتوى')),
      ])
    );
  }
}