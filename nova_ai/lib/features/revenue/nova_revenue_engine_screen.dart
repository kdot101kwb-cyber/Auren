import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_runtime.dart';

class NovaRevenueEngineScreen extends StatefulWidget {
  const NovaRevenueEngineScreen({super.key});

  @override
  State<NovaRevenueEngineScreen> createState() => _NovaRevenueEngineScreenState();
}

class _NovaRevenueEngineScreenState extends State<NovaRevenueEngineScreen> {
  final _skills = TextEditingController(text: 'Arabic-English writing, short-video scripts, SEO, social media content');
  final _languages = TextEditingController(text: 'Arabic and English');
  final _hours = TextEditingController(text: '3');
  final _budget = TextEditingController(text: '0');
  bool _enabled = false;
  bool _busy = false;
  String? _message;
  String? _report;
  String? _status;
  String? _error;

  static const _tracks = <({String title, String detail, String price, IconData icon})>[
    (title: 'خدمات الكتابة بالذكاء الاصطناعي', detail: 'وصف منتجات، كتابة إعلانية، تحرير وتدقيق', price: 'مثال $20–50', icon: Icons.edit_note),
    (title: 'السيرة الذاتية وLinkedIn', detail: 'تحسين السيرة ورسائل التقديم دون اختلاق خبرة', price: 'مثال $20–60', icon: Icons.badge_outlined),
    (title: 'سكريبتات الفيديو القصير', detail: 'فكرة + Hook + نص + دعوة للتفاعل', price: 'مثال $15–40', icon: Icons.video_library_outlined),
    (title: 'مقالات SEO وموجزات المحتوى', detail: 'بحث كلمات مفتاحية وهيكل مقال ومراجعة الحقائق', price: 'مثال $25–75', icon: Icons.search),
    (title: 'حزم منشورات السوشيال', detail: 'تقويم محتوى ونصوص لمنشورات متعددة', price: 'مثال $20–60', icon: Icons.campaign_outlined),
    (title: 'تصميمات رقمية وصور مصغرة', detail: 'قوالب وإعلانات وصور مصغرة بأدوات مجانية متاحة', price: 'مثال $10–40', icon: Icons.image_outlined),
    (title: 'قوالب رقمية قابلة للبيع', detail: 'قوائم متابعة، مخططات، قوالب Notion أو ملفات PDF أصلية', price: 'السعر حسب المنتج', icon: Icons.inventory_2_outlined),
    (title: 'ترجمة وتوطين عربي/إنجليزي', detail: 'ترجمة أولية مع تدقيق بشري ومراجعة المصطلحات', price: 'مثال $15–50', icon: Icons.translate),
    (title: 'مساعدة افتراضية للشركات الصغيرة', detail: 'تنظيم بيانات، تلخيص مستندات، أبحاث عامة', price: 'مثال $5–20/ساعة', icon: Icons.support_agent),
    (title: 'بحث العملاء المحتملين وتقارير السوق', detail: 'قوائم موثقة بمصادر وروابط، دون رسائل جماعية مزعجة', price: 'مثال $25–80', icon: Icons.insights_outlined),
  ];

  @override
  void dispose() {
    _skills.dispose();
    _languages.dispose();
    _hours.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<void> _load() async {
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      setState(() => _message = NovaFirebaseRuntime.initializationError ??
          'يلزم إعداد Firebase وApp Check قبل الاتصال بالخادم.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getNovaRevenueDashboard').call();
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() {
        _enabled = data['enabled'] == true;
        _status = data['status']?.toString();
        _report = data['report']?.toString();
        _error = data['error']?.toString();
        _message = 'تم تحديث حالة محرك الدخل من الخادم.';
      });
    } catch (error) {
      setState(() => _message = 'تعذر تحميل حالة محرك الدخل: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _configure(bool enabled) async {
    final hours = int.tryParse(_hours.text.trim());
    final budget = double.tryParse(_budget.text.trim());
    if (hours == null || budget == null) {
      setState(() => _message = 'أدخل عدد ساعات وميزانية صحيحة.');
      return;
    }
    if (!NovaFirebaseRuntime.initialized || !NovaFirebaseRuntime.appCheckActivated) {
      setState(() => _message = NovaFirebaseRuntime.initializationError ??
          'يلزم إعداد Firebase وApp Check قبل تشغيل المحرك.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _ensureSignedIn();
      final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('configureNovaRevenueEngine').call(<String, dynamic>{
        'enabled': enabled,
        'skills': _skills.text.trim(),
        'languages': _languages.text.trim(),
        'hoursPerDay': hours,
        'startingBudgetUsd': budget,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() {
        _enabled = data['enabled'] == true;
        if (data['report'] is String) _report = data['report'] as String;
        _status = data['status']?.toString();
        _message = data['message']?.toString() ?? (enabled ? 'تم إرسال إعداد التشغيل.' : 'تم إرسال طلب الإيقاف.');
      });
      await _load();
    } catch (error) {
      setState(() => _message = 'تعذر تحديث المحرك: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
    ),
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF155E59), Color(0xFF202039)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_graph, size: 32, color: Color(0xFF7DE2D1)),
          SizedBox(height: 10),
          Text('NOVA — محرك فرص الدخل', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('ينشئ حزمة عمل يومية فيها خدمات قابلة للبيع، عينة أعمال، رسالة تواصل للمراجعة، وخطة تنفيذ. الهدف $100 يومياً طموح وليس دخلاً مضموناً.'),
        ]),
      ),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_enabled ? Icons.cloud_done : Icons.pause_circle_outline,
              color: _enabled ? Colors.greenAccent : Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(_enabled ? 'المحرك مفعّل حسب إعدادات الخادم' : 'المحرك غير مفعّل أو لم تُحمّل حالته')),
          if (_status != null) Chip(label: Text(_status!)),
        ]),
        const SizedBox(height: 8),
        const Text('مهم: التشغيل بالخلفية يتطلب نشر Firebase، إعداد OPENROUTER_API_KEY، وتسجيل الدخول. المحرك لا يرسل عروضاً، ولا ينشئ حسابات، ولا ينشر محتوى أو ينفذ مدفوعات تلقائياً.'),
        const SizedBox(height: 12),
        _field('مهاراتك أو الخدمات التي تريد بيعها', _skills),
        _field('اللغات', _languages),
        _field('الساعات المتاحة يومياً (1–12)', _hours),
        _field('ميزانية البداية بالدولار (0–100)', _budget),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: _busy ? null : () => _configure(true),
            icon: const Icon(Icons.play_arrow),
            label: Text(_busy ? 'جاري الاتصال…' : 'تفعيل وإعداد خطة اليوم'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _configure(false),
            icon: const Icon(Icons.pause),
            label: const Text('إيقاف المحرك'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث الحالة'),
          ),
        ]),
      ]))),
      if (_message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_message!, textDirection: TextDirection.rtl)),
      if (_error != null && _error!.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('خطأ آخر تشغيل: $_error', style: const TextStyle(color: Colors.orangeAccent), textDirection: TextDirection.rtl))),
      if (_report != null && _report!.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('حزمة العمل اليومية من NOVA', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: SelectableText(_report!, textDirection: TextDirection.rtl))),
      ],
      const SizedBox(height: 20),
      const Text('10 مسارات دخل لاختبارها', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('الأسعار أدناه أمثلة للتسعير وليست بيانات سوق أو ضماناً للبيع. ابدأ بمسار واحد أو اثنين، واختبر الطلب قبل التوسع. تحقق من توفر المنصات ووسائل السحب في بلدك.'),
      const SizedBox(height: 10),
      for (var i = 0; i < _tracks.length; i++)
        Card(child: ListTile(
          leading: CircleAvatar(child: Icon(_tracks[i].icon)),
          title: Text('${i + 1}. ${_tracks[i].title}'),
          subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('${_tracks[i].detail}\n${_tracks[i].price}')),
          isThreeLine: true,
        )),
    ],
  );
}
