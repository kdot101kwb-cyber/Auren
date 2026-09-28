import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/agriculture/auren_agriculture_repository.dart';

class AurenAgricultureScreen extends StatefulWidget {
  const AurenAgricultureScreen({super.key});
  @override State<AurenAgricultureScreen> createState() => _AurenAgricultureScreenState();
}

class _AurenAgricultureScreenState extends State<AurenAgricultureScreen> {
  final _repo = AurenAgricultureRepository();
  final _location = TextEditingController();
  String _type = 'all';

  @override
  void dispose() { _location.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final type = _type == 'all' ? null : _type;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Agriculture & Livestock AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مساعد الزراعة والثروة الحيوانية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('ابحث عن المحاصيل، المزارع، المواشي والفرص المحلية.'),
                const SizedBox(height: 14),
                TextField(
                  controller: _location,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'الولاية / المدينة / المنطقة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final item in const {'all':'الكل','crop':'محاصيل','livestock':'مواشي','farm':'مزارع'}.entries)
                    ChoiceChip(label: Text(item.value), selected: _type == item.key, onSelected: (_) => setState(() => _type = item.key)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded),
                  SizedBox(width: 8),
                  Text('AUREN AI الزراعي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 8),
                const Text('إرشادات أولية حسب نوع النشاط. لا تستبدل فحص المختص أو الطبيب البيطري.'),
                const SizedBox(height: 10),
                Text(_aiAdvice(_type), style: const TextStyle(height: 1.45)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Text('السوق والفرص', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenAgricultureRecord>>(
            stream: _repo.watchOpportunities(),
            builder: (context, snapshot) => _records(snapshot.data ?? const [], Icons.storefront_outlined),
          ),
          const SizedBox(height: 16),
          const Text('المعلومات المحلية', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          StreamBuilder<List<AurenAgricultureRecord>>(
            stream: _repo.watchRecords(type: type, location: _location.text),
            builder: (context, snapshot) => _records(snapshot.data ?? const [], Icons.agriculture_outlined),
          ),
          if (uid != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addNote(context, uid),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('إضافة ملاحظة للحقل / المزرعة'),
            ),
          ],
        ],
      ),
    );
  }


  String _aiAdvice(String type) {
    switch (type) {
      case 'crop':
        return 'المحاصيل: راقب رطوبة التربة، حالة الأوراق، الآفات والطقس قبل قرار الري أو المعالجة.';
      case 'livestock':
        return 'المواشي: راقب الشهية، النشاط، التنفس، الحرارة وأي تغير مفاجئ، واعزل الحيوان المشتبه بإصابته واطلب مختصاً عند الحاجة.';
      case 'farm':
        return 'المزرعة: اجمع بيانات الماء والتربة والمحاصيل والمخزون والتكاليف، ثم استخدمها لاتخاذ قرارات أدق.';
      default:
        return 'ابدأ بتحديد نوع النشاط والموقع والمحصول أو الحيوان، ثم سجّل الملاحظات والصور والبيانات بانتظام ليصبح التحليل أكثر فائدة.';
    }
  }

  Widget _records(List<AurenAgricultureRecord> rows, IconData icon) {
    if (rows.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد بيانات متاحة حالياً.')));
    }
    return Column(children: rows.take(20).map((r) => Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text([r.type, r.location, r.status].where((x) => x.isNotEmpty).join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    )).toList());
  }

  Future<void> _addNote(BuildContext context, String uid) async {
    final title = TextEditingController();
    final note = TextEditingController();
    final type = ValueNotifier('field');
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ملاحظة زراعية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
          TextField(controller: note, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'الملاحظة')),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(valueListenable: type, builder: (_, v, __) => DropdownButton<String>(
            value: v, isExpanded: true,
            items: const [DropdownMenuItem(value:'field',child:Text('حقل')),DropdownMenuItem(value:'livestock',child:Text('مواشي')),DropdownMenuItem(value:'farm',child:Text('مزرعة'))],
            onChanged: (x) { if (x != null) type.value = x; },
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            if (title.text.trim().isEmpty || note.text.trim().isEmpty) return;
            await _repo.saveFieldNote(uid: uid, title: title.text, note: note.text, type: type.value);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('حفظ')),
        ],
      ),
    );
    title.dispose(); note.dispose(); type.dispose();
  }
}
