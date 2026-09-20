import 'package:flutter/material.dart';
import '../../../core/models/agent_listing.dart';
import '../../../services/agents/agent_marketplace_repository.dart';
import 'agent_detail_screen.dart';

class AgentMarketplaceScreen extends StatelessWidget {
  const AgentMarketplaceScreen({super.key});

  String _price(AurenAgentListing a) {
    if (a.pricingModel == 'free' || a.amountMinor == 0) return 'مجاني';
    return '${(a.amountMinor / 100).toStringAsFixed(2)} ${a.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Marketplace')),
      body: StreamBuilder<List<AurenAgentListing>>(
        stream: AurenAgentMarketplaceRepository().watchPublished(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الوكلاء'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('لا توجد Agents منشورة حالياً.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final agent = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.smart_toy_outlined)),
                  title: Text(agent.name),
                  subtitle: Text('${agent.description}\n${agent.capabilities.join(' • ')}'),
                  isThreeLine: true,
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (agent.reviewCount > 0) Text('★ ${agent.reputationScore.toStringAsFixed(1)}'),
                    Text(_price(agent)),
                  ]),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetailScreen(agent: agent))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
