import 'package:flutter/material.dart';
import 'opportunity_engine.dart';

const _accent = Color(0xFF9B87FF);

class OpportunityLabScreen extends StatefulWidget {
  const OpportunityLabScreen({super.key});
  @override
  State<OpportunityLabScreen> createState() => _OpportunityLabScreenState();
}

class _OpportunityLabScreenState extends State<OpportunityLabScreen> {
  final _name = TextEditingController();
  final _evidence = TextEditingController();
  double _demand = 50, _trend = 50, _monetization = 50;
  double _evidenceStrength = 20, _competition = 50, _cost = 50;
  OpportunityCandidate? _result;
  String _error = '';

  @override
  void dispose() { _name.dispose(); _evidence.dispose(); super.dispose(); }

  void _evaluate() {
    try {
      final candidate = OpportunityCandidate(
        name: _name.text.trim(), evidence: _evidence.text.trim(),
        demand: _demand, trend: _trend, monetization: _monetization,
        evidenceStrength: _evidenceStrength, competition: _competition, executionCost: _cost,
      );
      candidate.validate();
      setState(() { _result = candidate; _error = ''; });
    } on ArgumentError catch (error) {
      setState(() { _result = null; _error = error.message?.toString() ?? 'راجع البيانات المدخلة'; });
    }
  }

  Widget _scoreSlider(String label, double value, ValueChanged<double> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label)),
          Text(value.round().toString(), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
        ]),
        Slider(value: value, min: 0, max: 100, divisions: 20, activeColor: _accent, onChanged: onChanged),
      ]);

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]), borderRadius: BorderRadius.circular(22)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.trending_up, color: _accent, size: 30), SizedBox(height: 10),
        Text('مختبر فرص الدخل', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), Text('رتّب الأفكار بمعايير واضحة، واكشف ضعف الأدلة قبل أن تصرف المال.'),
      ]),
    ),
    const SizedBox(height: 16),
    TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الفكرة أو المنتج', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: _evidence, maxLines: 2, decoration: const InputDecoration(labelText: 'الدليل أو مصدر المعلومة (رابط/مقابلات/مبيعات)', border: OutlineInputBorder())),
    const SizedBox(height: 18),
    const Text('قيّم من 0 إلى 100 حسب الأدلة المتوفرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    const SizedBox(height: 8),
    _scoreSlider('الطلب المتوقع', _demand, (v) => setState(() => _demand = v)),
    _scoreSlider('قوة الاتجاه الصاعد', _trend, (v) => setState(() => _trend = v)),
    _scoreSlider('وضوح طريقة تحقيق الدخل', _monetization, (v) => setState(() => _monetization = v)),
    _scoreSlider('قوة الأدلة المتاحة', _evidenceStrength, (v) => setState(() => _evidenceStrength = v)),
    _scoreSlider('شدة المنافسة (الأقل أفضل)', _competition, (v) => setState(() => _competition = v)),
    _scoreSlider('تكلفة التنفيذ (الأقل أفضل)', _cost, (v) => setState(() => _cost = v)),
    const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('الأوزان: الطلب 25%، الاتجاه 15%، تحقيق الدخل 20%، قوة الدليل 20%، المنافسة 10%، تكلفة التنفيذ 10%. المنافسة والتكلفة تُحسبان عكسيًا.'))),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: _evaluate, icon: const Icon(Icons.analytics_outlined), label: const Text('احسب ترتيب الفرصة')),
    if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error, style: const TextStyle(color: Colors.orangeAccent))),
    if (_result != null) ...[
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_result!.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_result!.score.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _accent)),
          const Padding(padding: EdgeInsets.only(bottom: 7, left: 6), child: Text('/ 100')),
        ]),
        const SizedBox(height: 8),
        Text(_result!.recommendation, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('الدليل المسجل: ${_result!.evidence.isEmpty ? 'لم يُسجل دليل بعد' : _result!.evidence}'),
      ]))),
    ],
    const SizedBox(height: 8),
    const Text('هذا تقييم إرشادي من المدخلات التي أدخلتها، وليس بحث سوق مباشرًا أو وعدًا بالأرباح. اجمع بيانات حقيقية وحدّث الدرجات قبل اتخاذ قرار مالي.', style: TextStyle(color: Colors.white70)),
  ]);
}
