import 'package:flutter/material.dart';
import '../../../core/models/agent_listing.dart';
import '../../../services/agents/agent_marketplace_repository.dart';
class AgentMarketplaceScreen extends StatelessWidget {
 const AgentMarketplaceScreen({super.key});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Agent Marketplace')),body:StreamBuilder<List<AurenAgentListing>>(stream:AurenAgentMarketplaceRepository().watchPublished(),builder:(context,snapshot){
 if(snapshot.hasError)return const Center(child:Text('تعذر تحميل الوكلاء'));
 if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
 final items=snapshot.data!;
 if(items.isEmpty)return const Center(child:Text('لا توجد Agents منشورة حالياً.'));
 return ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,i){
 final agent=items[i];
 return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.smart_toy)),title:Text(agent.name),subtitle:Text(agent.description+'\n'+agent.capabilities.join(' • ')),isThreeLine:true,trailing:Text(agent.pricingModel)));
 });
 }));
  }
}