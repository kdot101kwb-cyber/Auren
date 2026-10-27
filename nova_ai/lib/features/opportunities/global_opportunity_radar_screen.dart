import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'global_opportunity_radar.dart';

const _radarAccent = Color(0xFF9B87FF);
const _savedKey = 'nova.global_opportunity_radar.saved.v1';

class GlobalOpportunityRadarScreen extends StatefulWidget {
  const GlobalOpportunityRadarScreen({super.key});

  @override
  State<GlobalOpportunityRadarScreen> createState() => _GlobalOpportunityRadarScreenState();
}

class _GlobalOpportunityRadarScreenState extends State<GlobalOpportunityRadarScreen> {
  final _query = TextEditingController();
  final Set<String> _savedIds = <String>{};
  String _category = 'الكل';
  bool _savedOnly = false;
  bool _loadingSaved = true;
  bool _marketLoading = false;
  String? _marketError;
  List<Map<String, dynamic>> _marketCandidates = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _marketTools = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getStringList(_savedKey) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _savedIds
          ..clear()
          ..addAll(saved);
        _loadingSaved = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _toggleSaved(GlobalOpportunity opportunity) async {
    setState(() {
      if (!_savedIds.add(opportunity.id)) _savedIds.remove(opportunity.id);
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(_savedKey, _savedIds.toList()..sort());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ القائمة على هذا الجهاز.')),
      );
    }
  }

  Future<void> _openSource(GlobalOpportunity opportunity) async {
    final uri = Uri.tryParse(opportunity.url);
    if (uri == null || !uri.hasScheme || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المصدر. انسخ الرابط أو حاول لاحقاً.')),
      );
    }
  }


  Future<void> _scanMarket() async {
    setState(() { _marketLoading = true; _marketError = null; });
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getNovaMarketIntelligence')
          .call(<String, dynamic>{});
      final data = result.data;
      if (data is! Map) throw StateError('Invalid market scan response.');
      final rawCandidates = data['opportunities'];
      final rawTools = data['tools'];
      if (!mounted) return;
      setState(() {
        _marketCandidates = rawCandidates is List
            ? rawCandidates.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
            : <Map<String, dynamic>>[];
        _marketTools = rawTools is List
            ? rawTools.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
            : <Map<String, dynamic>>[];
      });
    } catch (_) {
      if (mounted) setState(() => _marketError = 'تعذر فحص السوق الآن. تأكد من تسجيل الدخول ونشر وظيفة الرادار واتصال الإنترنت.');
    } finally {
      if (mounted) setState(() => _marketLoading = false);
    }
  }

  Future<void> _openMarketTool(Map<String, dynamic> tool) async {
    final uri = Uri.tryParse(tool['url']?.toString() ?? '');
    if (uri == null || uri.scheme != 'https' ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح أداة البحث.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = searchGlobalOpportunities(
      query: _query.text,
      category: _category,
      savedIds: _savedIds,
      savedOnly: _savedOnly,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرادار العالمي للفرص'),
        actions: [
          IconButton(
            tooltip: _savedOnly ? 'عرض كل الفرص' : 'عرض المحفوظة',
            onPressed: () => setState(() => _savedOnly = !_savedOnly),
            icon: Icon(_savedOnly ? Icons.bookmarks : Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.public, color: _radarAccent, size: 30),
                SizedBox(height: 10),
                Text('فرص من العالم وبكل اللغات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('ابحث بالعربية أو الإنجليزية أو بلغات أخرى. القائمة الأولية تعمل دون إنترنت، والروابط تفتح المصادر الرسمية عند توفر الاتصال.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.query_stats, color: _radarAccent),
                    SizedBox(width: 8),
                    Expanded(child: Text('تحليل السوق واختيار الفرص', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 6),
                  const Text('10 أدوات بحث شبيهة بـ Semrush مع إشارات عامة من مصادر متعددة. يحتاج الفحص إلى الإنترنت.'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _marketLoading ? null : _scanMarket,
                      icon: _marketLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.travel_explore),
                      label: Text(_marketLoading ? 'يفحص السوق...' : 'افحص السوق ورتّب الفرص'),
                    ),
                  ),
                  if (_marketError != null) ...[
                    const SizedBox(height: 8),
                    Text(_marketError!, style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                  if (_marketCandidates.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('مرشحات مرتبة: ${_marketCandidates.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ..._marketCandidates.map((item) {
                      final ready = item['eligibleForZeroCostTest'] == true;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(ready ? Icons.task_alt : Icons.manage_search,
                            color: ready ? Colors.greenAccent : _radarAccent),
                        title: Text(item['title']?.toString() ?? 'فرصة بدون عنوان'),
                        subtitle: Text('${item['readiness'] ?? 'research_more'} • الدرجة ${item['score'] ?? '—'} • مصادر مستقلة: ${item['sourceCount'] ?? 0}'),
                        trailing: ready ? const Icon(Icons.check_circle_outline) : null,
                        isThreeLine: false,
                      );
                    }),
                    const Text('حتى المرشح الجاهز يحتاج اختبار طلب مجاني والتحقق من أهلية الدفع؛ لا توجد ضمانات دخل.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                  if (_marketTools.isNotEmpty) ...[
                    const Divider(),
                    const Text('أدوات البحث الرسمية', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._marketTools.map((tool) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tool['name']?.toString() ?? ''),
                      subtitle: Text(tool['access']?.toString() ?? ''),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openMarketTool(tool),
                    )),
                  ],
                ],
              ),
            ),
          ),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'ابحث عن مهارة أو فرصة بأي لغة',
              hintText: 'مثال: ترجمة، remote job، transcription، traducción، 远程工作',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(onPressed: () { _query.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: globalOpportunityCategories.map((category) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(_savedOnly ? 'الفرص المحفوظة: ${opportunities.length}' : 'مصادر عالمية مبدئية: ${opportunities.length}')),
              if (_loadingSaved) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              TextButton.icon(
                onPressed: () => setState(() => _savedOnly = !_savedOnly),
                icon: Icon(_savedOnly ? Icons.public : Icons.bookmark),
                label: Text(_savedOnly ? 'كل الفرص' : 'المحفوظة'),
              ),
            ],
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'مهم: هذه أدلة دخول إلى منصات، وليست وظائف مؤكدة أو ضمان دخل. أهلية السودان ووسائل السحب تختلف؛ تحقق من الشروط الرسمية قبل التسجيل أو تقديم بياناتك أو أداء اختبار طويل.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          if (opportunities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('لا توجد نتائج مطابقة. جرّب كلمة أخرى أو اختر «الكل».')),
            ),
          ...opportunities.map((opportunity) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(child: Icon(Icons.travel_explore)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opportunity.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${opportunity.sourceName} • ${opportunity.category}', style: const TextStyle(color: _radarAccent)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _savedIds.contains(opportunity.id) ? 'إزالة من المحفوظة' : 'حفظ الفرصة',
                        onPressed: () => _toggleSaved(opportunity),
                        icon: Icon(_savedIds.contains(opportunity.id) ? Icons.bookmark : Icons.bookmark_border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(opportunity.summary),
                  const SizedBox(height: 8),
                  Text('المهارات: ${opportunity.skills}'),
                  Text('اللغة: ${opportunity.languages}'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(child: Text(opportunity.paymentNote, style: const TextStyle(color: Colors.amberAccent))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSource(opportunity),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('فتح المصدر الرسمي: ${opportunity.sourceName}'),
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
          const Text(
            'التحديث المباشر يحتاج اتصالاً ومصادر/واجهة خلفية موثوقة. هذه النسخة توفر دليلاً متعدد اللغات يعمل محلياً، ولا تدّعي أن كل الفرص أو المدفوعات متاحة في كل بلد.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
