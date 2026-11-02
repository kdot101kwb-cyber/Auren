import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../builder/nova_app_builder_screen.dart';
import '../integrations/github_ci_screen.dart';
import '../integrations/integration_hub_screen.dart';

const _factoryKey = 'nova.application_factory.ideas.v1';

/// Arabic-first intake and control surface for idea-to-app and app lifecycle work.
/// Market monitoring and autonomous execution remain unavailable until real
/// source adapters and an isolated runner are configured.
class NovaApplicationFactoryScreen extends StatefulWidget {
  const NovaApplicationFactoryScreen({super.key});

  @override
  State<NovaApplicationFactoryScreen> createState() => _NovaApplicationFactoryScreenState();
}

class _NovaApplicationFactoryScreenState extends State<NovaApplicationFactoryScreen> {
  final _idea = TextEditingController();
  final _project = TextEditingController();
  final List<String> _savedIdeas = [];
  bool _loading = true;
  String _mode = 'new';

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  @override
  void dispose() {
    _idea.dispose();
    _project.dispose();
    super.dispose();
  }

  Future<void> _loadIdeas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final values = prefs.getStringList(_factoryKey) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _savedIdeas..clear()..addAll(values.take(20));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveIdea() async {
    final value = _idea.text.trim();
    if (value.length < 12) {
      _notice('اكتب وصفاً للفكرة لا يقل عن 12 حرفاً.');
      return;
    }
    final next = <String>[value, ..._savedIdeas.where((item) => item != value)].take(20).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_factoryKey, next);
      if (!mounted) return;
      setState(() {
        _savedIdeas..clear()..addAll(next);
      });
      _notice('حُفظت الفكرة على هذا الجهاز. لم يبدأ بحث سوق أو بناء تلقائي بعد.');
    } catch (_) {
      _notice('تعذر حفظ الفكرة على الجهاز.');
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _builderPrompt() {
    final idea = _idea.text.trim();
    final project = _project.text.trim();
    if (_mode == 'existing') {
      return 'افحص التطبيق الموجود أولاً ولا تعدّل أي ملف قبل الفحص. رابط المستودع/المشروع: $project\nالمطلوب: $idea\n'
          'ابدأ بتقرير حالة المنتج والسوق، ثم حدد هل المطلوب إصلاح أم تحديث أم إعادة تصميم. افحص البنية والاعتماديات والاختبارات والأمان والتراخيص وCI. '
          'اكتب معايير قبول وخطة اختبار وتراجع. لا تدّع تنفيذ إصلاح أو مراقبة سوق أو بناء APK دون عامل موصول ونتائج فعلية.';
    }
    return 'فكرة التطبيق: $idea\n'
        'قبل التنفيذ، أعد موجز منتج يتضمن المستخدمين والمشكلة وحالات الاستخدام والمنافسين وطلب السوق والأدلة وروابط المصادر وحداثتها والثقة والفجوات. '
        'حدد هل الأنسب تطبيق جديد أم ميزة داخل منتج موجود. غطِّ UX/UI وRTL وإمكانية الوصول والعمل دون اتصال والعمارة وقاعدة البيانات وواجهات API والمصادقة والأمن والخصوصية والتراخيص والاختبارات وCI والبناء والتوزيع والتشغيل والدعم والتكلفة والتسعير والتسويق. '
        'لا تخترع أرقام سوق أو إيرادات. افصل الحقائق عن الفرضيات، وضع معايير قبول وخطة تراجع. لا تدّع تنفيذ بناء أو بحث حي دون مصادر وعامل فعلي.';
  }

  void _openBuilder() {
    if (_mode == 'existing' && _project.text.trim().isEmpty) {
      _notice('أضف رابط المشروع أو وصف مكانه أولاً.');
      return;
    }
    if (_idea.text.trim().length < 12) {
      _notice('اكتب المطلوب بوضوح أولاً.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NovaAppBuilderScreen(initialPrompt: _builderPrompt()),
    ));
  }

  Widget _statusCard({required IconData icon, required String title, required String status, required String detail, Color? color}) {
    final accent = color ?? Theme.of(context).colorScheme.secondary;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: accent, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$status\n$detail', textDirection: TextDirection.rtl),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF174C55)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 34, color: Colors.white),
              SizedBox(height: 10),
              Text('مصنع التطبيقات الذكي', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('أعطِ NOVA فكرة أو مشروعاً قائماً. تتولى المنظومة دراسة المتطلبات وتوجيه العمل من التخطيط إلى الاختبار والتسليم.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'new', label: Text('فكرة جديدة'), icon: Icon(Icons.lightbulb_outline)),
            ButtonSegment(value: 'existing', label: Text('تطبيق موجود'), icon: Icon(Icons.phone_android)),
          ],
          selected: {_mode},
          onSelectionChanged: (values) => setState(() => _mode = values.first),
        ),
        const SizedBox(height: 12),
        if (_mode == 'existing') ...[
          TextField(
            controller: _project,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'رابط GitHub أو المشروع',
              hintText: 'https://github.com/owner/repository',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _idea,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: _mode == 'new' ? 'اشرح فكرة التطبيق' : 'ما الذي تريد فحصه أو تحديثه؟',
            hintText: _mode == 'new'
                ? 'مثال: تطبيق تعليم يعمل دون إنترنت ويخدم الطلاب...'
                : 'مثال: افحص الأخطاء، احتياجات المستخدمين، المنافسين، والتحديثات المطلوبة...',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _openBuilder,
          icon: const Icon(Icons.rocket_launch),
          label: const Text('انتقل إلى بناء المهمة'),
        ),
        OutlinedButton.icon(
          onPressed: _saveIdea,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('احفظ الفكرة على الجهاز'),
        ),
        const SizedBox(height: 16),
        const Text('وكيل مراقبة سوق التطبيقات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _statusCard(
          icon: Icons.travel_explore,
          title: 'App Market Scout',
          status: 'التصميم معتمد — مصادر السوق الحية غير موصولة بعد',
          detail: 'سيبحث في احتياجات المستخدمين، تقييمات المتاجر، المنافسين، اتجاهات البحث، تحديثات الأنظمة، ومشكلات التطبيقات. سيقرر: تطبيق جديد، تحديث، ميزة، انتظار أدلة، أو استبعاد.',
          color: Colors.orange,
        ),
        _statusCard(
          icon: Icons.health_and_safety_outlined,
          title: 'مراقبة التطبيقات الحالية',
          status: 'تحتاج ربط مصادر كل تطبيق',
          detail: 'أعطال وأداء ومراجعات المستخدمين والثغرات وتحديثات SDK والسياسات وتغيرات المنافسين.',
        ),
        const SizedBox(height: 14),
        const Text('متطلبات كل تطبيق', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _RequirementTile(icon: Icons.people_outline, title: 'المستخدم والسوق', detail: 'المشكلة، الجمهور، المنافسون، الطلب، التميز، والتكلفة.'),
        const _RequirementTile(icon: Icons.design_services_outlined, title: 'التصميم وتجربة الاستخدام', detail: 'رحلات المستخدم، الواجهات، RTL، اللغات، وإمكانية الوصول.'),
        const _RequirementTile(icon: Icons.account_tree_outlined, title: 'الهندسة والبنية', detail: 'التقنيات، قاعدة البيانات، API، العمل دون اتصال، والتوسع.'),
        const _RequirementTile(icon: Icons.lock_outline, title: 'الأمان والخصوصية', detail: 'الصلاحيات، حماية الأسرار، التراخيص، والبيانات.'),
        const _RequirementTile(icon: Icons.fact_check_outlined, title: 'الجودة والاختبارات', detail: 'تحليل الكود، اختبارات الوحدات والواجهات والتكامل والأداء.'),
        const _RequirementTile(icon: Icons.rocket_launch_outlined, title: 'البناء والإطلاق', detail: 'CI، APK/AAB، التوقيع، المتاجر، التراجع، والمراقبة.'),
        const _RequirementTile(icon: Icons.support_agent_outlined, title: 'التشغيل والنمو', detail: 'الأعطال، الدعم، النسخ الاحتياطي، التسويق، والتطوير المستمر.'),
        const SizedBox(height: 14),
        const Text('مركز التشغيل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        _statusCard(
          icon: Icons.monitor_heart_outlined,
          title: 'DevOps Command Center',
          status: 'يمكن فتح نتائج GitHub الحالية',
          detail: 'يعرض نتائج GitHub Actions المتاحة. ربط CircleCI وGitLab والمراقبة الحية يحتاج تكاملات آمنة إضافية.',
          color: Colors.green,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GitHubCiScreen())),
              icon: const Icon(Icons.code),
              label: const Text('نتائج GitHub'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IntegrationHubScreen())),
              icon: const Icon(Icons.hub_outlined),
              label: const Text('الخدمات والربط'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('الأفكار المحفوظة على هذا الجهاز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_loading) const LinearProgressIndicator(),
        if (!_loading && _savedIdeas.isEmpty) const Text('لا توجد أفكار محفوظة بعد.'),
        ..._savedIdeas.map((idea) => Card(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(idea, maxLines: 3, overflow: TextOverflow.ellipsis),
            onTap: () => setState(() { _mode = 'new'; _idea.text = idea; }),
          ),
        )),
        const SizedBox(height: 10),
        const Text(
          'تنبيه صريح: حفظ الفكرة لا يعني أن السوق تم فحصه. طلب البناء الحالي يُسجّل في الطابور فقط حتى يتصل عامل بناء معزول. لن تعرض NOVA حالة «جاهز» قبل نجاح الاختبارات والبناء الفعلي.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
    ),
  );
}
