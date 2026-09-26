import 'package:flutter/material.dart';
import '../../../services/social/match_everything_service.dart';

class AurenOpportunityDetailScreen extends StatelessWidget {
  final AurenMatchItem item;
  final String intent;
  const AurenOpportunityDetailScreen({super.key,required this.item,required this.intent});

  @override Widget build(BuildContext context) {
    final d=item.data;
    final location=[d['city'],d['country']].where((x)=>x!=null&&x.toString().trim().isNotEmpty).join(' • ');
    final type=(d['type']??d['category'])?.toString()??'Opportunity';
    return Scaffold(
      appBar:AppBar(title:const Text('Opportunity')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Icon(Icons.radar,size:40),const SizedBox(height:12),
          Text(item.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          if(item.subtitle.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(item.subtitle)),
          const SizedBox(height:14),Chip(label:Text(type)),
          if(location.isNotEmpty)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.location_on_outlined),title:const Text('الموقع'),subtitle:Text(location)),
        ]))),
        if(intent.trim().isNotEmpty)Card(child:ListTile(leading:const Icon(Icons.search),title:const Text('طلبك'),subtitle:Text(intent))),
        if(item.reasons.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('سبب المطابقة',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:8),
          ...item.reasons.map((x)=>Padding(padding:const EdgeInsets.only(bottom:6),child:Text('• $x')))
        ]))),
        if((d['description']??d['text'])!=null)Card(child:Padding(padding:const EdgeInsets.all(16),child:Text((d['description']??d['text']).toString()))),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ اهتمامك بالفرصة. سنربط التقديم المباشر عند تفعيل نموذج التقديم.'))),icon:const Icon(Icons.arrow_forward),label:const Text('متابعة الفرصة')),
      ])
    );
  }
}