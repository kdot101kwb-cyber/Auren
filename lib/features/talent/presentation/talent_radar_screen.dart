import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/talent_scout_finding.dart';
import '../../../services/talent/talent_scout_service.dart';

class AurenTalentRadarScreen extends StatefulWidget {
  const AurenTalentRadarScreen({super.key});
  @override State<AurenTalentRadarScreen> createState() => _AurenTalentRadarScreenState();
}

class _AurenTalentRadarScreenState extends State<AurenTalentRadarScreen> {
  String filter = 'all';
  bool _cleaning = false;
  @override Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً.')));
    final service = TalentScoutService();
    return Scaffold(
      appBar: AppBar(title: const Text('Talent Radar'), actions: [IconButton(tooltip: 'تنظيف الإشارات المنتهية', icon: _cleaning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cleaning_services_outlined), onPressed: _cleaning ? null : () async {
        setState(() => _cleaning = true);
        try {
          await service.clearExpired(uid);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذر تنظيف الإشارات: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _cleaning = false);
        }
      })]),
      body: StreamBuilder<List<AurenTalentScoutFinding>>(
        stream: service.watchFindings(uid),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('تعذر تحميل الرادار: ${snap.error}'));
          final all = snap.data ?? const <AurenTalentScoutFinding>[];
          final items = filter == 'all' ? all : all.where((x) => x.type == filter).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 6, children: [
              for (final x in const ['all','opportunity','sports','learning','market','brand','talent']) FilterChip(label: Text(x == 'all' ? 'الكل' : x), selected: filter == x, onSelected: (_) => setState(() => filter = x)),
            ])),
            Expanded(child: items.isEmpty ? const Center(child: Text('لا توجد إشارات بعد. شغّل الكشافين لإعادة البحث.')) : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) { final f = items[i]; return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.radar), const SizedBox(width: 8), Expanded(child: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w900))), Chip(label: Text('${f.score}%'))]),
                const SizedBox(height: 6), Text(f.description),
                if (f.matchedSkills.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('المهارات الموثقة المطابقة: ${f.matchedSkills.join(' • ')}')),
                if (f.missingSkills.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('فجوات: ${f.missingSkills.join(' • ')}')),
                const SizedBox(height: 8), Wrap(spacing: 8, children: [if (f.status == 'new') OutlinedButton(onPressed: () => service.markSeen(uid, f.id), child: const Text('مراجعة')), if (f.status != 'interested' && f.status != 'dismissed') OutlinedButton(onPressed: () => service.markInterested(uid, f.id), child: const Text('مهتم')), if (f.status != 'dismissed') OutlinedButton(onPressed: () => service.dismiss(uid, f.id), child: const Text('إخفاء'))]),
              ]))); },
            )),
          ]);
        },
      ),
    );
  }
}