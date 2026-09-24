import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_agent_repository.dart';
import '../../../core/models/talent_agent.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentAgentsScreen extends StatelessWidget {
  const AurenTalentAgentsScreen({super.key});

  static const definitions = <Map<String, dynamic>>[
    {'role': 'career', 'name': 'Career Agent', 'icon': Icons.route, 'description': 'يحوّل مهارات الموهبة وأهدافها إلى خطة مهنية وفرص قابلة للتنفيذ.', 'capabilities': ['goal_planning', 'skill_gap', 'career_path']},
    {'role': 'discovery', 'name': 'Discovery Agent', 'icon': Icons.explore, 'description': 'يكتشف فرص العمل والمشاريع والشراكات المناسبة للموهبة.', 'capabilities': ['opportunity_discovery', 'matching', 'research']},
    {'role': 'portfolio', 'name': 'Portfolio Agent', 'icon': Icons.collections_bookmark_outlined, 'description': 'ينظم الأعمال والإنجازات ويبني ملفاً احترافياً قابلاً للمشاركة.', 'capabilities': ['portfolio', 'bio', 'case_study']},
    {'role': 'brand', 'name': 'Talent Brand Agent', 'icon': Icons.auto_awesome, 'description': 'يساعد الموهبة في المحتوى والهوية والعرض أمام الجمهور والعملاء.', 'capabilities': ['content', 'personal_brand', 'audience']},
    {'role': 'negotiation', 'name': 'Negotiation Agent', 'icon': Icons.handshake_outlined, 'description': 'يساعد في إعداد العروض والأسئلة ونقاط التفاوض قبل أي اتفاق.', 'capabilities': ['proposal', 'negotiation_prep', 'terms_review']},
  ];

  Future<void> _create(BuildContext context, String uid, Map<String, dynamic> d) async {
    try {
      await TalentAgentRepository().upsert(
        ownerId: uid, talentId: 'primary', name: d['name'] as String,
        role: d['role'] as String, description: d['description'] as String,
        capabilities: List<String>.from(d['capabilities'] as List),
      );
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تفعيل الوكيل: ' + e.toString())));
    }
  }

  String _prompt(AurenTalentAgent agent) =>
      'أنت وكيل ' + agent.name + ' داخل AUREN. دورك: ' + agent.description +
      ' ساعدني اعتماداً على معلوماتي التي أشاركها هنا، ولا تنفذ أي إجراء حساس أو مالي. '
      'ابدأ بأسئلة قليلة عند الحاجة، ثم أعطني خطوات عملية واضحة.';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول.')));
    final repo = TalentAgentRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Talent Agents')),
      body: StreamBuilder<List<AurenTalentAgent>>(
        stream: repo.watch(uid),
        builder: (context, snapshot) {
          final active = snapshot.data ?? const <AurenTalentAgent>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.psychology_outlined), SizedBox(width: 10),
                    Text('وكلاء الموهبة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  const Text('وكلاء متخصصون في التطور، اكتشاف الفرص، الملف، العلامة الشخصية والتفاوض.'),
                ]),
              )),
              const SizedBox(height: 12),
              ...definitions.map((d) {
                final role = d['role'] as String;
                final existing = active.where((a) => a.role == role).firstOrNull;
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Icon(d['icon'] as IconData)),
                  title: Text(d['name'] as String),
                  subtitle: Text(d['description'] as String),
                  trailing: existing == null
                      ? IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _create(context, uid, d))
                      : Switch(value: existing.enabled, onChanged: (v) => repo.setEnabled(uid, existing.id, v)),
                  onTap: existing == null ? () => _create(context, uid, d) : () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: _prompt(existing)))),
                ));
              }),
              if (active.any((a) => a.enabled)) ...[
                const SizedBox(height: 12),
                const Text('الوكلاء النشطون', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ...active.where((a) => a.enabled).map((a) => Card(child: ListTile(
                  leading: const Icon(Icons.smart_toy_outlined), title: Text(a.name),
                  subtitle: Text(a.capabilities.join(' • ')), trailing: const Icon(Icons.chat_outlined),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: _prompt(a)))),
                ))),
              ],
            ],
          );
        },
      ),
    );
  }
}
