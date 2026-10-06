import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/talent/talent_badge_repository.dart';

class AurenTalentBadgesScreen extends StatefulWidget {
  final String talentId; final String ownerId; final String displayName; final List<String> sports; final List<String> skills; final List<String> achievements; final List<String> goals;
  const AurenTalentBadgesScreen({super.key, required this.talentId, required this.ownerId, required this.displayName, required this.sports, required this.skills, required this.achievements, required this.goals});
  @override State<AurenTalentBadgesScreen> createState() => _AurenTalentBadgesScreenState();
}

class _AurenTalentBadgesScreenState extends State<AurenTalentBadgesScreen> {
  final repo = TalentBadgeRepository();
  bool running = false;
  Future<void> _evaluate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid; if (uid == null || uid != widget.ownerId) return;
    setState(() => running = true);
    try { await repo.evaluate(uid: uid, talentId: widget.talentId, displayName: widget.displayName, sports: widget.sports, skills: widget.skills, achievements: widget.achievements, goals: widget.goals); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الشارات حسب البيانات الحالية.'))); }
    finally { if (mounted) setState(() => running = false); }
  }
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != widget.ownerId) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    return Scaffold(appBar: AppBar(title: const Text('Achievements & Badges'), actions: [IconButton(onPressed: running ? null : _evaluate, icon: const Icon(Icons.refresh))]),
      body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(onPressed: running ? null : _evaluate, icon: running ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.auto_awesome), label: const Text('حدّث الشارات'))),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watch(uid),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('تعذر تحميل الشارات: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final badges = snap.data!;
              if (badges.isEmpty) {
                return const Center(
                  child: Text('لا توجد شارات بعد. أكمل ملف الموهبة ثم حدّث الشارات.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final b = badges[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.workspace_premium),
                      ),
                      title: Text(b['title']?.toString() ?? ''),
                      subtitle: const Text('تم الحصول عليها من بيانات ملف الموهبة'),
                      trailing: const Icon(Icons.verified_outlined),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}