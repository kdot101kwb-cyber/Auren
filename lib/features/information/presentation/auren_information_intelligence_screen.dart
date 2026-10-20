import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/information/auren_information_intelligence_service.dart';

class AurenInformationIntelligenceScreen extends StatefulWidget {
  const AurenInformationIntelligenceScreen({super.key});

  @override
  State<AurenInformationIntelligenceScreen> createState() => _AurenInformationIntelligenceScreenState();
}

class _AurenInformationIntelligenceScreenState extends State<AurenInformationIntelligenceScreen> {
  final _author = TextEditingController();
  final _title = TextEditingController();
  final _year = TextEditingController();
  final _publisher = TextEditingController();
  final _citationUrl = TextEditingController();
  final _topicInput = TextEditingController();
  final _sampleTitle = TextEditingController();
  final _sampleSummary = TextEditingController();
  final _sourceName = TextEditingController();
  final _sourceCheckedAt = TextEditingController();
  final _packInput = TextEditingController();
  final _previousText = TextEditingController();
  final _currentText = TextEditingController();

  CitationStyle _citationStyle = CitationStyle.apa7;
  String _citationOutput = '';
  String _topicResult = '';
  String _freshnessResult = '';
  String _packOutput = '';
  String _revisionOutput = '';
  List<String> _topics = [];
  List<Map<String, String>> _sourceChecks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    for (final controller in [
      _author, _title, _year, _publisher, _citationUrl, _topicInput,
      _sampleTitle, _sampleSummary, _sourceName, _sourceCheckedAt,
      _packInput, _previousText, _currentText,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSources = prefs.getString('auren_information_source_checks_v1');
    List<Map<String, String>> sources = [];
    if (rawSources != null) {
      try {
        sources = (jsonDecode(rawSources) as List)
            .whereType<Map>()
            .map((value) => value.map((key, value) => MapEntry(key.toString(), value.toString())))
            .toList();
      } catch (_) {
        sources = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _topics = prefs.getStringList('auren_information_topic_watchlist_v1') ?? [];
      _sourceChecks = sources;
      _previousText.text = prefs.getString('auren_information_revision_baseline_v1') ?? '';
    });
  }

  Future<void> _addTopic() async {
    final topic = _topicInput.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (topic.isEmpty) return;
    if (topic.length > 80) {
      setState(() => _error = 'الموضوع يجب ألا يتجاوز 80 حرفًا.');
      return;
    }
    if (_topics.length >= 50) {
      setState(() => _error = 'وصلت إلى الحد الأقصى: 50 موضوعًا.');
      return;
    }
    if (_topics.any((item) => item.toLowerCase() == topic.toLowerCase())) {
      setState(() => _error = 'الموضوع موجود بالفعل في قائمة المتابعة.');
      return;
    }
    final next = [..._topics, topic];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auren_information_topic_watchlist_v1', next);
    if (!mounted) return;
    setState(() { _topics = next; _topicInput.clear(); _error = null; });
  }

  Future<void> _removeTopic(String topic) async {
    final next = _topics.where((item) => item != topic).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('auren_information_topic_watchlist_v1', next);
    if (mounted) setState(() => _topics = next);
  }

  void _matchTopics() {
    final item = InformationItem(
      id: 'sample',
      title: _sampleTitle.text,
      summary: _sampleSummary.text,
    );
    final matches = TopicWatchlistEngine.match(topics: _topics, items: [item]);
    setState(() {
      _topicResult = matches.isEmpty
          ? 'لا توجد كلمات متابعة مطابقة في النص المدخل.'
          : 'المواضيع المطابقة: ' + matches.first.matchedTopics.join('، ');
      _error = null;
    });
  }

  Future<void> _assessSourceFreshness() async {
    try {
      final name = _sourceName.text.trim();
      if (name.isEmpty) throw ArgumentError('أدخل اسم المصدر.');
      final dateText = _sourceCheckedAt.text.trim();
      final checked = dateText.isEmpty ? null : DateTime.tryParse(dateText);
      if (dateText.isNotEmpty && checked == null) {
        throw ArgumentError('اكتب التاريخ بصيغة YYYY-MM-DD.');
      }
      if (checked != null && checked.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        throw ArgumentError('تاريخ المراجعة لا يمكن أن يكون في المستقبل.');
      }
      final assessment = SourceFreshnessRadar.assess(
        lastCheckedAt: checked,
        now: DateTime.now(),
      );
      final status = switch (assessment.status) {
        SourceFreshnessStatus.unknown => 'غير مفحوص',
        SourceFreshnessStatus.fresh => 'حديث',
        SourceFreshnessStatus.reviewSoon => 'يحتاج مراجعة قريباً',
        SourceFreshnessStatus.stale => 'قديم ويحتاج مراجعة',
      };
      final record = <String, String>{
        'name': name,
        'lastCheckedAt': checked?.toIso8601String() ?? '',
        'status': status,
        'daysSinceCheck': assessment.daysSinceCheck?.toString() ?? '',
      };
      final next = [record, ..._sourceChecks.where((item) => item['name'] != name)].take(50).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auren_information_source_checks_v1', jsonEncode(next));
      if (!mounted) return;
      setState(() {
        _sourceChecks = next;
        _freshnessResult = checked == null
            ? 'الحالة: $status. أضف تاريخ آخر مراجعة للحصول على تقييم أدق.'
            : 'الحالة: $status — مرّ ' + (assessment.daysSinceCheck ?? 0).toString() + ' يومًا منذ آخر مراجعة.';
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error is ArgumentError ? error.message.toString() : 'تعذر تقييم المصدر.');
    }
  }

  void _buildPack() {
    try {
      final lines = _packInput.text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
      final items = lines.map((line) {
        final fields = line.split('|');
        if (fields.length < 2) throw ArgumentError('كل سطر يجب أن يحتوي على id|title ويمكن إضافة body|sourceUrl.');
        return KnowledgePackItem(
          id: fields[0].trim(),
          title: fields[1].trim(),
          body: fields.length > 2 ? fields[2].trim() : '',
          sourceUrl: fields.length > 3 ? fields[3].trim() : '',
        );
      }).toList();
      final manifest = OfflineKnowledgePackPlanner.build(items: items, now: DateTime.now());
      setState(() { _packOutput = manifest.encode(); _error = null; });
    } catch (error) {
      setState(() => _error = error is ArgumentError ? error.message.toString() : 'تعذر إنشاء حزمة المعرفة.');
    }
  }

  Future<void> _saveRevisionBaseline() async {
    final value = _currentText.text;
    if (value.trim().isEmpty) {
      setState(() => _error = 'أدخل النص الحالي أولاً.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auren_information_revision_baseline_v1', value);
    if (!mounted) return;
    setState(() { _previousText.text = value; _revisionOutput = 'تم حفظ نسخة أساس محلية للمقارنة القادمة.'; _error = null; });
  }

  void _compareRevisions() {
    try {
      final diff = KnowledgeRevisionLedger.compare(_previousText.text, _currentText.text);
      setState(() {
        _revisionOutput = !diff.hasChanges
            ? 'لا توجد تغييرات بين النسختين.'
            : [
                'الأسطر المضافة (' + diff.addedLines.length.toString() + '):',
                if (diff.addedLines.isEmpty) '—' else ...diff.addedLines.map((line) => '+ ' + line),
                '',
                'الأسطر المحذوفة (' + diff.removedLines.length.toString() + '):',
                if (diff.removedLines.isEmpty) '—' else ...diff.removedLines.map((line) => '- ' + line),
              ].join('\n');
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'تعذر مقارنة النسختين.');
    }
  }

  Future<void> _copy(String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ.')));
  }

  Widget _field(TextEditingController controller, String label, {int lines = 1, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _output(String value, {String title = 'النتيجة'}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SelectableText(value),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(onPressed: () => _copy(value), icon: const Icon(Icons.copy_outlined), tooltip: 'نسخ'),
          ),
        ]),
      ),
    );
  }

  Widget _citationTab() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('أنشئ استشهادًا قابلًا للنسخ بعدة صيغ. راجع بيانات المصدر قبل استخدامه أكاديميًا.'),
    const SizedBox(height: 12),
    _field(_author, 'المؤلف'),
    _field(_title, 'عنوان المصدر *'),
    _field(_year, 'سنة النشر'),
    _field(_publisher, 'الناشر أو الدورية'),
    _field(_citationUrl, 'رابط المصدر (اختياري)', keyboard: TextInputType.url),
    DropdownButtonFormField<CitationStyle>(
      value: _citationStyle,
      decoration: const InputDecoration(labelText: 'صيغة التصدير'),
      items: const [
        DropdownMenuItem(value: CitationStyle.apa7, child: Text('APA 7')),
        DropdownMenuItem(value: CitationStyle.mla9, child: Text('MLA 9')),
        DropdownMenuItem(value: CitationStyle.chicago, child: Text('Chicago')),
        DropdownMenuItem(value: CitationStyle.bibtex, child: Text('BibTeX')),
        DropdownMenuItem(value: CitationStyle.ris, child: Text('RIS')),
      ],
      onChanged: (value) { if (value != null) setState(() => _citationStyle = value); },
    ),
    const SizedBox(height: 10),
    FilledButton.icon(
      onPressed: () {
        try {
          final output = CitationExportStudio.format(CitationRecord(
            author: _author.text, title: _title.text, year: _year.text,
            publisher: _publisher.text, url: _citationUrl.text,
          ), _citationStyle);
          setState(() { _citationOutput = output; _error = null; });
        } catch (error) {
          setState(() => _error = error is ArgumentError ? error.message.toString() : 'تعذر إنشاء الاستشهاد.');
        }
      },
      icon: const Icon(Icons.format_quote_outlined),
      label: const Text('إنشاء الاستشهاد'),
    ),
    _output(_citationOutput, title: 'الاستشهاد الناتج'),
  ]);

  Widget _topicsTab() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('أنشئ قائمة مواضيع محلية ثم اختبر مطابقتها مع عنوان وملخص أي مادة. القائمة محفوظة على هذا الجهاز.'),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: TextField(controller: _topicInput, decoration: const InputDecoration(labelText: 'موضوع للمتابعة'))),
      const SizedBox(width: 8),
      IconButton(onPressed: _addTopic, icon: const Icon(Icons.add_circle_outline), tooltip: 'إضافة'),
    ]),
    Wrap(spacing: 8, runSpacing: 4, children: _topics.map((topic) => InputChip(
      label: Text(topic), onDeleted: () => _removeTopic(topic),
    )).toList()),
    const Divider(height: 28),
    _field(_sampleTitle, 'عنوان المادة المراد فحصها'),
    _field(_sampleSummary, 'الملخص أو النص المختصر', lines: 3),
    FilledButton.icon(onPressed: _matchTopics, icon: const Icon(Icons.manage_search), label: const Text('فحص المطابقة')),
    _output(_topicResult),
  ]);

  Widget _freshnessTab() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('تتبّع متى راجعت مصدرًا آخر مرة. هذا تقييم للتذكير بالمراجعة، وليس تحققًا آليًا من صحة المصدر.'),
    const SizedBox(height: 12),
    _field(_sourceName, 'اسم المصدر أو الموضوع *'),
    _field(_sourceCheckedAt, 'تاريخ آخر مراجعة YYYY-MM-DD (اتركه فارغًا إن لم يُراجع)'),
    FilledButton.icon(onPressed: _assessSourceFreshness, icon: const Icon(Icons.update), label: const Text('تقييم حداثة المصدر')),
    _output(_freshnessResult),
    const SizedBox(height: 12),
    Text('سجل المراجعة المحلي', style: Theme.of(context).textTheme.titleMedium),
    if (_sourceChecks.isEmpty) const Text('لم تُسجّل مراجعات بعد.')
    else ..._sourceChecks.map((item) => Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(item['name'] ?? 'مصدر'),
        subtitle: Text((item['status'] ?? '') + ((item['daysSinceCheck'] ?? '').isEmpty ? '' : ' • ' + item['daysSinceCheck']! + ' يوم')),
      ),
    )),
  ]);

  Widget _offlinePackTab() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('أنشئ manifest لحزمة معرفة قابلة للتجهيز دون اتصال. كل سطر: id|title|body|sourceUrl. هذه الخطوة تنشئ البيان فقط ولا تنزّل الملفات تلقائيًا.'),
    const SizedBox(height: 12),
    _field(_packInput, 'عنصر واحد في كل سطر', lines: 7),
    FilledButton.icon(onPressed: _buildPack, icon: const Icon(Icons.inventory_2_outlined), label: const Text('إنشاء manifest')),
    _output(_packOutput, title: 'Knowledge Pack Manifest'),
  ]);

  Widget _revisionTab() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('قارن نسخة أساس محفوظة محليًا مع نص حالي، أو احفظ النص الحالي كأساس للمراجعة القادمة.'),
    const SizedBox(height: 12),
    _field(_previousText, 'نسخة الأساس', lines: 4),
    _field(_currentText, 'النص الحالي', lines: 4),
    Wrap(spacing: 8, runSpacing: 8, children: [
      FilledButton.icon(onPressed: _compareRevisions, icon: const Icon(Icons.difference), label: const Text('مقارنة النسختين')),
      OutlinedButton.icon(onPressed: _saveRevisionBaseline, icon: const Icon(Icons.save_outlined), label: const Text('حفظ الحالي كأساس')),
    ]),
    _output(_revisionOutput, title: 'ملخص التغييرات'),
  ]);

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Information Tools'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.format_quote_outlined), text: 'الاستشهادات'),
            Tab(icon: Icon(Icons.notifications_active_outlined), text: 'متابعة المواضيع'),
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'حداثة المصادر'),
            Tab(icon: Icon(Icons.offline_pin), text: 'حزم دون اتصال'),
            Tab(icon: Icon(Icons.difference), text: 'تاريخ المعرفة'),
          ],
        ),
      ),
      body: Column(children: [
        if (_error != null)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(_error!),
              trailing: IconButton(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.close)),
            ),
          ),
        Expanded(child: TabBarView(children: [
          _citationTab(),
          _topicsTab(),
          _freshnessTab(),
          _offlinePackTab(),
          _revisionTab(),
        ])),
      ]),
    ),
  );
}
