import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'global_opportunity_radar_engine.dart';

const _radarAccent = Color(0xFF7DE2D1);
const _savedKey = 'nova.global_opportunity_radar.saved.v1';

class NovaGlobalOpportunityRadarScreen extends StatefulWidget {
  const NovaGlobalOpportunityRadarScreen({super.key});
  @override
  State<NovaGlobalOpportunityRadarScreen> createState() => _NovaGlobalOpportunityRadarScreenState();
}

class _NovaGlobalOpportunityRadarScreenState extends State<NovaGlobalOpportunityRadarScreen> {
  final _query = TextEditingController();
  String _category = 'All', _region = 'Worldwide', _country = 'All countries', _language = 'All languages';
  bool _busy = false, _showSaved = false;
  String? _status;
  final List<String> _sourceWarnings = [];
  List<GlobalOpportunityLead> _results = [], _saved = [];

  static const _categories = ['All', 'Work', 'Freelance', 'Translation', 'AI & Data', 'Content'];
  static const _regions = ['Worldwide', 'Africa', 'Europe', 'Asia', 'Americas'];
  static const _countries = ['All countries', 'Sudan'];
  static const _languages = ['All languages', 'Arabic', 'English', 'French', 'Spanish', 'Portuguese', 'German', 'Hindi', 'Swahili', 'Chinese', 'Japanese'];

  @override
  void initState() { super.initState(); _loadSaved(); }
  @override
  void dispose() { _query.dispose(); super.dispose(); }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = decodeSavedRadarLeads(prefs.getString(_savedKey));
      if (mounted) setState(() => _saved = saved);
    } catch (_) {
      if (mounted) setState(() => _status = 'تعذر تحميل القائمة المحفوظة من الهاتف.');
    }
  }

  String _localizedTerm(String language) {
    switch (language) {
      case 'Arabic': return 'عمل عن بعد وظيفة عمل حر';
      case 'French': return 'emploi télétravail freelance';
      case 'Spanish': return 'empleo remoto trabajo freelance';
      case 'Portuguese': return 'emprego remoto trabalho freelance';
      case 'German': return 'remote arbeit freelance job';
      case 'Hindi': return 'रिमोट नौकरी फ्रीलांस काम';
      case 'Swahili': return 'kazi za mbali ajira';
      case 'Chinese': return '远程工作 自由职业';
      case 'Japanese': return 'リモートワーク フリーランス';
      case 'English': return 'remote work freelance job';
      default: return '';
    }
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _status = null; _sourceWarnings.clear(); });
    final all = <GlobalOpportunityLead>[];
    final rawQuery = _query.text.trim();
    final expanded = expandRadarQueries(rawQuery, category: _category);
    final localized = _localizedTerm(_language);
    final queries = <String>{if (rawQuery.isNotEmpty) rawQuery, if (localized.isNotEmpty) localized, ...expanded}
        .where((s) => s.trim().isNotEmpty).take(4).toList();
    try {
      final requests = <Future<void>>[];
      for (final q in queries.take(3)) { requests.add(_fetchRemotive(q, all)); }
      requests.add(_fetchArbeitnow(all));
      await Future.wait(requests);
      final ranked = rankGlobalLeads(all, query: rawQuery, country: _country, region: _region);
      if (!mounted) return;
      setState(() {
        _results = ranked; _showSaved = false;
        _status = ranked.isEmpty
          ? 'لم نجد نتائج مطابقة في المصادر العامة التي استجابت. جرّب حذف بعض الكلمات أو اختيار كل الدول.'
          : 'تم فحص ' + all.length.toString() + ' سجل عام، وعرض ' + ranked.length.toString() + ' نتيجة بعد إزالة التكرار والفلاتر. افحص الأهلية والدفع من المصدر قبل التقديم.';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'تعذر إكمال البحث: ' + error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchRemotive(String query, List<GlobalOpportunityLead> into) async {
    try {
      final uri = Uri.https('remotive.com', '/api/remote-jobs', {'search': query, 'limit': '40'});
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) { _sourceWarnings.add('Remotive: HTTP ' + response.statusCode.toString()); return; }
      final payload = jsonDecode(response.body);
      final jobs = payload is Map && payload['jobs'] is List ? payload['jobs'] as List : const [];
      into.addAll(jobs.whereType<Map>().map((item) => parseRemotiveLead(Map<String, dynamic>.from(item))).whereType<GlobalOpportunityLead>());
    } catch (_) { _sourceWarnings.add('Remotive غير متاح حالياً'); }
  }

  Future<void> _fetchArbeitnow(List<GlobalOpportunityLead> into) async {
    try {
      final response = await http.get(Uri.https('www.arbeitnow.com', '/api/job-board-api')).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) { _sourceWarnings.add('Arbeitnow: HTTP ' + response.statusCode.toString()); return; }
      final payload = jsonDecode(response.body);
      final jobs = payload is Map && payload['data'] is List ? payload['data'] as List : const [];
      into.addAll(jobs.whereType<Map>().map((item) => parseArbeitnowLead(Map<String, dynamic>.from(item))).whereType<GlobalOpportunityLead>());
    } catch (_) { _sourceWarnings.add('Arbeitnow غير متاح حالياً'); }
  }

  Future<void> _toggleSaved(GlobalOpportunityLead lead) async {
    final exists = _saved.any((item) => item.id == lead.id);
    final next = [..._saved.where((item) => item.id != lead.id)];
    if (!exists) next.insert(0, lead);
    setState(() => _saved = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKey, jsonEncode(next.map((item) => item.toJson()).toList()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exists ? 'أزيلت من الفرص المحفوظة' : 'حُفظت على هذا الهاتف')));
    } catch (_) { if (mounted) setState(() => _status = 'تعذر حفظ الفرصة على الجهاز.'); }
  }

  Future<void> _openLead(GlobalOpportunityLead lead) async {
    final uri = Uri.tryParse(lead.url);
    if (uri == null || uri.scheme != 'https' || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط المصدر')));
    }
  }

  Widget _filter(String label, String value, List<String> options, ValueChanged<String?> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: value, isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: options.map((option) => DropdownMenuItem<String>(value: option, child: Text(option, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shown = _showSaved ? _saved : _results;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF155E59), Color(0xFF202039)]), borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.public, color: _radarAccent, size: 32), SizedBox(height: 10),
          Text('NOVA Global Opportunity Radar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('ابحث عالمياً عن وظائف عن بُعد وفرص العمل الحر والترجمة والبيانات والمحتوى عبر مصادر عامة متعددة اللغات.'),
          SizedBox(height: 8),
          Text('النتائج ليست ضمان قبول أو دفع. قد لا تسمح الوظيفة بالتقديم من السودان؛ تحقق من البلد ووسيلة السحب في المصدر الأصلي.', style: TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _query, textInputAction: TextInputAction.search, onSubmitted: (_) => _search(),
        decoration: const InputDecoration(labelText: 'ابحث بأي لغة', hintText: 'مثال: Arabic transcription, ترجمة، data annotation', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
      ),
      const SizedBox(height: 10),
      _filter('نوع الفرصة', _category, _categories, (v) => setState(() => _category = v ?? 'All')),
      _filter('المنطقة', _region, _regions, (v) => setState(() => _region = v ?? 'Worldwide')),
      _filter('بلد الأهلية المطلوب', _country, _countries, (v) => setState(() => _country = v ?? 'All countries')),
      _filter('لغة البحث الإضافية', _language, _languages, (v) => setState(() => _language = v ?? 'All languages')),
      Row(children: [
        Expanded(child: FilledButton.icon(
          onPressed: _busy ? null : _search,
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.radar),
          label: Text(_busy ? 'جاري البحث...' : 'ابحث عالمياً'),
        )),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: () => setState(() => _showSaved = !_showSaved), icon: const Icon(Icons.bookmark_outline), label: Text(_showSaved ? 'نتائج البحث' : 'المحفوظة (' + _saved.length.toString() + ')')),
      ]),
      if (_status != null) ...[const SizedBox(height: 10), Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_status!, textDirection: TextDirection.rtl)))],
      if (_sourceWarnings.isNotEmpty) ...[const SizedBox(height: 6), Text('مصادر لم تستجب: ' + _sourceWarnings.toSet().join('، '), style: const TextStyle(color: Colors.orangeAccent))],
      const SizedBox(height: 12),
      if (shown.isEmpty && !_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 26), child: Center(child: Text('لا توجد نتائج معروضة. اضغط «ابحث عالمياً» أو افتح المحفوظة.'))),
      ...shown.map(_leadCard),
      const SizedBox(height: 12),
      const Text('المصادر الحالية: Remotive وArbeitnow. البحث يستخدم كلمات مفتاحية متعددة اللغات، لكنه ليس ترجمة آلية شاملة لكل لغة ولا قاعدة وظائف تغطي كل دول العالم. لا يتم إرسال طلبات توظيف أو إنشاء حسابات أو دفع أي رسوم تلقائياً.', style: TextStyle(color: Colors.white70)),
    ]);
  }

  Widget _leadCard(GlobalOpportunityLead lead) {
    final saved = _saved.any((item) => item.id == lead.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.work_outline, color: _radarAccent), const SizedBox(width: 10),
          Expanded(child: Text(lead.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
          IconButton(tooltip: saved ? 'إزالة من المحفوظة' : 'حفظ الفرصة', onPressed: () => _toggleSaved(lead), icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: _radarAccent)),
        ]),
        if (lead.company.isNotEmpty) Text(lead.company, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Wrap(spacing: 6, runSpacing: 6, children: [
          Chip(label: Text(lead.source)),
          if (lead.country.isNotEmpty) Chip(label: Text(lead.country, overflow: TextOverflow.ellipsis)),
          if (lead.remote) const Chip(label: Text('Remote')),
          if (lead.salary.isNotEmpty) Chip(label: Text(lead.salary, overflow: TextOverflow.ellipsis)),
        ]),
        if (lead.category.isNotEmpty) Text('المجال: ' + lead.category),
        if (lead.description.isNotEmpty) ...[const SizedBox(height: 6), Text(lead.description, maxLines: 4, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(lead.publishedAt == null ? 'تاريخ النشر غير موضح' : 'نُشرت: ' + lead.publishedAt!.toLocal().toString().split(' ').first, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          TextButton.icon(onPressed: () => _openLead(lead), icon: const Icon(Icons.open_in_new), label: const Text('المصدر الأصلي')),
        ]),
      ])),
    );
  }
}
