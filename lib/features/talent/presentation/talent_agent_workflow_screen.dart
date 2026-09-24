import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/talent.dart';
import '../../../core/models/opportunity.dart';
import '../../../services/talent/talent_discovery_service.dart';
import '../../../services/talent/talent_agent_orchestrator.dart';
import '../../messenger/presentation/messenger_screen.dart';

class TalentAgentWorkflowScreen extends StatelessWidget {
  final AurenTalent talent;
  final AurenTalentMatch match;
  const TalentAgentWorkflowScreen({super.key, required this.talent, required this.match});

  @override
  Widget build(BuildContext context) {
    final opportunity = match.opportunity;
    final steps = const AurenTalentAgentOrchestrator().buildWorkflow(talent: talent, opportunity: null as dynamic, match: null as dynamic);
    return Scaffold(
      appBar: AppBar(title: const Text('Talent Agent Workflow')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(title: Text(opportunity.title), subtitle: Text('مطابقة المهارات: ${match.score}%'))),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${entry.key + 1}')),
              title: Text(entry.value.agent),
              subtitle: Text('${entry.value.title}\n${entry.value.instruction}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chat_outlined),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(
                initialPrompt: 'أنت ${entry.value.agent}. ${entry.value.instruction} الفرصة: ${opportunity.title}. لا تنفذ أي إجراء حساس بدون موافقتي.',
              ))),
            ),
          )),
        ],
      ),
    );
  }
}
