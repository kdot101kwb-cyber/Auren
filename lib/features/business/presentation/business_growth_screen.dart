import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/business.dart';
import '../../../services/business/business_growth_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenBusinessGrowthScreen extends StatefulWidget {
  const AurenBusinessGrowthScreen({super.key, required this.business});
  final AurenBusiness business;
  @override
  State<AurenBusinessGrowthScreen> createState() => _AurenBusinessGrowthScreenState();
}

class _AurenBusinessGrowthScreenState extends State<AurenBusinessGrowthScreen> {
  final service = AurenGrowthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Growth & Outreach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessengerScreen(
                  initialPrompt: 'حلّل نشاط \${widget.business.name} وابنِ خطة نمو تشمل العملاء، التسويق، الشراكات والتوسع.',
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: ListTile(leading: const Icon(Icons.trending_up), title: Text(widget.business.name), subtitle: const Text('Growth Engine • Outreach • Campaigns'))),
          Row(
            children: [
              Expanded(child: _action('خطة نمو', Icons.insights_outlined, 'حلّل نشاطي وابنِ خطة نمو من 30 يوماً')),
              Expanded(child: _action('عملاء', Icons.people_alt_outlined, 'حدّد لي شرائح العملاء المناسبة وكيف أصل إليها')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _action('حملة', Icons.campaign_outlined, 'اكتب حملة تسويقية كاملة لهذا النشاط')),
              Expanded(child: _action('شراكات', Icons.handshake_outlined, 'اقترح أنواع شركاء يمكن أن ينمو معهم النشاط')),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Campaigns', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: service.watchCampaigns(widget.business.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('تعذر تحميل الحملات: \${snapshot.error}');
              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('لا توجد حملات بعد. أنشئ أول حملة من الزر أدناه.')));
              return Column(
                children: items.map((campaign) {
                  final id = campaign['id']?.toString() ?? '';
                  final name = campaign['name']?.toString() ?? '';
                  final channel = campaign['channel']?.toString() ?? '';
                  final status = campaign['status']?.toString() ?? 'draft';
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('\$channel • \$status'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => service.updateCampaignStatus(businessId: widget.business.id, campaignId: id, status: value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'active', child: Text('تشغيل')),
                          PopupMenuItem(value: 'paused', child: Text('إيقاف مؤقت')),
                          PopupMenuItem(value: 'completed', child: Text('إكمال')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('إنشاء حملة')),
        ],
      ),
    );
  }

  Widget _action(String title, IconData icon, String prompt) => Padding(
        padding: const EdgeInsets.all(4),
        child: OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: '\$prompt لنشاط \${widget.business.name}')),
          ),
          icon: Icon(icon),
          label: Text(title),
        ),
      );
}
