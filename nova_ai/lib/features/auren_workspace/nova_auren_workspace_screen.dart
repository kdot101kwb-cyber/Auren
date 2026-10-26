import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private device-local planning workspace. A scheduled server worker and
/// authorized GitHub integration are required for real background execution.
class NovaAurenWorkspaceScreen extends StatefulWidget {
  const NovaAurenWorkspaceScreen({super.key, required this.onOpenBuilder});
  final VoidCallback onOpenBuilder;

  @override
  State<NovaAurenWorkspaceScreen> createState() => _NovaAurenWorkspaceScreenState();
}

class _NovaAurenWorkspaceScreenState extends State<NovaAurenWorkspaceScreen> {
  static const _key = 'nova.auren.workspace.items.v1';
  final _title = TextEditingController();
  final _details = TextEditingController();
  String _kind = 'feature';
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  static const _kinds = <String, String>{
    'feature': 'ميزة AUREN',
    'bug': 'إصلاح / اختبار',
    'market': 'فرصة سوق',
    'app': 'تطبيق مستقل محتمل',
    'idea': 'فكرة تحتاج دراسة',
  };
  static const _statuses = <String, String>{
    'captured': 'مسجلة',
    'review': 'قيد الدراسة',
    'ready': 'جاهزة للتخطيط',
    'done': 'مكتملة',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is List) {
          _items = data.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {
      // Preserve access to the screen if local data is unavailable.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> _add() async {
    final title = _title.text.trim();
    if (title.length < 3) {
      _message('اكتب عنواناً واضحاً من 3 أحرف على الأقل.');
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    setState(() {
      _items.insert(0, {
        'id': now,
        'title': title,
        'details': _details.text.trim(),
        'kind': _kind,
        'status': 'captured',
        'createdAt': now,
        'updatedAt': now,
      });
      _title.clear();
      _details.clear();
    });
    try {
      await _persist();
      _message('تم حفظ العنصر على هذا الجهاز.');
    } catch (_) {
      _message('تعذر حفظ العنصر محلياً.');
    }
  }

  Future<void> _status(int index, String value) async {
    setState(() {
      _items[index]['status'] = value;
      _items[index]['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    });
    try {
      await _persist();
    } catch (_) {
      _message('تعذر حفظ تغيير الحالة.');
    }
  }

  Future<void> _delete(int index) async {
    final old = _items.removeAt(index);
    setState(() {});
    try {
      await _persist();
    } catch (_) {
      setState(() => _items.insert(index, old));
      _message('تعذر الحذف؛ أُعيد العنصر للقائمة.');
    }
  }

  Future<void> _openRepo() async {
    final uri = Uri.parse('https://github.com/kdot101kwb-cyber/Auren');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _message('تعذر فتح مستودع AUREN.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewing = _items.where((e) => e['status'] == 'review').length;
    final ready = _items.where((e) => e['status'] == 'ready').length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('مساحة NOVA الخاصة بـ AUREN',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'اجمع أفكار AUREN وملفاتها وروابطها وأخطاءها وفرص السوق. '
          'قيّم هل الأنسب إضافة ميزة إلى AUREN أم بناء تطبيق مستقل.',
          textDirection: TextDirection.rtl),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CountCard(label: 'العناصر', value: _items.length.toString())),
          const SizedBox(width: 8),
          Expanded(child: _CountCard(label: 'قيد الدراسة', value: reviewing.toString())),
          const SizedBox(width: 8),
          Expanded(child: _CountCard(label: 'جاهزة للتخطيط', value: ready.toString())),
        ]),
        const SizedBox(height: 16),
        const Text('تسجيل فكرة أو مهمة', textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _title, textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'العنوان',
            hintText: 'مثال: مزامنة منخفضة البيانات في AUREN',
            border: OutlineInputBorder())),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _kind,
          decoration: const InputDecoration(labelText: 'نوع العنصر', border: OutlineInputBorder()),
          items: _kinds.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) { if (v != null) setState(() => _kind = v); },
        ),
        const SizedBox(height: 8),
        TextField(controller: _details, minLines: 2, maxLines: 5,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'التفاصيل، رابط الملف، الدليل أو احتياج السوق',
            border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _loading ? null : _add,
          icon: const Icon(Icons.add_task), label: const Text('حفظ في مساحة AUREN')),
        OutlinedButton.icon(onPressed: widget.onOpenBuilder,
          icon: const Icon(Icons.rocket_launch_outlined),
          label: const Text('فتح مهندس بناء التطبيقات')),
        OutlinedButton.icon(onPressed: _openRepo, icon: const Icon(Icons.code),
          label: const Text('فتح مستودع AUREN')),
        const SizedBox(height: 14),
        const Text('سجل الأفكار والمهام', textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_loading)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('لا توجد عناصر محفوظة بعد. أضف أول فكرة أو مهمة أعلاه.',
              textDirection: TextDirection.rtl))
        else
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final kind = item['kind'] as String? ?? 'idea';
            final current = item['status'] as String? ?? 'captured';
            return Card(child: Padding(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(item['title'] as String? ?? 'عنصر بلا عنوان',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text((_kinds[kind] ?? kind) + ' • ' + (_statuses[current] ?? current),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white70)),
                if ((item['details'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(item['details'] as String, textDirection: TextDirection.rtl),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _statuses.containsKey(current) ? current : 'captured',
                  decoration: const InputDecoration(labelText: 'حالة العنصر',
                    border: OutlineInputBorder(), isDense: true),
                  items: _statuses.entries.map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) { if (v != null) _status(index, v); },
                ),
                Align(alignment: Alignment.centerLeft,
                  child: IconButton(tooltip: 'حذف العنصر',
                    onPressed: () => _delete(index),
                    icon: const Icon(Icons.delete_outline))),
              ])));
          }),
        const SizedBox(height: 10),
        const _BoundaryNotice(),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(10),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, textDirection: TextDirection.rtl),
    ])));
}

class _BoundaryNotice extends StatelessWidget {
  const _BoundaryNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF282438), borderRadius: BorderRadius.circular(14)),
    child: const Text(
      'الحالة بشفافية: هذه النسخة تحفظ السجل على الهاتف. لا تعمل بعدُ كعامل خلفي دائم، '
      'ولا تفحص السوق تلقائياً، ولا تغيّر مستودع GitHub. يتطلب ذلك خادماً مجدولاً آمناً، '
      'ربط GitHub بصلاحيات محدودة، وسجل تدقيق واختبارات قبل اعتماد أي تعديل.',
      textDirection: TextDirection.rtl));
}
