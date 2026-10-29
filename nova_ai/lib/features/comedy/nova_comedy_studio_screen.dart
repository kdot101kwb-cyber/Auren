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
  String _brandId = 'lol_planet';
  String _filterBrandId = 'all';
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
  static const _brands = <String, String>{
    'lol_planet': 'LOL Planet — كوميديا',
    'midnight_files': 'Midnight Files — قصص غامضة',
    'ai_after_dark': 'AI After Dark — ذكاء اصطناعي',
    'sports_vibes': 'Sports Vibes — رياضة',
    'pet_comedy_club': 'Pet Comedy Club — حيوانات مضحكة',
    'beyond_mystery': 'Beyond Mystery — ألغاز',
    'future_unlocked': 'Future Unlocked — تقنية',
    'daily_chaos': 'Daily Chaos — الحياة اليومية',
    'challenge_arena': 'Challenge Arena — تحديات',
    'wild_and_funny': 'Wild & Funny — طبيعة',
    'science_uncovered': 'Science Uncovered — علوم',
    'bite_and_smile': 'Bite & Smile — طعام',
    'level_up_life': 'Level Up Life — تطوير الذات',
    'world_is_weird': 'World Is Weird — غرائب',
    'dream_machines': 'Dream Machines — اختراعات',
    'brain_trap': 'Brain Trap — ألغاز ذهنية',
    'hidden_earth': 'Hidden Earth — أماكن',
    'money_unfiltered': 'Money Unfiltered — مال',
    'office_circus': 'Office Circus — كوميديا العمل',
    'what_if_universe': 'What If Universe — افتراضات',
    'fit_and_strong': 'Fit & Strong — لياقة',
    'gameverse': 'GameVerse — ألعاب',
    'screen_secrets': 'Screen Secrets — سينما',
    'toon_town': 'Toon Town — رسوم',
    'style_radar': 'Style Radar — أسلوب',
    'space_makeover': 'Space Makeover — فضاء',
    'make_it_magic': 'Make It Magic — إبداع',
    'sound_lab': 'Sound Lab — موسيقى',
    'language_hackers': 'Language Hackers — لغات',
    'nature_pulse': 'Nature Pulse — بيئة',
    'startup_zero': 'Startup Zero — مشاريع',
    'focus_mode': 'Focus Mode — تركيز',
    'cosmic_window': 'Cosmic Window — كون',
    'reality_glitch': 'Reality Glitch — خيال',
    'street_food_quest': 'Street Food Quest — أكل الشوارع',
    'pet_school': 'Pet School — تعليم الحيوانات',
    'build_tomorrow': 'Build Tomorrow — ابتكار',
    'book_bites': 'Book Bites — كتب',
    'culture_connect': 'Culture Connect — ثقافات',
    'creative_sparks': 'Creative Sparks — أفكار',
    'sports_skills': 'Sports Vibes: Skills & Tactics — مهارات رياضية',
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
      'brand': _brandId,
      'format': _format,
      'language': _language,
      'arabicText': arabic,
      'englishText': english,
      'notes': _notes.text.trim(),
      'status': 'draft',
      'platform': '',
      'views': null,
      'engagements': null,
      'retentionPercent': null,
      'revenueUsd': 0,
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

  Future<void> _recordResults(int index) async {
    final item = _items[index];
    final platformController = TextEditingController(text: item['platform'] as String? ?? '');
    final viewsController = TextEditingController(text: item['views']?.toString() ?? '');
    final engagementController = TextEditingController(text: item['engagements']?.toString() ?? '');
    final retentionController = TextEditingController(text: item['retentionPercent']?.toString() ?? '');
    final revenueController = TextEditingController(text: item['revenueUsd']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل النتائج الفعلية', textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: platformController,
                decoration: const InputDecoration(labelText: 'المنصة (مثلاً YouTube Shorts)'),
                textDirection: TextDirection.ltr),
              TextFormField(controller: viewsController, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المشاهدات'),
                validator: (value) => _validNonNegativeNumber(value, 'المشاهدات')),
              TextFormField(controller: engagementController, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'التفاعلات'),
                validator: (value) => _validNonNegativeNumber(value, 'التفاعلات')),
              TextFormField(controller: retentionController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'متوسط المشاهدة % (اختياري)'),
                validator: (value) => _validPercent(value)),
              TextFormField(controller: revenueController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الدخل المستلم بالدولار'),
                validator: (value) => _validNonNegativeNumber(value, 'الدخل')),
              const SizedBox(height: 8),
              const Text('سجّل الأرقام التي تظهر فعلياً في التحليلات أو التي استلمتها؛ لا تُقدّر الدخل كأنه مستلم.',
                textDirection: TextDirection.rtl),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(dialogContext, {
              'platform': platformController.text.trim(),
              'views': _parseOptionalNumber(viewsController.text),
              'engagements': _parseOptionalNumber(engagementController.text),
              'retentionPercent': _parseOptionalNumber(retentionController.text),
              'revenueUsd': _parseOptionalNumber(revenueController.text) ?? 0,
            });
          }, child: const Text('حفظ النتائج')),
        ],
      ),
    );
    platformController.dispose();
    viewsController.dispose();
    engagementController.dispose();
    retentionController.dispose();
    revenueController.dispose();
    if (result == null || !mounted) return;

    final previous = Map<String, dynamic>.from(_items[index]);
    setState(() {
      _items[index] = {..._items[index], ...result,
        'resultsUpdatedAt': DateTime.now().toUtc().toIso8601String()};
    });
    try {
      await _persist();
      _message('تم حفظ النتائج المدخلة محلياً. تحقق من صحتها في مصدرها الأصلي.');
    } catch (_) {
      setState(() => _items[index] = previous);
      _message('تعذر حفظ النتائج؛ تم التراجع عن التغيير.');
    }
  }

  String? _validNonNegativeNumber(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return null;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'أدخل رقماً صحيحاً غير سالب لـ$label';
    }
    return null;
  }

  String? _validPercent(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || !parsed.isFinite || parsed < 0 || parsed > 100) {
      return 'أدخل نسبة بين 0 و100';
    }
    return null;
  }

  num? _parseOptionalNumber(String value) {
    if (value.trim().isEmpty) return null;
    return num.tryParse(value.trim());
  }

  void _toggleAutopublish(bool value) {
    setState(() => _autopublishRequested = value);
    if (value) {
      _message('النشر التلقائي مقفول حتى توثيق اتصال الصفحة والصلاحيات.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filterBrandId == 'all' ? _items : _items.where((item) => item['brand'] == _filterBrandId).toList();
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
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Metric(label: 'المشاهدات المسجلة',
            value: _items.fold<num>(0, (sum, item) => sum + ((item['views'] as num?) ?? 0)).toString())),
          const SizedBox(width: 8),
          Expanded(child: _Metric(label: 'الدخل المسجل بالدولار',
            value: _items.fold<num>(0, (sum, item) => sum + ((item['revenueUsd'] as num?) ?? 0)).toStringAsFixed(2))),
        ]),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('الأرقام هنا مدخلة يدوياً وليست بيانات متصلة تلقائياً بالمنصات.',
            textDirection: TextDirection.rtl, style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 16),
        const Text('اختيار العلامة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _brandId,
          decoration: const InputDecoration(labelText: 'علامة المحتوى', border: OutlineInputBorder()),
          items: _brands.entries.map((entry) =>
            DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) { if (value != null) setState(() => _brandId = value); },
        ),
        const SizedBox(height: 16),
        const Text('إنشاء محتوى أصلي',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _format,
          decoration: const InputDecoration(labelText: 'نوع المحتوى', border: OutlineInputBorder()),
          items: _formats.entries.map((entry) =>
            DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
          onChanged: (value) { if (value != null) setState(() => _format = value); },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _language,
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _filterBrandId,
          decoration: const InputDecoration(labelText: 'تصفية حسب العلامة', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('كل العلامات')),
            ..._brands.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (value) { if (value != null) setState(() => _filterBrandId = value); },
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (visibleItems.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 18),
            child: Text('لا توجد مسودات بعد. ابدأ بفكرة أصلية أعلاه.', textDirection: TextDirection.rtl))
        else
          ...List.generate(visibleItems.length, (index) {
            final item = visibleItems[index];
            final itemIndex = _items.indexOf(item);
            final format = _formats[item['format']] ?? 'محتوى';
            final status = item['status'] as String? ?? 'draft';
            final ar = item['arabicText'] as String? ?? '';
            final en = item['englishText'] as String? ?? '';
            return Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(_brands[item['brand']] ?? 'علامة غير معروفة',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(format, style: Theme.of(context).textTheme.bodySmall),
                if (ar.isNotEmpty) ...[const SizedBox(height: 8), Text(ar, textDirection: TextDirection.rtl)],
                if (en.isNotEmpty) ...[const SizedBox(height: 8), Text(en)],
                if ((item['notes'] as String? ?? '').isNotEmpty)
                  Text(item['notes'] as String, textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _statuses.containsKey(status) ? status : 'draft',
                  decoration: const InputDecoration(labelText: 'حالة المحتوى', isDense: true),
                  items: _statuses.entries.map((entry) =>
                    DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                  onChanged: (value) { if (value != null) _setStatus(itemIndex, value); },
                ),
                const SizedBox(height: 8),
                Text('المنصة: ${(item['platform'] as String? ?? '').isEmpty ? 'غير محددة' : item['platform']}',
                  textDirection: TextDirection.rtl),
                Text('المشاهدات: ${item['views'] ?? '—'}  •  التفاعلات: ${item['engagements'] ?? '—'}',
                  textDirection: TextDirection.rtl),
                Text('متوسط المشاهدة: ${item['retentionPercent'] == null ? '—' : '${item['retentionPercent']}%'}  •  الدخل المسجل: ${((item['revenueUsd'] as num?) ?? 0).toStringAsFixed(2)}',
                  textDirection: TextDirection.rtl),
                OutlinedButton.icon(
                  onPressed: () => _recordResults(itemIndex),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('تسجيل النتائج الفعلية'),
                ),
                Align(alignment: Alignment.centerLeft, child: IconButton(
                  tooltip: 'حذف المسودة', onPressed: () => _delete(itemIndex),
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
