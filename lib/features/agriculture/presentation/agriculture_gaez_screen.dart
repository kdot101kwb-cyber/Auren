import 'package:flutter/material.dart';
import '../../../services/agriculture/gaez_crop_insights_service.dart';

class AgricultureGaezScreen extends StatefulWidget {
  const AgricultureGaezScreen({super.key});
  @override State<AgricultureGaezScreen> createState() => _AgricultureGaezScreenState();
}

class _AgricultureGaezScreenState extends State<AgricultureGaezScreen> {
  final _country = TextEditingController(text: 'SDN');
  final _crop = TextEditingController(text: 'Sorghum');
  final _climate = TextEditingController();
  final _ssp = TextEditingController();
  final _period = TextEditingController();
  final _water = TextEditingController();
  final _management = TextEditingController();
  final _service = GaezCropInsightsService();
  List<GaezCropInsight> _rows = const [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    for (final c in [_country, _crop, _climate, _ssp, _period, _water, _management]) c.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    if (_country.text.trim().isEmpty || _crop.text.trim().isEmpty) return;
    setState(() { _loading = true; _message = null; });
    try {
      final rows = await _service.query(
        country: _country.text, crop: _crop.text, climateSource: _climate.text,
        ssp: _ssp.text, period: _period.text, waterSupply: _water.text, management: _management.text,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _message = rows.isEmpty ? 'لا توجد نتائج مستوردة لهذا الفلتر حالياً. شغّل استيراد GAEZ v5 الرسمي أولاً.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _message = 'تعذر الوصول إلى GAEZ حالياً: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN GAEZ v5')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('FAO GAEZ v5 Crop Insights', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('استعلام عن بيانات المحصول من بيانات GAEZ v5 المستوردة في AUREN. القيم المعروضة تحمل مصدرها وإصدارها ولا تُعامل كبديل عن التحقق الزراعي المحلي.'),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field(_country, 'ISO3 الدولة')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_crop, 'المحصول')),
                ]),
                _field(_climate, 'مصدر المناخ (اختياري)'),
                Row(children: [
                  Expanded(child: _field(_ssp, 'SSP')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_period, 'الفترة')),
                ]),
                Row(children: [
                  Expanded(child: _field(_water, 'المياه / الري')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_management, 'مستوى الإدارة')),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _query,
                    icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore_outlined),
                    label: Text(_loading ? 'جاري البحث...' : 'ابحث في GAEZ v5'),
                  ),
                ),
              ]),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(_message!))),
          ],
          const SizedBox(height: 16),
          for (final item in _rows)
            Card(
              child: ExpansionTile(
                title: Text('\${item.crop} • \${item.country}'),
                subtitle: Text('\${item.version} • \${item.source}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  ...item.row.entries.map((entry) => ListTile(dense: true, title: Text(entry.key), subtitle: Text('\${entry.value}'))),
                  if (item.resourceUrl != null) SelectableText(item.resourceUrl!, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: controller, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );
}
