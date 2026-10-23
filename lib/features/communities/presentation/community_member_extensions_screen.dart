import 'package:flutter/material.dart';
import '../../../services/social/community_member_extensions_service.dart';

class AurenCommunityMemberExtensionsScreen extends StatefulWidget {
  const AurenCommunityMemberExtensionsScreen({super.key, required this.communityId});
  final String communityId;
  @override
  State<AurenCommunityMemberExtensionsScreen> createState() =>
      _AurenCommunityMemberExtensionsScreenState();
}

class _AurenCommunityMemberExtensionsScreenState extends State<AurenCommunityMemberExtensionsScreen> {
  final _service = AurenCommunityMemberExtensionsService();
  final _source = TextEditingController(), _translated = TextEditingController(),
      _language = TextEditingController(), _activity = TextEditingController(),
      _hours = TextEditingController(), _availability = TextEditingController(),
      _term = TextEditingController(), _meaning = TextEditingController(),
      _glossaryLanguage = TextEditingController();
  List<Map<String, dynamic>> _translations = [], _hoursLog = [], _glossary = [];
  bool _availabilityVisible = false, _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() {
    _source.dispose(); _translated.dispose(); _language.dispose(); _activity.dispose();
    _hours.dispose(); _availability.dispose(); _term.dispose(); _meaning.dispose();
    _glossaryLanguage.dispose(); super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait<Object>([
        _service.translations(widget.communityId), _service.volunteerHours(widget.communityId),
        _service.availability(widget.communityId), _service.glossary(widget.communityId),
      ]);
      if (!mounted) return;
      final profile = values[2] as Map<String, dynamic>;
      setState(() {
        _translations = values[0] as List<Map<String, dynamic>>;
        _hoursLog = values[1] as List<Map<String, dynamic>>;
        _availabilityVisible = profile['visible'] == true;
        _availability.text = profile['text'] as String? ?? '';
        _glossary = values[3] as List<Map<String, dynamic>>; _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل أدوات المجتمع المحلية.'; _loading = false; });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try { await action(); await _load(); }
    catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم الحفظ: ' + error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('امتدادات عضو المجتمع')),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: TextButton(onPressed: _load, child: Text(_error!)))
      : ListView(padding: const EdgeInsets.all(16), children: [
        const Text('أربع أدوات إضافية. كل البيانات محلية ولا تُنشر أو تُرسل لأي عضو تلقائياً.'),
        _section('٥. مساهمات الترجمة', Icons.translate, [
          TextField(controller: _source, maxLength: 1000, decoration: const InputDecoration(labelText: 'النص الأصلي')),
          TextField(controller: _translated, maxLength: 1000, decoration: const InputDecoration(labelText: 'الترجمة المقترحة')),
          TextField(controller: _language, maxLength: 60, decoration: const InputDecoration(labelText: 'اللغة')),
          FilledButton(onPressed: () => _run(() async {
            await _service.addTranslation(communityId: widget.communityId, sourceText: _source.text,
              translatedText: _translated.text, language: _language.text);
            _source.clear(); _translated.clear();
          }), child: const Text('حفظ مسودة الترجمة')),
          ..._translations.map((item) => ListTile(title: Text(item['translatedText'] as String? ?? ''),
            subtitle: Text((item['language'] ?? '').toString() + ' • مسودة محلية\n' + (item['sourceText'] ?? '').toString()),
            isThreeLine: true, trailing: IconButton(icon: const Icon(Icons.delete_outline),
              onPressed: () => _run(() => _service.removeTranslation(widget.communityId, item['id'] as String))))),
        ]),
        _section('٦. سجل ساعات التطوع', Icons.volunteer_activism_outlined, [
          TextField(controller: _activity, maxLength: 120, decoration: const InputDecoration(labelText: 'النشاط التطوعي')),
          TextField(controller: _hours, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'الساعات (من 0 إلى 24)')),
          FilledButton(onPressed: () => _run(() async {
            final value = double.tryParse(_hours.text.trim());
            if (value == null) throw ArgumentError('أدخل عدد ساعات صحيحاً.');
            await _service.addVolunteerHours(communityId: widget.communityId, activity: _activity.text,
              hours: value, date: DateTime.now());
            _activity.clear(); _hours.clear();
          }), child: const Text('إضافة ساعات')),
          ..._hoursLog.map((item) => ListTile(title: Text(item['activity'] as String? ?? ''),
            subtitle: Text((item['hours'] ?? '').toString() + ' ساعة • ' + (item['date'] ?? '').toString()),
            trailing: IconButton(icon: const Icon(Icons.delete_outline),
              onPressed: () => _run(() => _service.removeVolunteerHours(widget.communityId, item['id'] as String))))),
        ]),
        _section('٧. بطاقة التوفر الاختيارية', Icons.schedule_outlined, [
          const Text('التفعيل يسجل اختيارك محلياً فقط؛ لا يجعل البطاقة ظاهرة للأعضاء الآخرين.'),
          TextField(controller: _availability, maxLength: 500, maxLines: 3,
            decoration: const InputDecoration(labelText: 'أوقات أو ملاحظات التوفر')),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('السماح بمشاركتها لاحقاً'),
            subtitle: const Text('لا توجد مشاركة أو مزامنة في هذه النسخة.'),
            value: _availabilityVisible, onChanged: (value) => setState(() => _availabilityVisible = value)),
          FilledButton(onPressed: () => _run(() => _service.saveAvailability(communityId: widget.communityId,
            text: _availability.text, visible: _availabilityVisible)), child: const Text('حفظ بطاقة التوفر')),
        ]),
        _section('٨. قاموس مصطلحات المجتمع', Icons.menu_book_outlined, [
          TextField(controller: _term, maxLength: 120, decoration: const InputDecoration(labelText: 'المصطلح')),
          TextField(controller: _meaning, maxLength: 500, decoration: const InputDecoration(labelText: 'المعنى')),
          TextField(controller: _glossaryLanguage, maxLength: 60, decoration: const InputDecoration(labelText: 'اللغة')),
          FilledButton(onPressed: () => _run(() async {
            await _service.addGlossaryTerm(communityId: widget.communityId, term: _term.text,
              meaning: _meaning.text, language: _glossaryLanguage.text);
            _term.clear(); _meaning.clear();
          }), child: const Text('إضافة مصطلح')),
          ..._glossary.map((item) => ListTile(title: Text(item['term'] as String? ?? ''),
            subtitle: Text((item['language'] ?? '').toString() + ' • ' + (item['meaning'] ?? '').toString()),
            trailing: IconButton(icon: const Icon(Icons.delete_outline),
              onPressed: () => _run(() => _service.removeGlossaryTerm(widget.communityId, item['id'] as String))))),
        ]),
      ]),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    margin: const EdgeInsets.only(top: 12, bottom: 4),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon), const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium))]),
        const SizedBox(height: 8), ...children,
      ],
    )),
  );
}
