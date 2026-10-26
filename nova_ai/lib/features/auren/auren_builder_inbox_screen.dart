import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Private intake queue for AUREN ideas and source references.
/// Entries are saved on this device; this is not a remote repository sync.
class AurenBuilderInboxScreen extends StatefulWidget {
  const AurenBuilderInboxScreen({super.key});

  @override
  State<AurenBuilderInboxScreen> createState() =>
      _AurenBuilderInboxScreenState();
}

class _AurenBuilderInboxScreenState extends State<AurenBuilderInboxScreen> {
  static const _storageKey = 'nova.auren.builder.inbox.v1';
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _source = TextEditingController();
  final _search = TextEditingController();
  String _kind = 'فكرة AUREN';
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];

  static const _kinds = [
    'فكرة AUREN',
    'ملف أو رابط مرجعي',
    'فرصة سوق',
    'مشكلة أو اختبار',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _source.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _entries = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_entries));
  }

  Future<void> _addEntry() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب عنواناً أولاً')),
      );
      return;
    }
    final source = _source.text.trim();
    if (source.isNotEmpty && Uri.tryParse(source)?.hasAbsolutePath != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('راجع الرابط أو اتركه فارغاً')),
      );
      return;
    }
    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'details': _details.text.trim(),
      'source': source,
      'kind': _kind,
      'status': 'جديد',
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _entries = [entry, ..._entries];
      _title.clear();
      _details.clear();
      _source.clear();
    });
    try {
      await _save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أضيف العنصر للشاشة لكن تعذر حفظه محلياً')),
        );
      }
    }
  }

  Future<void> _setStatus(Map<String, dynamic> entry, String status) async {
    setState(() => entry['status'] = status);
    try {
      await _save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التغيير على الجهاز')),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> entry) async {
    setState(() => _entries.removeWhere((item) => item['id'] == entry['id']));
    try {
      await _save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الحذف على الجهاز')),
        );
      }
    }
  }

  Future<void> _openSource(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرابط يجب أن يبدأ بـ http أو https')),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  Future<void> _export() async {
    final text = StringBuffer('# NOVA Builder Inbox — AUREN\n\n');
    for (final entry in _entries) {
      text.writeln('## ${entry['title']}');
      text.writeln('- النوع: ${entry['kind']}');
      text.writeln('- الحالة: ${entry['status']}');
      if ((entry['details'] as String? ?? '').isNotEmpty) {
        text.writeln(entry['details']);
      }
      if ((entry['source'] as String? ?? '').isNotEmpty) {
        text.writeln('المصدر: ${entry['source']}');
      }
      text.writeln();
    }
    await Clipboard.setData(ClipboardData(text: text.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ سجل الأفكار والمراجع')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _entries.where((entry) {
      final haystack = [
        entry['title'],
        entry['details'],
        entry['source'],
        entry['kind'],
        entry['status'],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NOVA Builder · أفكار وملفات AUREN'),
          actions: [
            IconButton(
              tooltip: 'نسخ السجل',
              onPressed: _entries.isEmpty ? null : _export,
              icon: const Icon(Icons.content_copy_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF382B70), Color(0xFF202039)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.inventory_2_outlined, color: Color(0xFFB7A7FF), size: 30),
                  SizedBox(height: 8),
                  Text('صندوق عمل AUREN',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('اجمع الأفكار والروابط والمشكلات وفرص السوق في مكان خاص، ثم رتّبها كمدخلات لخطة التطوير.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'الشفافية: تُحفظ هذه المدخلات محلياً على الهاتف. الرابط يُسجّل كمرجع فقط ولا يرفع الملف إلى GitHub ولا يبدأ وكيلاً بالخلفية. مزامنة الملفات والتنفيذ الآلي تحتاجان خدمة آمنة وربطاً موثقاً بالمستودع.',
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'عنوان الفكرة أو الملف أو الفرصة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'نوع المدخل', border: OutlineInputBorder()),
              items: _kinds.map((kind) => DropdownMenuItem(value: kind, child: Text(kind))).toList(),
              onChanged: (value) => setState(() => _kind = value ?? _kinds.first),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              minLines: 2,
              maxLines: 5,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'التفاصيل: المطلوب، المشكلة، أو ملاحظات السوق',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _source,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'رابط ملف أو PR أو مصدر (اختياري)',
                hintText: 'https://github.com/...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('حفظ في صندوق NOVA Builder'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('مدخلات التطوير',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
                Text('${_entries.length}'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث في الأفكار والمراجع',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا توجد مدخلات مطابقة بعد. أضف أول فكرة أو رابط مرجعي.'),
              )
            else
              ...visible.map((entry) => Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF9B87FF)),
                      title: Text(entry['title']?.toString() ?? 'بدون عنوان'),
                      subtitle: Text('${entry['kind']} · ${entry['status']}'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        if ((entry['details'] as String? ?? '').isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(entry['details'] as String),
                          ),
                        if ((entry['source'] as String? ?? '').isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _openSource(entry['source'] as String),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('فتح المرجع'),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final status in ['جديد', 'قيد الدراسة', 'جاهز للتنفيذ', 'مكتمل'])
                              ActionChip(
                                label: Text(status),
                                onPressed: () => _setStatus(entry, status),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('حذف'),
                              onPressed: () => _delete(entry),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
