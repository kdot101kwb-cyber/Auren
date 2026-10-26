import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first personal workspace. Entries stay on this device and are not
/// represented as market data, executed investments, or verified income.
class NovaOfflineWorkspaceScreen extends StatefulWidget {
  const NovaOfflineWorkspaceScreen({super.key});

  @override
  State<NovaOfflineWorkspaceScreen> createState() => _NovaOfflineWorkspaceScreenState();
}

class _NovaOfflineWorkspaceScreenState extends State<NovaOfflineWorkspaceScreen> {
  static const _storageKey = 'nova.offline.workspace.v1';
  final _title = TextEditingController();
  final _detail = TextEditingController();
  final _monthlyRevenue = TextEditingController();
  final _monthlyCosts = TextEditingController();
  String _category = 'خطة دخل';
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _monthlyRevenue.dispose();
    _monthlyCosts.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _entries = decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _notify('تعذر قراءة السجل المحلي. يمكنك المحاولة مجدداً.');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_entries));
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addEntry() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _notify('اكتب عنواناً قبل الحفظ.');
      return;
    }
    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'detail': _detail.text.trim(),
      'category': _category,
      'done': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _entries = [entry, ..._entries];
      _title.clear();
      _detail.clear();
    });
    try {
      await _save();
      _notify('حُفظت الملاحظة على هذا الجهاز فقط.');
    } catch (_) {
      setState(() => _entries.removeWhere((item) => item['id'] == entry['id']));
      _notify('فشل الحفظ المحلي؛ تحقق من مساحة الجهاز.');
    }
  }

  Future<void> _toggle(Map<String, dynamic> entry, bool value) async {
    final index = _entries.indexWhere((item) => item['id'] == entry['id']);
    if (index < 0) return;
    final previous = _entries[index]['done'];
    setState(() => _entries[index]['done'] = value);
    try {
      await _save();
    } catch (_) {
      if (!mounted) return;
      setState(() => _entries[index]['done'] = previous);
      _notify('تعذر حفظ التغيير.');
    }
  }

  Future<void> _delete(Map<String, dynamic> entry) async {
    final index = _entries.indexWhere((item) => item['id'] == entry['id']);
    if (index < 0) return;
    setState(() => _entries.removeAt(index));
    try {
      await _save();
    } catch (_) {
      if (!mounted) return;
      setState(() => _entries.insert(index, entry));
      _notify('تعذر حفظ الحذف.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _entries.where((entry) => entry['done'] == true).length;
    final revenue = double.tryParse(_monthlyRevenue.text.trim().replaceAll(',', '.')) ?? 0;
    final costs = double.tryParse(_monthlyCosts.text.trim().replaceAll(',', '.')) ?? 0;
    final net = revenue - costs;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('مساحة NOVA دون إنترنت', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('سجّل خطط الدخل والاستثمار والمهام والأفكار أثناء انقطاع الشبكة. البيانات محفوظة محلياً على الهاتف، ولا تُرسل تلقائياً إلى أي خادم.'),
        const SizedBox(height: 12),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.offline_bolt, color: Colors.greenAccent, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text('السجل المحلي: ${_entries.length} عنصر • ${completed} مكتمل')),
          ]),
        )),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('حاسبة الدخل الشهرية دون إنترنت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('أدخل تقدير الإيرادات والتكاليف. الحساب محلي على الهاتف ولا يُعد توصية استثمارية.'),
          const SizedBox(height: 10),
          TextField(controller: _monthlyRevenue, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الإيرادات المتوقعة شهرياً', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          TextField(controller: _monthlyCosts, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'التكاليف المتوقعة شهرياً', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Text('الصافي التقديري: ${net.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.greenAccent : Colors.redAccent)),
          Text(revenue > 0 ? 'هامش الصافي: ${(net / revenue * 100).toStringAsFixed(1)}%' : 'أدخل إيرادات أكبر من صفر لحساب الهامش.'),
        ]))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'نوع السجل', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'خطة دخل', child: Text('خطة دخل')),
            DropdownMenuItem(value: 'بحث استثماري', child: Text('بحث استثماري')),
            DropdownMenuItem(value: 'مهمة AUREN', child: Text('مهمة AUREN')),
            DropdownMenuItem(value: 'فكرة', child: Text('فكرة')),
          ],
          onChanged: (value) { if (value != null) setState(() => _category = value); },
        ),
        const SizedBox(height: 10),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()), textDirection: TextDirection.rtl),
        const SizedBox(height: 10),
        TextField(controller: _detail, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'التفاصيل / الخطوات التالية', border: OutlineInputBorder()), textDirection: TextDirection.rtl),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _addEntry, icon: const Icon(Icons.save_outlined), label: const Text('حفظ محلياً')),
        const SizedBox(height: 16),
        const Text('سجلاتك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_loading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _entries.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('لا توجد سجلات بعد. أضف خطة أو فكرة أعلاه.')),
        for (final entry in _entries)
          Card(child: CheckboxListTile(
            value: entry['done'] == true,
            onChanged: (value) => _toggle(entry, value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('${entry['title'] ?? ''}', textDirection: TextDirection.rtl),
            subtitle: Text('${entry['category'] ?? 'فكرة'}${(entry['detail'] as String? ?? '').isEmpty ? '' : '\\n${entry['detail']}'}', textDirection: TextDirection.rtl),
            secondary: IconButton(tooltip: 'حذف السجل', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(entry)),
          )),
        const SizedBox(height: 8),
        const Text('تنبيه: هذه مساحة تخطيط وليست خدمة استثمار أو ضمان دخل. لا تُنفّذ صفقات أو تحويلات مالية، ولا تُزامن البيانات أو تنشئ نسخة احتياطية سحابية.', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
