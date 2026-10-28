import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first NOVA comedy content queue. Publishing requires a separately
/// verified official platform adapter and server-side permission checks.
class NovaComedyStudioScreen extends StatefulWidget {
  const NovaComedyStudioScreen({super.key});

  @override
  State<NovaComedyStudioScreen> createState() => _NovaComedyStudioScreenState();
}

class _NovaComedyStudioScreenState extends State<NovaComedyStudioScreen> {
  static const _key = 'nova.comedy_studio.queue.v1';
  final _ar = TextEditingController();
  final _en = TextEditingController();
  final _notes = TextEditingController();
  String _format = 'meme';
  String _language = 'both';
  bool _loading = true;
  bool _autopublishRequested = false;
  List<Map<String, dynamic>> _items = [];

  static const _formats = <String, String>{
    'meme': 'ميم / صورة',
    'joke': 'نكتة / نص',
    'short_video': 'فيديو قصير',
    'carousel': 'منشور متعدد الصور',
  };
  static const _statuses = <String, String>{
    'draft': 'مسودة',
    'review': 'تحتاج مراجعة',
    'ready': 'جاهزة بعد التحقق',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ar.dispose();
    _en.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items = decoded.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (_) {
      _message('تعذر قراءة المسودات المحفوظة.');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value, textDirection: TextDirection.rtl)),
    );
  }

  Future<void> _saveDraft() async {
    final arabic = _ar.text.trim();
    final english = _en.text.trim();
    if (arabic.isEmpty && english.isEmpty) {
      _message('أضف نصاً عربياً أو إنجليزياً على الأقل.');
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final item = <String, dynamic>{
      'id': now,
      'brand': 'independent_nova_network_brand',
      'format': _format,
      'language': _language,
      'arabicText': arabic,
      'englishText': english,
      'notes': _notes.text.trim(),
      'status': 'draft',
      'publishingState': 'not_connected',
      'createdAt': now,
      'updatedAt': now,
    };
    setState(() {
      _items.insert(0, item);
      _ar.clear();
      _en.clear();
      _notes.clear();
    });
    try {
      await _persist();
      _message('حُفظت المسودة على الجهاز. لم يتم نشر أي شيء.');
    } catch (_) {
      setState(() => _items.removeWhere((entry) => entry['id'] == now));
      _message('تعذر حفظ المسودة؛ لم يتم نشر أي شيء.');
    }
  }

  Future<void> _setStatus(int index, String value) async {
    final previous = _items[index]['status'];
    setState(() {
      _items[index]['status'] = value;
      _items[index]['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    });
    try {
      await _persist();
    } catch (_) {
      setState(() => _items[index]['status'] = previous);
      _message('تعذر حفظ تغيير الحالة.');
    }
  }

  Future<void> _delete(int index) async {
    final removed = _items.removeAt(index);
    setState(() {});
    try {
      await _persist();
    } catch (_) {
      setState(() => _items.insert(index, removed));
      _message('تعذر الحذف؛ أُعيدت المسودة للقائمة.');
    }
  }

  void _toggleAutopublish(bool value) {
    setState(() => _autopublishRequested = value);
    if (value) {
      _message('النشر التلقائي مقفول حتى توثيق اتصال الصفحة والصلاحيات.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF382B70), Color(0xFF202039)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.theater_comedy_outlined, size: 32, color: Color(0xFFB6A8FF)),
              SizedBox(height: 10),
              Text('NOVA Comedy Studio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('كوميديا عربية وإنجليزية لجمهور عالمي. هوية مستقلة ضمن شبكة NOVA وليست صفحة AUREN.',
                textDirection: TextDirection.rtl),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Metric(label: 'عناصر المحتوى', value: _items.length.toString())),
          const SizedBox(width: 8),
          Expanded(child: _Metric(
            label: 'جاهزة للمراجعة',
            value: _items.where((item) => item['status'] == 'ready').length.toString(),
          )),
        ]),
        const SizedBox(height: 16),
        const Text('إنشاء محتوى أصلي',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _format,
          decoration: const InputDecoration(labelText: 'نوع المحتوى', border: OutlineInputBorder()),
          items: _formats.entries.map((entry) =>
            DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
          onChanged: (value) { if (value != null) setState(() => _format = value); },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _language,
          decoration: const InputDecoration(labelText: 'اللغة', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'both', child: Text('عربي + English')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) { if (value != null) setState(() => _language = value); },
        ),
        const SizedBox(height: 8),
        TextField(controller: _ar, minLines: 2, maxLines: 5, textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'النص العربي', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _en, minLines: 2, maxLines: 5,
          decoration: const InputDecoration(labelText: 'English caption', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _notes, minLines: 1, maxLines: 3, textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'ملاحظات الفكرة أو مصدر الترند وحقوق الأصل',
            border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _loading ? null : _saveDraft,
          icon: const Icon(Icons.save_outlined), label: const Text('حفظ المسودة محلياً')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('طلب النشر التلقائي'),
          subtitle: const Text('غير مفعّل حتى توثيق اتصال الصفحة وصلاحيات النشر'),
          value: _autopublishRequested,
          onChanged: _toggleAutopublish,
        ),
        const _StatusNotice(),
        const SizedBox(height: 16),
        const Text('قائمة المحتوى',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_items.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('لا توجد مسودات بعد. ابدأ بفكرة أصلية أعلاه.', textDirection: TextDirection.rtl))
        else
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            final format = _formats[item['format']] ?? 'محتوى';
            final status = item['status'] as String? ?? 'draft';
            final ar = item['arabicText'] as String? ?? '';
            final en = item['englishText'] as String? ?? '';
            return Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(format, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (ar.isNotEmpty) ...[const SizedBox(height: 8), Text(ar, textDirection: TextDirection.rtl)],
                if (en.isNotEmpty) ...[const SizedBox(height: 8), Text(en)],
                if ((item['notes'] as String? ?? '').isNotEmpty)
                  Text(item['notes'] as String, textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _statuses.containsKey(status) ? status : 'draft',
                  decoration: const InputDecoration(labelText: 'حالة المحتوى', isDense: true),
                  items: _statuses.entries.map((entry) =>
                    DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                  onChanged: (value) { if (value != null) _setStatus(index, value); },
                ),
                Align(alignment: Alignment.centerLeft, child: IconButton(
                  tooltip: 'حذف المسودة', onPressed: () => _delete(index),
                  icon: const Icon(Icons.delete_outline))),
              ]),
            ));
          }),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, textDirection: TextDirection.rtl),
    ]),
  ));
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF282438), borderRadius: BorderRadius.circular(14)),
    child: const Text(
      'الحالة بشفافية: هذه النسخة تحفظ المسودات على الجهاز فقط. لم يتم إنشاء صفحة فيسبوك أو ربط حساب أو نشر محتوى. '
      'النشر التلقائي يتطلب اتصال Meta رسمي وصلاحيات صفحة مؤكدة وخادماً آمناً وسجل تدقيق واختبارات. لا تُنسخ منشورات أو صور الآخرين.',
      textDirection: TextDirection.rtl,
    ),
  );
}
