import 'package:flutter/material.dart';
import '../../../core/models/agent_listing.dart';
import '../../../services/agents/agent_review_repository.dart';
class AgentReviewsSheet extends StatelessWidget {
 final AurenAgentListing agent; const AgentReviewsSheet({super.key,required this.agent});
 @override Widget build(BuildContext context)=>StreamBuilder(
  stream:AurenAgentReviewRepository().watch(agent.agentId),
  builder:(context,snapshot){ final reviews=snapshot.data??const [];
   return SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:Row(children:[Expanded(child:Text('Reviews • '+agent.name,style:Theme.of(context).textTheme.titleLarge)),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close))])),
    Expanded(child:reviews.isEmpty?const Center(child:Text('لا توجد مراجعات بعد.')):ListView.separated(itemCount:reviews.length,padding:const EdgeInsets.all(16),separatorBuilder:(_,__)=>const Divider(),itemBuilder:(_,i)=>ListTile(leading:CircleAvatar(child:Text(reviews[i].rating.toString())),title:Text(reviews[i].text),subtitle:Text('تقييم '+reviews[i].rating.toString()+'/5'))))
   ]));
  });
}
