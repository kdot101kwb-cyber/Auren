import 'package:flutter/material.dart';
import '../../../services/agriculture/gaez_v5_service.dart';

class AurenGaezV5Card extends StatefulWidget {
  const AurenGaezV5Card({super.key});

  @override
  State<AurenGaezV5Card> createState() => _AurenGaezV5CardState();
}

class _AurenGaezV5CardState extends State<AurenGaezV5Card> {
  final _service = AurenGaezV5Service();
  final _crop = TextEditingController();
  String _input = 'HRLM';
  String _status = 'اختر المحصول ثم افحص مصدر GAEZ v5.';
  bool _loading = false;

  @override
  void dispose() {
    _crop.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final crop = _crop.text.trim();
    if (crop.isEmpty) {
      setState(() => _status = 'أدخل كود المحصول في GAEZ v5.');
      return;
    }
    setState(() {
      _loading = true;
      _status = 'جارٍ الاستعلام من كتالوج FAO RES05...';
    });
    try {
      final data = await _service.queryOfficialCatalog(
        crop: crop,
        inputLevel: _input,
      );
      final features = data['features'];
      final count = features is List ? features.length : 0;
      if (!mounted) return;
      setState(() {
        _status = count > 0
            ? 'تم العثور على $count سجل/سجلات حقيقية في كتالوج FAO RES05.'
            : 'لم يعثر الكتالوج على نتائج بهذا الكود ومستوى الإدارة.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'تعذر الوصول إلى كتالوج GAEZ v5 حالياً.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.public_outlined),
                SizedBox(width: 8),
                Text('GAEZ v5 — FAO/IIASA',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'تحليل ملاءمة المحاصيل والإنتاجية المحتملة عبر بيانات GAEZ v5 الرسمية.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _crop,
              decoration: const InputDecoration(
                labelText: 'كود المحصول في GAEZ v5',
                hintText: 'مثال: استخدم كوداً من كتالوج GAEZ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _input,
              decoration: const InputDecoration(
                labelText: 'مستوى الإدارة/المدخلات',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'HRLM', child: Text('High input / rain-fed')),
                DropdownMenuItem(value: 'HILM', child: Text('High input / irrigated')),
                DropdownMenuItem(value: 'LRLM', child: Text('Low input / rain-fed')),
                DropdownMenuItem(value: 'LILM', child: Text('Low input / irrigated')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _input = value);
              },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loading ? null : _check,
              icon: const Icon(Icons.verified_outlined),
              label: Text(_loading ? 'جاري الفحص...' : 'فحص مصدر GAEZ'),
            ),
            const SizedBox(height: 8),
            Text(_status, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
