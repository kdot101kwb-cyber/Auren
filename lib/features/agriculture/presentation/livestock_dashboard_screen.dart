import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/agriculture/livestock_management_service.dart';
import '../../../services/agriculture/livestock_planning_service.dart';
import '../../../services/agriculture/livestock_operations_service.dart';

class LivestockDashboardScreen extends StatelessWidget {
  LivestockDashboardScreen({super.key});
  final _animals = LivestockManagementService();
  final _planning = LivestockPlanningService();
  final _ops = LivestockOperationsService();

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
              Card(child: ListTile(
                leading: const Icon(Icons.insights),
                title: const Text('الإنتاج والنمو والتنبيهات'),
                subtitle: const Text('سجّل الإنتاج، تابع تغير الوزن وأغلق التنبيهات'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _operations(context, uid, active),
              )),
              const SizedBox(height: 12),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _ops.watchAlerts(uid),
                  builder: (context, s) {
                    final docs = s.data?.docs ?? const [];
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('تنبيهات القطيع', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (docs.isEmpty) const Text('لا توجد تنبيهات مفتوحة.'),
                      ...docs.take(6).map((d) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_active),
                        title: Text((d.data()['title'] ?? 'تنبيه').toString()),
                        subtitle: Text(((d.data()['dueAt'] as Timestamp?)?.toDate() ?? '').toString()),
                        trailing: IconButton(
                          icon: const Icon(Icons.done),
                          onPressed: () => _ops.closeAlert(uid, d.id),
                        ),
                      )),
                    ]);
                  },
                ),
              )),
              const SizedBox(height: 12),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _ops.watchProduction(uid),
                  builder: (context, s) {
                    final docs = s.data?.docs ?? const [];
                    double total = 0;
                    for (final d in docs) total += ((d.data()['quantity'] as num?)?.toDouble() ?? 0);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('الإنتاج المسجل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('إجمالي آخر السجلات: ' + total.toStringAsFixed(2)),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => _recordProduction(context, uid, active),
                        child: const Text('تسجيل إنتاج'),
                      ),
                    ]);
                  },
                ),
              )),
              const SizedBox(height: 12),
              Card(child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('تسجيل نمو/وزن'),
                subtitle: const Text('احفظ قياس الوزن لمتابعة النمو عبر الزمن'),
                onTap: () => _recordGrowth(context, uid, active),
              )),
              const SizedBox(height: 12),
              Card(child: ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('إضافة تنبيه'),
                subtitle: const Text('تحصين، تناسل، فحص أو مهمة قادمة'),
                onTap: () => _createAlert(context, uid, active),
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

  Future<void> _operations(BuildContext context, String uid, List<LivestockAnimal> animals) async {
    if (animals.isEmpty) return;
    final analytics = await _ops.calculateAnalytics(uid, animals.map((a) => {
      'id': a.id, 'status': a.status, 'weightKg': a.weightKg
    }).toList());
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('تحليلات القطيع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ListTile(title: const Text('النشطة'), trailing: Text(analytics.activeAnimals.toString())),
        ListTile(title: const Text('متوسط الوزن'), trailing: Text(analytics.averageWeightKg.toStringAsFixed(1) + ' kg')),
        ListTile(title: const Text('تغير الوزن المسجل'), trailing: Text(analytics.weightChangeKg.toStringAsFixed(1) + ' kg')),
        ListTile(title: const Text('الإنتاج خلال آخر 24 ساعة'), trailing: Text(analytics.productionToday.toStringAsFixed(2))),
        ListTile(title: const Text('التنبيهات المفتوحة'), trailing: Text(analytics.dueAlerts.toString())),
      ])),
    );
  }

  Future<void> _recordProduction(BuildContext context, String uid, List<LivestockAnimal> animals) async {
    var animal = animals.first;
    final qty = TextEditingController();
    final type = TextEditingController(text: 'milk');
    final unit = TextEditingController(text: 'kg');
    await showDialog<void>(context: context, builder: (dc) => AlertDialog(
      title: const Text('تسجيل إنتاج'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: animal.id,
          items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text(a.tag + ' • ' + a.species))).toList(),
          onChanged: (v) { for (final a in animals) if (a.id == v) animal = a; },
          decoration: const InputDecoration(labelText: 'الحيوان'),
        ),
        TextField(controller: type, decoration: const InputDecoration(labelText: 'النوع (milk/eggs/meat/other)')),
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'الوحدة')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          final q = double.tryParse(qty.text);
          if (q == null || q < 0) return;
          await _ops.recordProduction(uid, animalId: animal.id, type: type.text, quantity: q, unit: unit.text);
          if (dc.mounted) Navigator.pop(dc);
        }, child: const Text('حفظ')),
      ],
    ));
    qty.dispose(); type.dispose(); unit.dispose();
  }

  Future<void> _recordGrowth(BuildContext context, String uid, List<LivestockAnimal> animals) async {
    var animal = animals.first;
    final weight = TextEditingController(text: animal.weightKg?.toString() ?? '');
    await showDialog<void>(context: context, builder: (dc) => AlertDialog(
      title: const Text('تسجيل نمو/وزن'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: animal.id,
          items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text(a.tag + ' • ' + a.species))).toList(),
          onChanged: (v) { for (final a in animals) if (a.id == v) animal = a; },
        ),
        TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن بالكيلو')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          final w = double.tryParse(weight.text);
          if (w == null || w <= 0) return;
          await _ops.recordGrowth(uid, animalId: animal.id, weightKg: w);
          if (dc.mounted) Navigator.pop(dc);
        }, child: const Text('حفظ')),
      ],
    ));
    weight.dispose();
  }

  Future<void> _createAlert(BuildContext context, String uid, List<LivestockAnimal> animals) async {
    var animal = animals.first;
    final title = TextEditingController();
    final type = TextEditingController(text: 'checkup');
    final note = TextEditingController();
    await showDialog<void>(context: context, builder: (dc) => AlertDialog(
      title: const Text('إضافة تنبيه'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: animal.id,
          items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text(a.tag + ' • ' + a.species))).toList(),
          onChanged: (v) { for (final a in animals) if (a.id == v) animal = a; },
        ),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان التنبيه')),
        TextField(controller: type, decoration: const InputDecoration(labelText: 'النوع')),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'ملاحظة')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dc), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          if (title.text.trim().isEmpty) return;
          await _ops.createAlert(uid, animalId: animal.id, type: type.text.trim(), title: title.text, dueAt: DateTime.now().add(const Duration(days: 1)), note: note.text);
          if (dc.mounted) Navigator.pop(dc);
        }, child: const Text('حفظ')),
      ],
    ));
    title.dispose(); type.dispose(); note.dispose();
  }

}
