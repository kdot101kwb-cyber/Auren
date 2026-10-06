import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/talent/talent_sports_catalog.dart';
import '../../../services/talent/auren_sports_ai_service.dart';
import '../../messenger/presentation/messenger_screen.dart';

class AurenTalentPerformanceScreen extends StatefulWidget {
  final String sport;
  const AurenTalentPerformanceScreen({super.key, this.sport = ''});

  @override
  State<AurenTalentPerformanceScreen> createState() => _AurenTalentPerformanceScreenState();
}

class _AurenTalentPerformanceScreenState extends State<AurenTalentPerformanceScreen> {
  static const sports = TalentSportsCatalog.all;

  static const metrics = <String, String>{
    'training_load': 'حمل التدريب',
    'pace': 'الوتيرة',
    'speed': 'السرعة',
    'accuracy': 'نسبة النجاح',
    'win_rate': 'نسبة الفوز',
    'reaction': 'زمن الاستجابة',
    'vertical': 'الوثب العمودي',
    'shooting': 'دقة التسديد',
    'endurance': 'التحمل',
    'strength': 'القوة',
    'agility': 'الرشاقة',
    'balance': 'التوازن',
    'technique': 'التقنية',
  };

  late String sport;
  final metricController = TextEditingController();
  final valueController = TextEditingController();
  final unitController = TextEditingController();
  final noteController = TextEditingController();
  String summaryUnit = '';

  @override
  void initState() {
    super.initState();
    sport = widget.sport.isEmpty ? sports.first : widget.sport;
  }

  @override
  void dispose() {
    metricController.dispose();
    valueController.dispose();
    unitController.dispose();
    noteController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _entries {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('talent_performance');
  }

  Future<void> _addEntry() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final value = double.tryParse(valueController.text.trim());
    if (uid == null || value == null || value < 0 || metricController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل الرياضة والمؤشر وقيمة صحيحة.')));
      return;
    }
    await _entries.add({
      'ownerId': uid,
      'sport': sport,
      'metric': metricController.text.trim(),
      'value': value,
      'unit': unitController.text.trim(),
      'note': noteController.text.trim(),
      'recordedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    valueController.clear();
    noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ القياس.')));
  }

  Future<void> _calculator(String id) async {
    final a = TextEditingController();
    final b = TextEditingController();
    const singleValueMetrics = {'reaction','vertical','endurance','strength','agility','balance','technique'};
    final isSingleValue = singleValueMetrics.contains(id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(metrics[id] ?? 'حاسبة الأداء'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isSingleValue ? 'القيمة' : 'القيمة الأولى')),
          if (!isSingleValue) TextField(controller: b, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القيمة الثانية')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('احسب')),
        ],
      ),
    );
    final x = double.tryParse(a.text.trim());
    final y = isSingleValue ? 1.0 : double.tryParse(b.text.trim());
    if (x != null && y != null && (x < 0 || y < 0)) {
      a.dispose();
      b.dispose();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('القيم يجب أن تكون صفر أو أكبر.')));
      return;
    }
    a.dispose();
    b.dispose();
    if (ok != true || x == null || y == null) return;

    if (id == 'pace' || id == 'speed' || id == 'accuracy' || id == 'win_rate' || id == 'shooting') {
      final divisor = id == 'pace' ? x : y;
      if (divisor == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن الحساب بالقسمة على صفر.')),
          );
        }
        return;
      }
    }

    double? result;
    String unit = '';
    if (id == 'training_load') { result = x * y; unit = 'وحدة'; }
    if (id == 'pace' && x > 0) { result = y / x; unit = 'دقيقة/كم'; }
    if (id == 'speed' && y > 0) { result = x / y; unit = 'كم/ساعة'; }
    if (id == 'accuracy' && y > 0) { result = x / y * 100; unit = '%'; }
    if (id == 'win_rate' && y > 0) { result = x / y * 100; unit = '%'; }
    if (id == 'reaction') { result = x; unit = 'مللي ثانية'; }
    if (id == 'vertical') { result = x; unit = 'سم'; }
    if (id == 'shooting' && y > 0) { result = x / y * 100; unit = '%'; }
    if (id == 'endurance') { result = x; unit = 'نقطة'; }
    if (id == 'strength') { result = x; unit = 'كجم'; }
    if (id == 'agility') { result = x; unit = 'ثانية'; }
    if (id == 'balance') { result = x; unit = 'ثانية'; }
    if (id == 'technique') { result = x; unit = 'نقطة'; }

    if (!mounted || result == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(metrics[id] ?? 'النتيجة'),
        content: Text(result!.toStringAsFixed(2) + ' ' + unit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    ]),
  );


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول.')));
    return Scaffold(
      appBar: AppBar(title: const Text('تحليل وتطوير الأداء')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entries.orderBy('recordedAt', descending: true).limit(50).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final current = docs.where((d) => (d.data()['sport'] ?? '').toString() == sport).toList();
          final values = current.map((d) => (d.data()['value'] as num?)?.toDouble()).whereType<double>().toList();
          final selectedMetric = metricController.text.trim();
          final selectedMetricValues = selectedMetric.isEmpty ? values : current.where((d) => (d.data()['metric'] ?? '').toString() == selectedMetric && (summaryUnit.isEmpty || (d.data()['unit'] ?? '').toString() == summaryUnit)).map((d) => (d.data()['value'] as num?)?.toDouble()).whereType<double>().toList();
          final summaryValues = selectedMetric.isEmpty ? values : selectedMetricValues;
          final average = summaryValues.isEmpty ? null : summaryValues.reduce((a, b) => a + b) / summaryValues.length;
          final best = summaryValues.isEmpty ? null : summaryValues.reduce((a, b) => a > b ? a : b);
          final latest = summaryValues.isEmpty ? null : summaryValues.first;
          final previous = selectedMetricValues.length > 1 ? selectedMetricValues[1] : null;
          final delta = latest != null && previous != null ? latest - previous : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('الرياضة', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: sport,
                  isExpanded: true,
                  items: sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => sport = v ?? sport),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ]))),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton.icon(onPressed: current.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerScreen(initialPrompt: AurenSportsAiService.performancePrompt(sport, 'القياسات المسجلة في هذه الصفحة فقط'))), icon: const Icon(Icons.auto_awesome), label: const Text('مراجعة الأداء مع AUREN AI')),\n                const SizedBox(height: 10),\n                const Text('مؤشرات الرياضة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('اختر مؤشراً مرتبطاً بالرياضة الحالية. الملخص يعرض القياسات لنفس المؤشر فقط ولا يخلط مؤشرات مختلفة.'),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  'التحمل','القوة','السرعة','الرشاقة','التوازن','نسبة النجاح','دقة التسديد','التقنية','زمن الاستجابة'
                ].map((x) => ActionChip(label: Text(x), onPressed: () => setState(() => metricController.text = x))).toList()),
              ])),
              const SizedBox(height: 10),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('حاسبات الأداء', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('مؤشرات تخطيطية وليست تشخيصاً طبياً أو بديلاً عن المدرب. قارن القياسات لنفس المؤشر والوحدة عند متابعة الاتجاه.'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: metrics.keys.map((id) => ActionChip(label: Text(metrics[id]! ), onPressed: () => _calculator(id))).toList()),
              ]))),
              const SizedBox(height: 10),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                Text('سجل قياس لـ $sport', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: metricController.text.isEmpty ? null : metricController.text,
                  items: metrics.values.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => metricController.text = v ?? ''),
                  decoration: const InputDecoration(labelText: 'المؤشر', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(controller: valueController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القيمة', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'الوحدة (اختياري)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _addEntry, icon: const Icon(Icons.save_outlined), label: const Text('حفظ القياس'))),
              ]))),
              if (summaryValues.isNotEmpty) ...[
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('لوحة اتجاه الأداء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('عرض بصري لآخر ${summaryValues.length > 10 ? 10 : summaryValues.length} قياسات لنفس المؤشر.'),
                  const SizedBox(height: 10),
                  ...summaryValues.take(10).map((v) {
                    final maxValue = summaryValues.reduce((a, b) => a > b ? a : b);
                    final ratio = maxValue <= 0 ? 0.0 : (v / maxValue).clamp(0.0, 1.0);
                    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                      SizedBox(width: 70, child: Text(v.toStringAsFixed(1))),
                      const SizedBox(width: 8),
                      Expanded(child: LinearProgressIndicator(value: ratio, minHeight: 8)),
                    ]));
                  }),
                ]))),
                const SizedBox(height: 10),
                  const Text('ملخص الأداء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _stat('الأحدث', latest!.toStringAsFixed(2)),
                    _stat('المتوسط', average!.toStringAsFixed(2)),
                    _stat('الأفضل', best!.toStringAsFixed(2)),
                    _stat('عدد القياسات', summaryValues.length.toString()),
                    if (delta != null) _stat('التغير', '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}'),
                  ]),
                  if (delta != null) ...[
                    const SizedBox(height: 8),
                    Text(delta == 0 ? 'لا يوجد تغير عن القياس السابق.' : delta > 0 ? 'الاتجاه الأخير: ارتفاع عن القياس السابق.' : 'الاتجاه الأخير: انخفاض عن القياس السابق.', style: TextStyle(fontWeight: FontWeight.w700)),
                  ]
                ]))),
                const SizedBox(height: 10),
              ],
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('آخر القياسات • $sport', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (current.isEmpty) const Text('لا توجد قياسات بعد.'),
                ...current.take(20).map((d) {
                  final data = d.data();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.insights)),
                    title: Text((data['metric'] ?? 'مؤشر').toString()),
                    subtitle: Text((data['value'] ?? '').toString() + ' ' + (data['unit'] ?? '').toString() + ((data['note'] ?? '').toString().isEmpty ? '' : ' • ' + data['note'].toString())),
                  );
                }),
              ]))),
            ],
          );
        },
      ),
    );
  }
}
