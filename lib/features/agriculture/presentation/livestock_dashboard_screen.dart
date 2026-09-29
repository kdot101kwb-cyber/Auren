import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/agriculture/livestock_management_service.dart';
import '../../../services/agriculture/livestock_planning_service.dart';

class LivestockDashboardScreen extends StatelessWidget {
  LivestockDashboardScreen({super.key});
  final _animals = LivestockManagementService();
  final _planning = LivestockPlanningService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام لوحة القطيع.')));
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Livestock Dashboard')),
      body: StreamBuilder<List<LivestockAnimal>>(
        stream: _animals.watchAnimals(uid),
        builder: (context, snapshot) {
          final animals = snapshot.data ?? const <LivestockAnimal>[];
          final active = animals.where((a) => a.status == 'active').toList();
          final weights = active.where((a) => a.weightKg != null).map((a) => a.weightKg!).toList();
          final avg = weights.isEmpty ? 0.0 : weights.reduce((a, b) => a + b) / weights.length;
          final species = <String, int>{};
          for (final a in active) species[a.species] = (species[a.species] ?? 0) + 1;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: [
                _stat('الحيوانات', animals.length.toString(), Icons.pets),
                _stat('النشطة', active.length.toString(), Icons.check_circle),
                _stat('متوسط الوزن', avg.toStringAsFixed(1) + ' kg', Icons.monitor_weight),
                _stat('الأنواع', species.length.toString(), Icons.category),
              ]),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('توزيع القطيع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ...species.entries.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(e.key), trailing: Text(e.value.toString()))),
                ],
              ))),
              const SizedBox(height: 12),
              Card(child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('حاسبة العلف والماء'),
                subtitle: const Text('تقدير يومي حسب النوع والوزن ومرحلة الإنتاج'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _feedPlanner(context, uid, active),
              )),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _planning.watchDueSchedules(uid),
                builder: (context, s) {
                  final docs = s.data?.docs ?? const [];
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('المواعيد القادمة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (docs.isEmpty) const Text('لا توجد مواعيد معلقة.'),
                    ...docs.take(8).map((d) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text((d.data()['title'] ?? 'موعد').toString()),
                      subtitle: Text(((d.data()['dueAt'] as Timestamp?)?.toDate() ?? '').toString()),
                      trailing: IconButton(icon: const Icon(Icons.done), onPressed: () => _planning.completeSchedule(uid, d.id)),
                    )),
                  ]);
                },
              ))),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => SizedBox(
    width: 160,
    child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Icon(icon), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label),
      ])),
    ]))),
  );

  Future<void> _feedPlanner(BuildContext context, String uid, List<LivestockAnimal> animals) async {
    if (animals.isEmpty) return;
    var animal = animals.first;
    var stage = 'maintenance';
    LivestockFeedPlan? plan;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setLocal) => AlertDialog(
        title: const Text('حاسبة العلف والماء'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: animal.id,
            decoration: const InputDecoration(labelText: 'الحيوان'),
            items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text(a.tag + ' • ' + a.species))).toList(),
            onChanged: (id) { for (final a in animals) { if (a.id == id) setLocal(() => animal = a); } },
          ),
          DropdownButtonFormField<String>(
            value: stage,
            decoration: const InputDecoration(labelText: 'مرحلة الإنتاج'),
            items: const [
              DropdownMenuItem(value: 'maintenance', child: Text('صيانة')),
              DropdownMenuItem(value: 'growth', child: Text('نمو')),
              DropdownMenuItem(value: 'fattening', child: Text('تسمين')),
              DropdownMenuItem(value: 'pregnancy', child: Text('حمل')),
              DropdownMenuItem(value: 'lactation', child: Text('إدرار')),
            ],
            onChanged: (v) { if (v != null) setLocal(() => stage = v); },
          ),
          const SizedBox(height: 8),
          Text('الوزن المسجل: ' + (animal.weightKg?.toStringAsFixed(1) ?? 'غير مسجل') + ' kg'),
          if (plan != null) ...[
            const SizedBox(height: 12),
            Text('العلف الجاف: ' + plan!.dailyFeedKg.toStringAsFixed(2) + ' kg/يوم'),
            Text('الماء التقديري: ' + plan!.dailyWaterLiters.toStringAsFixed(1) + ' لتر/يوم'),
            Text(plan!.note, style: const TextStyle(fontSize: 12)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
          FilledButton(onPressed: () {
            final weight = animal.weightKg;
            if (weight == null || weight <= 0) return;
            setLocal(() => plan = _planning.estimateFeed(species: animal.species, bodyWeightKg: weight, stage: stage));
          }, child: const Text('احسب')),
          if (plan != null) FilledButton.tonal(
            onPressed: () async {
              await _planning.saveFeedPlan(uid, animalId: animal.id, plan: plan!);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('حفظ الخطة'),
          ),
        ],
      )),
    );
  }
}
