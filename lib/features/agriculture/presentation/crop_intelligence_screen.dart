import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agriculture/crop_intelligence_service.dart';

class CropIntelligenceScreen extends StatefulWidget {
  const CropIntelligenceScreen({super.key});
  @override
  State<CropIntelligenceScreen> createState() => _CropIntelligenceScreenState();
}

class _CropIntelligenceScreenState extends State<CropIntelligenceScreen> {
  final _service = CropIntelligenceService();
  final _crop = TextEditingController();
  final _field = TextEditingController();
  final _area = TextEditingController(text: '1');
  final _cycle = TextEditingController(text: '120');
  final _water = TextEditingController(text: '25');
  final _fertilizer = TextEditingController(text: '100');
  final _yield = TextEditingController(text: '0');
  DateTime _plantingDate = DateTime.now();

  @override
  void dispose() {
    for (final c in [_crop, _field, _area, _cycle, _water, _fertilizer, _yield]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Crop Intelligence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('تخطيط المحصول', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('الزراعة → النمو → الري → التسميد → فحص الآفات → الحصاد المتوقع. القيم التخطيطية تقديرية وليست بديلاً عن المختص المحلي.'),
          const SizedBox(height: 16),
          _fieldInput(_crop, 'المحصول'),
          _fieldInput(_field, 'اسم الحقل / المزرعة'),
          Row(children: [
            Expanded(child: _fieldInput(_area, 'المساحة (هكتار)', number: true)),
            const SizedBox(width: 10),
            Expanded(child: _fieldInput(_cycle, 'دورة المحصول (يوم)', number: true)),
          ]),
          Row(children: [
            Expanded(child: _fieldInput(_water, 'ماء/أسبوع (مم)', number: true)),
            const SizedBox(width: 10),
            Expanded(child: _fieldInput(_fertilizer, 'سماد/هكتار (كجم)', number: true)),
          ]),
          _fieldInput(_yield, 'إنتاج متوقع/هكتار (كجم، اختياري)', number: true),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('تاريخ الزراعة'),
            subtitle: Text('\${_plantingDate.year}-\${_plantingDate.month.toString().padLeft(2, '0')}-\${_plantingDate.day.toString().padLeft(2, '0')}'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: _plantingDate,
              );
              if (picked != null) setState(() => _plantingDate = picked);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: uid == null ? null : _createPlan,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('احسب خطة المحصول'),
          ),
          if (uid != null) ...[
            const SizedBox(height: 24),
            const Text('خطط محفوظة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            StreamBuilder<List<CropPlan>>(
              stream: _service.watchPlans(uid),
              builder: (context, snapshot) {
                final plans = snapshot.data ?? const <CropPlan>[];
                if (plans.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد خطط محفوظة.')));
                return Column(children: plans.map(_planCard).toList());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldInput(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> _createPlan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final plan = _service.calculatePlan(
      crop: _crop.text,
      fieldName: _field.text,
      areaHa: double.tryParse(_area.text) ?? 0,
      plantingDate: _plantingDate,
      cycleDays: int.tryParse(_cycle.text) ?? 0,
      waterMmPerWeek: double.tryParse(_water.text) ?? 0,
      fertilizerKgPerHa: double.tryParse(_fertilizer.text) ?? 0,
      expectedYieldKgPerHa: double.tryParse(_yield.text) ?? 0,
    );
    if (plan.crop.isEmpty || plan.fieldName.isEmpty) return;
    final id = await _service.savePlan(uid: uid, plan: plan);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطة المحصول جاهزة'),
        content: Text(
          'الحصاد المتوقع: \${plan.expectedHarvestDate.year}-\${plan.expectedHarvestDate.month.toString().padLeft(2, '0')}-\${plan.expectedHarvestDate.day.toString().padLeft(2, '0')}\n'
          'الماء الأسبوعي للحقل: \${plan.data['totalWaterMmPerWeek']} مم\n'
          'السماد الإجمالي: \${plan.data['totalFertilizerKg']} كجم\n'
          'الخطة: \${plan.tasks.join(' • ')}\n\nID: $id',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
      ),
    );
  }

  Widget _planCard(CropPlan plan) {
    return Card(
      child: ListTile(
        title: Text('\${plan.crop} • \${plan.fieldName}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          'حصاد متوقع: \${plan.expectedHarvestDate.day}/\${plan.expectedHarvestDate.month}/\${plan.expectedHarvestDate.year}\n'
          'ري: \${plan.waterMmPerWeek} مم/أسبوع • سماد: \${plan.fertilizerKgPerHa} كجم/هكتار',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return;
            await _service.deletePlan(uid, plan.id);
          },
        ),
      ),
    );
  }
}