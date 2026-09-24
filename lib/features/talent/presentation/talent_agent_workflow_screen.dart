import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/agent_task.dart';
import '../../../services/talent/talent_discovery_service.dart';
import '../../../services/talent/talent_agent_orchestrator.dart';
import '../../../services/agents/agent_collaboration_repository.dart';
import '../../messenger/presentation/messenger_screen.dart';

class TalentAgentWorkflowScreen extends StatefulWidget {
  final AurenTalent talent; final AurenTalentMatch match;
  const TalentAgentWorkflowScreen({super.key, required this.talent, required this.match});
  @override State<TalentAgentWorkflowScreen> createState()=>_TalentAgentWorkflowScreenState();
}
class _TalentAgentWorkflowScreenState extends State<TalentAgentWorkflowScreen> {
  late final AurenTalentPlan plan; late final AurenAgentCollaborationRepository repo;
  int currentStep=0; bool loading=false;
  @override void initState(){super.initState();plan=const AurenTalentAgentOrchestrator().buildPlan(talent:widget.talent,opportunity:widget.match.opportunity,match:widget.match);repo=AurenAgentCollaborationRepository();}
  Future<void> _runStep(int i) async {
    if(loading)return; setState(()=>loading=true);
    final step=plan.steps[i];
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:'أنت ${step.agent} في AUREN. ${step.instruction}\nالفرصة: ${plan.opportunity.title}\nالمطابقة: ${plan.matchScore}%\nالمهارات: ${plan.matchedSkills.join(', ')}\nفجوات المهارات: ${plan.skillGaps.map((g)=>g.skill).join(', ')}\nقدّم نتيجة منظمة يمكن للوكيل التالي البناء عليها. لا تنفذ إجراءً حساساً أو مالياً دون موافقة صريحة.',onAiResponse:(output)=>_handoff(i,output))));
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _handoff(int i,String output) async {
    if(output.trim().isEmpty)return;
    if(i>=plan.steps.length-1){if(mounted)setState(()=>currentStep=i);return;}
    try {
      final next=plan.steps[i+1];
      final id=await repo.propose(sourceAgent:plan.steps[i].agent,targetAgent:next.agent,title:'${next.title}: ${plan.opportunity.title}',input:{'workflowType':'talent_opportunity','opportunityId':plan.opportunity.id,'talentId':widget.talent.id,'step':i+1,'previousAgent':plan.steps[i].agent,'previousOutput':output});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم حفظ تسليم ${plan.steps[i].agent} → ${next.agent}. يحتاج موافقتك.')));
      if(mounted)setState(()=>currentStep=i+1);
      debugPrint('AUREN collaboration task created: $id');
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ تسليم الوكيل: $e')));}
  }
  Future<void> _decide(AurenAgentTask task,String decision) async {try{await repo.decide(task.id,decision);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(decision=='approved'?'تمت الموافقة على التسليم.':'تم إلغاء التسليم.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحديث المهمة: $e')));}}
  @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;return Scaffold(appBar:AppBar(title:const Text('AUREN Talent Workflow')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:Text(plan.opportunity.title),subtitle:Text('مطابقة المهارات: ${plan.matchScore}%'))),
    if(uid!=null) StreamBuilder<List<AurenAgentTask>>(stream:repo.watch(uid),builder:(c,s){final tasks=(s.data??const <AurenAgentTask>[]).where((t)=>t.input['opportunityId']==plan.opportunity.id).toList();if(tasks.isEmpty)return const SizedBox.shrink();return Column(children:tasks.map((t)=>Card(child:ListTile(title:Text('${t.sourceAgent} → ${t.targetAgent}'),subtitle:Text('${t.title}\nالحالة: ${t.status}'),isThreeLine:true,trailing:t.status=='proposed'?Wrap(children:[IconButton(onPressed:()=>_decide(t,'cancelled'),icon:const Icon(Icons.close)),IconButton(onPressed:()=>_decide(t,'approved'),icon:const Icon(Icons.check))]):null))).toList());}),
    const SizedBox(height:12),
    ...plan.steps.asMap().entries.map((e){final i=e.key,s=e.value,active=i==currentStep,done=i<currentStep;return Card(child:ListTile(leading:CircleAvatar(child:Text(done?'✓':'${i+1}')),title:Text(s.agent),subtitle:Text('${s.title}\n${s.instruction}'),isThreeLine:true,trailing:active?FilledButton(onPressed:loading?null:()=>_runStep(i),child:Text(loading?'...':'تشغيل')):Icon(done?Icons.check_circle:Icons.lock_outline)));}),
    if(currentStep>=plan.steps.length-1)FilledButton.icon(onPressed:loading?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:plan.toPrompt()))),icon:const Icon(Icons.auto_awesome),label:const Text('إكمال الخطة مع AUREN')),
  ]));}
}