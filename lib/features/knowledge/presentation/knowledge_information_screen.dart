import 'package:flutter/material.dart';
import '../../../services/knowledge/knowledge_information_service.dart';

class AurenKnowledgeInformationScreen extends StatelessWidget {
  const AurenKnowledgeInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KnowledgeInformationService();
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AUREN Knowledge'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.inbox_outlined), text: 'المعرفة'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'الأدلة'),
              Tab(icon: Icon(Icons.link_outlined), text: 'المصادر'),
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'القراءة'),
              Tab(icon: Icon(Icons.translate_outlined), text: 'المصطلحات'),
              Tab(icon: Icon(Icons.translate_outlined), text: 'ترجمة'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _KnowledgePane(kind: 'knowledge', service: service),
          _KnowledgePane(kind: 'evidence', service: service),
          _KnowledgePane(kind: 'sources', service: service),
          _KnowledgePane(kind: 'reading', service: service),
          _KnowledgePane(kind: 'glossary', service: service),
          _KnowledgePane(kind: 'translation', service: service),
        ]),
      ),
    );
  }
}

class _KnowledgePane extends StatefulWidget {
  const _KnowledgePane({required this.kind, required this.service});
  final String kind;
  final KnowledgeInformationService service;

  @override
  State<_KnowledgePane> createState() => _KnowledgePaneState();
}

class _KnowledgePaneState extends State<_KnowledgePane> {
  final Map<String, TextEditingController> _controllers = {};
  List<Map<String, dynamic>> _items = const [];
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String _verdict = 'unverified';
  String _priority = 'normal';
  String _translationResult = '';

  String _value(String key) => _controllers.putIfAbsent(key, TextEditingController.new).text;
  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.kind != 'translation') _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant _KnowledgePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind && widget.kind != 'translation') _refresh();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() {
    switch (widget.kind) {
      case 'knowledge': return widget.service.listKnowledge();
      case 'evidence': return widget.service.listEvidence();
      case 'sources': return widget.service.listSourceProfiles();
      case 'reading': return widget.service.listReadingQueue();
      case 'glossary': return widget.service.listGlossary();
      default: return Future.value(const <Map<String, dynamic>>[]);
    }
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _fetch();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل العناصر. تأكد من تسجيل الدخول ثم حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      if (widget.kind == 'translation') _translationResult = '';
    });
    try {
      switch (widget.kind) {
        case 'knowledge':
          await widget.service.captureKnowledge(
            title: _value('title'),
            body: _value('body'),
            sourceUrl: _value('sourceUrl'),
            tags: _value('tags').split(RegExp(r'[,،\n]')),
          );
          break;
        case 'evidence':
          await widget.service.saveEvidence(
            claim: _value('claim'),
            sourceUrls: _value('sourceUrls').split(RegExp(r'[,،\n]')).map((v) => v.trim()).where((v) => v.isNotEmpty).toList(),
            verdict: _verdict,
            notes: _value('notes'),
          );
          break;
        case 'sources':
          await widget.service.saveSourceProfile(
            url: _value('url'),
            label: _value('label'),
            ownerOrPublisher: _value('publisher'),
            sourceType: _value('sourceType').trim().isEmpty ? 'other' : _value('sourceType'),
            notes: _value('notes'),
          );
          break;
        case 'reading':
          await widget.service.saveReadingQueueItem(
            title: _value('title'),
            url: _value('url'),
            priority: _priority,
            notes: _value('notes'),
          );
          break;
        case 'translation':
          final result = await widget.service.translateText(
            text: _value('translationText'),
            sourceLanguage: _value('translationSource').trim().isEmpty
                ? 'auto'
                : _value('translationSource'),
            targetLanguage: _value('translationTarget'),
            context: _value('translationContext'),
          );
          if (mounted) {
            setState(() => _translationResult =
                result['translation']?.toString().trim() ?? '');
          }
          break;
        case 'glossary':
          await widget.service.saveGlossaryEntry(
            sourceTerm: _value('sourceTerm'),
            translatedTerm: _value('translatedTerm'),
            sourceLanguage: _value('sourceLanguage'),
            targetLanguage: _value('targetLanguage'),
            context: _value('context'),
            alternatives: _value('alternatives').split(RegExp(r'[,،\n]')),
          );
          break;
      }
      if (widget.kind != 'translation') {
        for (final controller in _controllers.values) {
          controller.clear();
        }
        await _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error is ArgumentError
          ? error.message.toString()
          : widget.kind == 'translation'
              ? 'تعذرت الترجمة. تحقق من إعدادات مزود الذكاء الاصطناعي والاتصال ثم حاول مجدداً.'
              : 'تعذر الحفظ. راجع البيانات والاتصال ثم حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label, {int lines = 1, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _controller(key),
          maxLines: lines,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  List<Widget> _formFields() {
    switch (widget.kind) {
      case 'knowledge':
        return [_field('title', 'عنوان المعلومة *'), _field('body', 'النص أو الملخص', lines: 3),
          _field('sourceUrl', 'رابط المصدر (اختياري إذا كتبت النص)', keyboard: TextInputType.url),
          _field('tags', 'وسوم مفصولة بفواصل')];
      case 'evidence':
        return [_field('claim', 'الادعاء المراد توثيقه *', lines: 2),
          _field('sourceUrls', 'روابط المصادر (كل رابط في سطر) *', lines: 3),
          DropdownButtonFormField<String>(value: _verdict, decoration: const InputDecoration(labelText: 'الحالة'),
            items: const [DropdownMenuItem(value: 'unverified', child: Text('غير متحقق')),
              DropdownMenuItem(value: 'supported', child: Text('مدعوم')),
              DropdownMenuItem(value: 'disputed', child: Text('متنازع عليه')),
              DropdownMenuItem(value: 'mixed', child: Text('أدلة مختلطة'))],
            onChanged: (value) { if (value != null) setState(() => _verdict = value); }),
          const SizedBox(height: 10), _field('notes', 'ملاحظات', lines: 2)];
      case 'sources':
        return [_field('url', 'رابط المصدر *', keyboard: TextInputType.url),
          _field('label', 'اسم المصدر'), _field('publisher', 'الناشر أو الجهة'),
          _field('sourceType', 'النوع: official / news / academic / journal / community / other'),
          _field('notes', 'ملاحظات عن المصدر', lines: 2)];
      case 'reading':
        return [_field('title', 'عنوان المادة *'), _field('url', 'رابط المادة *', keyboard: TextInputType.url),
          DropdownButtonFormField<String>(value: _priority, decoration: const InputDecoration(labelText: 'الأولوية'),
            items: const [DropdownMenuItem(value: 'low', child: Text('منخفضة')),
              DropdownMenuItem(value: 'normal', child: Text('عادية')),
              DropdownMenuItem(value: 'high', child: Text('عالية'))],
            onChanged: (value) { if (value != null) setState(() => _priority = value); }),
          const SizedBox(height: 10), _field('notes', 'ملاحظات', lines: 2)];
      case 'translation':
        return [
          _field('translationText', 'النص المطلوب ترجمته *', lines: 4),
          _field('translationSource', 'لغة المصدر (auto للكشف التلقائي)'),
          _field('translationTarget', 'لغة الهدف * (مثلاً ar أو en)'),
          _field('translationContext', 'السياق أو المصطلحات المتخصصة (اختياري)', lines: 2),
        ];
      default:
        return [_field('sourceTerm', 'المصطلح الأصلي *'), _field('translatedTerm', 'الترجمة *'),
          _field('sourceLanguage', 'لغة المصدر (مثلاً ar) *'), _field('targetLanguage', 'لغة الهدف (مثلاً en) *'),
          _field('context', 'السياق أو مثال الاستخدام', lines: 2), _field('alternatives', 'بدائل مفصولة بفواصل')];
    }
  }

  Future<void> _handleReadingAction(
    Map<String, dynamic> item,
    String action,
  ) async {
    final id = item['id']?.toString().trim() ?? '';
    try {
      if (action == 'remove') {
        if (id.isEmpty) throw ArgumentError('Missing reading item id.');
        await widget.service.removeReadingQueueItem(id: id);
      } else {
        await widget.service.saveReadingQueueItem(
          id: id,
          title: item['title']?.toString() ?? '',
          url: item['url']?.toString() ?? '',
          status: action,
          priority: item['priority']?.toString() ?? 'normal',
          notes: item['notes']?.toString() ?? '',
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ArgumentError
            ? error.message.toString()
            : 'تعذر تحديث قائمة القراءة. حاول مجدداً.');
      }
    }
  }

  String _itemTitle(Map<String, dynamic> item) {
    for (final key in ['title', 'claim', 'label', 'sourceTerm']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return item['url']?.toString() ?? item['sourceUrl']?.toString() ?? 'عنصر محفوظ';
  }

  String _itemSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    for (final key in ['status', 'verdict', 'sourceType', 'translatedTerm', 'sourceUrl', 'url']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) parts.add(value);
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final heading = switch (widget.kind) {
      'knowledge' => 'احفظ معلومة مع مصدرها',
      'evidence' => 'افصل الادعاء عن الأدلة',
      'sources' => 'سجّل مصدر المعلومة وحالته',
      'reading' => 'نظّم قراءاتك البحثية',
      'translation' => 'ترجم النص مع الحفاظ على المعنى والسياق',
      'glossary' => 'احتفظ بالمصطلحات عبر اللغات',
      _ => 'احتفظ بالمصطلحات عبر اللغات',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(heading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('تُحفظ العناصر في مساحة حسابك. تسجيل المصدر لا يعني أن صحته قد تم التحقق منها.'),
        const SizedBox(height: 16),
        ..._formFields(),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'جارٍ التنفيذ...' : (widget.kind == 'translation' ? 'ترجمة النص' : 'حفظ')),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        if (_translationResult.isNotEmpty && widget.kind == 'translation')
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_translationResult),
            ),
          ),
        if (widget.kind != 'translation') ...[
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Text('العناصر المحفوظة', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
          ]),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد عناصر محفوظة بعد.')))
          else ..._items.map((item) => Card(
            child: ListTile(
              title: Text(_itemTitle(item), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(_itemSubtitle(item), maxLines: 3, overflow: TextOverflow.ellipsis),
              leading: const Icon(Icons.bookmark_outline),
              trailing: widget.kind == 'reading'
                  ? PopupMenuButton<String>(
                      tooltip: 'إدارة حالة القراءة',
                      onSelected: (value) => _handleReadingAction(item, value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'to_read', child: Text('لم أبدأ')),
                        PopupMenuItem(value: 'reading', child: Text('قيد القراءة')),
                        PopupMenuItem(value: 'read', child: Text('اكتملت القراءة')),
                        PopupMenuItem(value: 'remove', child: Text('حذف من القائمة')),
                      ],
                    )
                  : null,
            ),
          )),
        ],
      ],
    );
  }
}
