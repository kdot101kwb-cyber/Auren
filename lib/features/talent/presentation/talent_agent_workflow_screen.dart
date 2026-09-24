import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../services/talent/talent_discovery_service.dart';
import '../../../services/talent/talent_agent_orchestrator.dart';
import '../../../services/agents/agent_collaboration_repository.dart';
import '../../../core/models/agent_task.dart';
import '../../messenger/presentation/messenger_screen.dart';

class TalentAgentWorkflowScreen extends StatefulWidget {
  final AurenTalent talent; final AurenTalentMatch match;
  const TalentAgentWorkflowScreen({super.key, required this.talent, required this.match});
  @override State<TalentAgentWorkflowScreen> createState() => _TalentAgentWorkflowScreenState();
}
class _TalentAgentWorkflowScreenState extends State<TalentAgentWorkflowScreen> {
  late final AurenTalentPlan plan; late final AurenAgentCollaborationRepository repo;
  int currentStep=0; bool loading=false;
  @override void initState(){super.initState(); plan=const AurenTalentAgentOrchestrator().buildPlan(talent:widget.talent,opportunity:widget.match.opportunity,match:widget.match); repo=AurenAgentCollaborationRepository();}
  String _taskIdFor(int i)=>'${widget.match.opportunity.id}_${i}';
  Future<void> _startStep(int i) async {
    final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null||loading)return;
    setState(()=>loading=true);
    try {
      final s=plan.steps[i];
      final id=await repo.propose(sourceAgent:i==0?s.agent:plan.steps[i-1].agent,targetAgent:s.agent,title:'${s.title}: ${plan.opportunity.title}',input:{'opportunityId':plan.opportunity.id,'talentId':widget.talent.id,'matchScore':plan.matchScore,'matchedSkills':plan.matchedSkills,'skillGaps':plan.skillGaps.map((g)=>g.skill).toList(),'instruction':s.instruction});
      await repo.decide(id,'approved');
      await repo.execute(id,output:{'status':'handoff_ready','agent':s.agent,'opportunityId':plan.opportunity.id});
      if(mounted)setState(()=>currentStep=(i<plan.steps.length-1)?i+1:i);
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تشغيل المرحلة: $e'))); } finally { if(mounted)setState(()=>loading=false); }
  }
  @override Widget build(BuildContext context){ final uid=FirebaseAuth.instance.currentUser?.uid; return Scaffold(appBar:AppBar(title:const Text('AUREN Talent Workflow')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:Text(plan.opportunity.title),subtitle:Text('مطابقة المهارات: ${plan.matchScore}%'))),
    if(uid!=null) StreamBuilder<List<AurenAgentTask>>(stream:repo.watch(uid),builder:(c,s){final tasks=s.data??const <AurenAgentTask>[]; final mine=tasks.where((t)=>t.input['opportunityId']==plan.opportunity.id).toList(); if(mine.isEmpty)return const SizedBox.shrink(); return Card(child:Padding(padding:const EdgeInsets.all(12),child:Text('المهام المحفوظة: ${mine.length}')));}),
    const SizedBox(height:12),
    ...plan.steps.asMap().entries.map((e){final i=e.key;final s=e.value;final active=i==currentStep;final done=i<currentStep;return Card(child:ListTile(leading:CircleAvatar(child:Text(done?'✓':'${i+1}')),title:Text(s.agent),subtitle:Text('${s.title}\n${s.instruction}'),isThreeLine:true,trailing:active?FilledButton(onPressed:loading?null:()=>_startStep(i),child:Text(loading?'...':'تشغيل')):Icon(done?Icons.check_circle:Icons.lock_outline)));}),
    const SizedBox(height:8),
    if(currentStep>=plan.steps.length-1) FilledButton.icon(onPressed:loading?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:plan.toPrompt()))),icon:const Icon(Icons.auto_awesome),label:const Text('إكمال الخطة مع AUREN')),
  ])); }
}