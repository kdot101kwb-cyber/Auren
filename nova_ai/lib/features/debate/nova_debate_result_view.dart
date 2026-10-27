import 'package:flutter/material.dart';

/// Renders the bounded, server-normalized strategic review without presenting
/// model JSON as if it were a verified execution report.
class NovaDebateResultView extends StatelessWidget {
  const NovaDebateResultView({super.key, required this.result});

  final Map<String, dynamic> result;

  String _text(Object? value, [String fallback = 'غير مذكور']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<Map<String, dynamic>> _items(String key) {
    final value = result[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _text(result['recommendation'], 'revise');
    final confidence = (result['confidence'] is num)
        ? ((result['confidence'] as num).clamp(0, 1) * 100).round()
        : null;
    final objections = _items('objections');
    final alternatives = _items('alternatives');
    final plan = _items('plan');
    final risks = _items('risks');
    final missing = result['missingEvidence'] is List
        ? (result['missingEvidence'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('التوصية: $recommendation', style: Theme.of(context).textTheme.titleMedium),
              if (confidence != null) Text('درجة الثقة التقديرية: $confidence%'),
              const SizedBox(height: 8),
              Text(_text(result['summary']), textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Text(_text(result['decisionRationale']), textDirection: TextDirection.rtl),
            ]),
          ),
        ),
        _section(context, 'اعتراضات المجلس', objections, (item) => [
          _heading(item, 'title'),
          _text(item['role']),
          _text(item['reason']),
          'الخطورة: ${_text(item['severity'])}',
          'التخفيف: ${_text(item['mitigation'])}',
        ]),
        _section(context, 'البدائل', alternatives, (item) => [
          _heading(item, 'name'),
          'الفائدة: ${_text(item['benefit'])}',
          'التكلفة: ${_text(item['cost'])}',
          'المخاطر: ${_text(item['risk'])}',
        ]),
        _section(context, 'خطة العمل ومعايير التحقق', plan, (item) => [
          _heading(item, 'step'),
          'السبب: ${_text(item['reason'])}',
          'التحقق: ${_text(item['verification'])}',
          'الجهد التقديري: ${_text(item['estimatedEffort'])}',
        ], numbered: true),
        _section(context, 'المخاطر والتخفيف', risks, (item) => [
          _heading(item, 'risk'),
          'الاحتمال: ${_text(item['likelihood'])}',
          'الأثر: ${_text(item['impact'])}',
          'التخفيف: ${_text(item['mitigation'])}',
        ]),
        if (missing.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الأدلة الناقصة', style: Theme.of(context).textTheme.titleMedium),
                ...missing.map((item) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.help_outline),
                  title: Text(item, textDirection: TextDirection.rtl),
                )),
              ]),
            ),
          ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'هذه توصيات مولّدة وليست حقائق متحققة. لم يُنفّذ أي تغيير في المستودع ضمن مراجعة النقاش.',
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
        ],
      ),
    );
  }

  String _heading(Map<String, dynamic> item, String key) => _text(item[key]);

  Widget _section(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    List<String> Function(Map<String, dynamic>) lines, {
    bool numbered = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (numbered) Padding(
                padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
                child: CircleAvatar(radius: 12, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12))),
              ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lines(entry.value).first, style: const TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                ...lines(entry.value).skip(1).map((line) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(line, textDirection: TextDirection.rtl),
                )),
              ])),
            ]),
          )),
        ]),
      ),
    );
  }
}
