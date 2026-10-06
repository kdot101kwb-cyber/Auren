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
  List<AurenAgentTask> tasks=[]; int currentStep=0; bool loading=false; String previousOutput=''; late final String workflowId; bool restored=false;
  @override void initState(){super.initState();plan=const AurenTalentAgentOrchestrator().buildPlan(talent:widget.talent,opportunity:widget.match.opportunity,match:widget.match);repo=AurenAgentCollaborationRepository(); workflowId='talent_${widget.talent.id}_${widget.match.opportunity.id}'; _restoreWorkflow();}
  List<AurenAgentTask> _workflowTasks(List<AurenAgentTask> value)=>value.where((t)=>t.input['opportunityId']==plan.opportunity.id&&t.input['talentId']==widget.talent.id).toList();
  void _syncTasks(List<AurenAgentTask> value){
    final next=_workflowTasks(value);
    if(!mounted)return;
    final maxCompleted=next.where((t)=>t.status=='completed').map((t)=>t.input['step'] is int?t.input['step'] as int:0).fold<int>(0,(a,b)=>a>b?a:b);
    final proposed=next.where((t)=>t.status=='proposed').map((t)=>t.input['step'] is int?t.input['step'] as int:0).fold<int>(999,(a,b)=>a<b?a:b);
    final approved=next.where((t)=>t.status=='approved').map((t)=>t.input['step'] is int?t.input['step'] as int:0).fold<int>(999,(a,b)=>a<b?a:b);
    final resumed=maxCompleted>0?maxCompleted:(approved<999?approved:(proposed<999?proposed:currentStep));
    if(tasks.length!=next.length||currentStep!=resumed)setState((){tasks=next;currentStep=resumed.clamp(0,plan.steps.length-1);});
  }
  AurenAgentTask? _incomingForStep(int i){for(final t in tasks){if(t.status=='approved'&&t.input['step']==i)return t;}return null;}
  String _previousOutput(int i){final incoming=_incomingForStep(i);if(incoming!=null)return incoming.input['previousOutput']?.toString()??'';return '';}
  Future<void> _restoreWorkflow() async {
    final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null)return;
    try {
      final tasks=(await repo.watch(uid).first).where((t)=>t.input['workflowId']==workflowId || t.input['opportunityId']==plan.opportunity.id).toList();
      if(tasks.isEmpty||!mounted)return;
      tasks.sort((a,b)=>(a.input['step'] is int ? a.input['step'] as int : -1).compareTo(b.input['step'] is int ? b.input['step'] as int : -1));
      final latest=tasks.last;
      final step=latest.input['step'] is int ? latest.input['step'] as int : 0;
      final previous=latest.input['previousOutput']?.toString()??'';
      final completed=latest.status=='completed';
      setState(() { currentStep=(completed ? step+1 : step).clamp(0,plan.steps.length-1); previousOutput=previous; restored=true; });
    } catch (_) {}
  }

  Future<void> _orchestrate(String command) async {
    if (loading) return;
    try {
      final result = await repo.orchestrate(workflowId, command: command);
      if (!mounted) return;
      final step = (result['currentStep'] is num
              ? (result['currentStep'] as num).toInt()
              : currentStep)
          .clamp(0, plan.steps.length - 1);
      setState(() => currentStep = step);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workflow: ' + (result['state']?.toString() ?? 'active') + ' • المرحلة ' + (step + 1).toString() + '/' + plan.steps.length.toString())),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إدارة الـWorkflow: $e')),
        );
      }
    }
  }
  Future<void> _runStep(int i) async {
    if(loading||i<0||i>=plan.steps.length)return; setState(()=>loading=true);
    final step=plan.steps[i]; final previous=_previousOutput(i); final incoming=_incomingForStep(i);
    final prompt='أنت ${step.agent} في AUREN. ${step.instruction}\nالفرصة: ${plan.opportunity.title}\nالمطابقة: ${plan.matchScore}%\nالمهارات: ${plan.matchedSkills.join(', ')}\nفجوات المهارات: ${plan.skillGaps.map((g)=>g.skill).join(', ')}\nمخرجات الوكيل السابق: ${previous.isEmpty?'لا توجد مخرجات سابقة.':previous}\nابنِ على هذه المخرجات وقدّم نتيجة منظمة للوكيل التالي. لا تنفذ إجراءً حساساً أو مالياً دون موافقة صريحة.';
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:prompt,onAiResponse:(output)=>_completeAndHandoff(i,incoming,output))));
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _completeAndHandoff(int i,AurenAgentTask? incoming,String output) async {
    if(output.trim().isEmpty)return;
    try {
      if(incoming!=null&&incoming.status=='approved'){await repo.execute(incoming.id,output:{'agent':plan.steps[i].agent,'agentOutput':output,'step':i,'opportunityId':plan.opportunity.id});}
      if(i>=plan.steps.length-1){if(mounted)setState(()=>currentStep=i);return;}
      final next=plan.steps[i+1];
      final id=await repo.propose(sourceAgent:plan.steps[i].agent,targetAgent:next.agent,title:'${next.title}: ${plan.opportunity.title}',workflowId:workflowId,step:i+1,input:{'workflowType':'talent_opportunity','opportunityId':plan.opportunity.id,'talentId':widget.talent.id,'step':i+1,'previousAgent':plan.steps[i].agent,'previousOutput':output});
      if(mounted){setState(()=>currentStep=i+1);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم حفظ مخرجات ${plan.steps[i].agent} وتسليمها إلى ${next.agent}. يحتاج موافقتك.')));}
      debugPrint('AUREN collaboration task created: $id');
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ مخرجات الوكيل: $e')));}
  }
  Future<void> _decide(AurenAgentTask task,String decision) async {try{await repo.decide(task.id,decision);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(decision=='approved'?'تمت الموافقة. يمكنك تشغيل الوكيل التالي.':'تم إلغاء التسليم.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحديث المهمة: $e')));}}
  @override Widget build(BuildContext context){final uid=FirebaseAuth.instance.currentUser?.uid;return Scaffold(appBar:AppBar(title:Text(restored?'AUREN Talent Workflow • مستأنف':'AUREN Talent Workflow')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(title:Text(plan.opportunity.title),subtitle:Text('مطابقة المهارات: ${plan.matchScore}%\nالمرحلة الحالية: ${currentStep+1} / ${plan.steps.length}'))),
    if(uid!=null)StreamBuilder<List<AurenAgentTask>>(stream:repo.watch(uid),builder:(c,s){final all=s.data??const <AurenAgentTask>[];WidgetsBinding.instance.addPostFrameCallback((_)=>_syncTasks(all));final mine=_workflowTasks(all);if(mine.isEmpty)return const SizedBox.shrink();return Column(children:mine.map((t)=>Card(child:ListTile(title:Text('${t.sourceAgent} → ${t.targetAgent}'),subtitle:Text('${t.title}\nالحالة: ${t.status}${t.input['previousOutput']!=null?'\nمخرجات سابقة محفوظة ✓':''}'),isThreeLine:true,trailing:t.status=='proposed'?Wrap(children:[IconButton(onPressed:()=>_decide(t,'cancelled'),icon:const Icon(Icons.close)),IconButton(onPressed:()=>_decide(t,'approved'),icon:const Icon(Icons.check))]):t.status=='approved'?const Icon(Icons.lock_open):const Icon(Icons.check_circle_outline)))).toList());}),
    Row(children:[Expanded(child:FilledButton.icon(onPressed:loading?null:()=>_orchestrate('pause'),icon:const Icon(Icons.pause),label:const Text('إيقاف'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:loading?null:()=>_orchestrate('resume'),icon:const Icon(Icons.play_arrow),label:const Text('استئناف')))]),
    const SizedBox(height:12),
    ...plan.steps.asMap().entries.map((e){final i=e.key,s=e.value,active=i==currentStep,done=i<currentStep;return Card(child:ListTile(leading:CircleAvatar(child:Text(done?'✓':'${i+1}')),title:Text(s.agent),subtitle:Text('${s.title}\n${s.instruction}'),isThreeLine:true,trailing:active?FilledButton(onPressed:loading?null:()=>_runStep(i),child:Text(loading?'...':'تشغيل')):Icon(done?Icons.check_circle:Icons.lock_outline)));}),
    if(currentStep>=plan.steps.length-1)FilledButton.icon(onPressed:loading?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MessengerScreen(initialPrompt:plan.toPrompt()))),icon:const Icon(Icons.auto_awesome),label:const Text('إكمال الخطة مع AUREN')),
  ]));}
}