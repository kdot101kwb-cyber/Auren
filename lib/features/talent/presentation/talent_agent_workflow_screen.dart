import 'package:flutter/material.dart';
import '../../../core/models/talent.dart';
import '../../../services/talent/talent_discovery_service.dart';
import '../../../services/talent/talent_agent_orchestrator.dart';
import '../../messenger/presentation/messenger_screen.dart';

class TalentAgentWorkflowScreen extends StatefulWidget {
  final AurenTalent talent; final AurenTalentMatch match;
  const TalentAgentWorkflowScreen({super.key, required this.talent, required this.match});
  @override State<TalentAgentWorkflowScreen> createState() => _TalentAgentWorkflowScreenState();
}
class _TalentAgentWorkflowScreenState extends State<TalentAgentWorkflowScreen> {
  late final AurenTalentPlan plan; int currentStep = 0; final outputs = <String>[];
  @override void initState() { super.initState(); plan = const AurenTalentAgentOrchestrator().buildPlan(talent: widget.talent, opportunity: widget.match.opportunity, match: widget.match); }
  void _runCurrent() {
    final step = plan.steps[currentStep];
    final previous = outputs.isEmpty ? 'لا توجد مخرجات سابقة.' : outputs.last;
    final prompt = 'أنت ${step.agent} في AUREN. ${step.instruction} الفرصة: ${plan.opportunity.title}. المطابقة: ${plan.matchScore}%. المهارات: ${plan.matchedSkills.join(', ')}. الفجوات: ${plan.skillGaps.map((g) => g.skill).join(', ')}. مخرجات الوكيل السابق: $previous. قدّم نتيجة منظمة يمكن للوكيل التالي البناء عليها. لا تنفذ أي إجراء حساس أو مالي دون موافقة صريحة.';
    Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: prompt))).then((_) {
      if (!mounted) return; setState(() { if (outputs.length <= currentStep) outputs.add('تم تشغيل ${step.agent}.'); if (currentStep < plan.steps.length - 1) currentStep++; });
    });
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Talent Workflow')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(plan.opportunity.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text('مطابقة المهارات: ${plan.matchScore}%'),
        if (plan.skillGaps.isNotEmpty) ...[const SizedBox(height: 12), const Text('Skill Gaps', style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 6, children: plan.skillGaps.map((g) => Chip(label: Text(g.skill))).toList())],
      ]))),
      const SizedBox(height: 12),
      ...plan.steps.asMap().entries.map((entry) { final i=entry.key; final s=entry.value; final active=i==currentStep; final completed=i<currentStep; return Card(child: ListTile(leading: CircleAvatar(child: Text(completed?'✓':'${i+1}')), title: Text(s.agent), subtitle: Text('${s.title}\n${s.instruction}'), isThreeLine: true, trailing: active ? FilledButton(onPressed: _runCurrent, child: Text(i==plan.steps.length-1?'تشغيل':'تشغيل ثم التالي')) : Icon(completed?Icons.check_circle:Icons.lock_outline))); }),
      if (outputs.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(outputs.last))),
    ]),
  );
}