import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../services/talent/talent_discovery_service.dart';
import '../../messenger/presentation/messenger_screen.dart';
import 'talent_agent_workflow_screen.dart';

class TalentOpportunityMatchesScreen extends StatefulWidget {
  final AurenTalent talent;
  const TalentOpportunityMatchesScreen({super.key,required this.talent});
  @override State<TalentOpportunityMatchesScreen> createState()=>_TalentOpportunityMatchesScreenState();
}
class _TalentOpportunityMatchesScreenState extends State<TalentOpportunityMatchesScreen>{
  late Future<List<AurenTalentMatch>> _future;
  @override void initState(){super.initState();_future=TalentDiscoveryService().matchOpportunities(widget.talent);}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Talent Matches')),
    body:FutureBuilder<List<AurenTalentMatch>>(
      future:_future,
      builder:(context,s){
        if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
        if(s.hasError)return Center(child:Text('تعذر تحميل المطابقات: ${s.error}'));
        final items=s.data??const <AurenTalentMatch>[];
        if(items.isEmpty)return const Center(child:Text('لا توجد مطابقة موثقة حالياً. أضف أدلة، ثم اطلب توثيق المهارات وجرب لاحقاً.'));
        return ListView.builder(
          padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(context,i){
            final m=items[i];
            return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[Expanded(child:Text(m.opportunity.title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold))),Text('${m.score}%')]),
              const SizedBox(height:8),Text(m.opportunity.description),
              const SizedBox(height:10),Text('المهارات الموثقة المتطابقة: '+(m.matchedSkills.isEmpty?'لا توجد':m.matchedSkills.join(' • '))),
              if(m.missingSkills.isNotEmpty)Text('مهارات مطلوبة إضافية: '+m.missingSkills.join(' • ')),
              const SizedBox(height:10),
              Wrap(alignment:WrapAlignment.end,spacing:8,runSpacing:8,children:[FilledButton.icon(
                icon:const Icon(Icons.auto_awesome),label:const Text('ابدأ خطة الوكلاء'),
                onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TalentAgentWorkflowScreen(talent:widget.talent,match:m))),
              ),FilledButton.icon(
                icon:const Icon(Icons.chat_outlined),label:const Text('حللها مع AUREN'),
                onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:
                  'حلل هذه الفرصة للموهبة: ${m.opportunity.title}. المهارات المتطابقة: ${m.matchedSkills.join(', ')}. المهارات الناقصة: ${m.missingSkills.join(', ')}. اقترح خطوات عملية للتقديم والتطوير، ولا تنفذ أي إجراء حساس بدون موافقتي.'))),
              )]),
            ])));
          });
      }),
  );
}
