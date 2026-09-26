import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/profile_mode_service.dart';
import '../../../services/social/adaptive_profile_service.dart';
import '../../creator/presentation/creator_studio_screen.dart';

class AurenAiProfileScreen extends StatefulWidget {
  const AurenAiProfileScreen({super.key});
  @override State<AurenAiProfileScreen> createState() => _AurenAiProfileScreenState();
}

class _AurenAiProfileScreenState extends State<AurenAiProfileScreen> {
  final _auth = FirebaseAurenAuthService();
  final _service = AurenProfileModeService();
  final _adaptive = const AurenAdaptiveProfileService();
  AurenAdaptiveProfileResult? _adaptiveResult;
  AurenProfileContext _context = AurenProfileContext.unknown;
  bool _autoContext = true;
  AurenProfileMode _mode = AurenProfileMode.personal;
  bool _loading = true, _saving = false, _discoverable = true, _showContact = false;
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  final _interests = TextEditingController();
  final _goals = TextEditingController();
  final _languages = TextEditingController();
  final _services = TextEditingController();
  final _achievements = TextEditingController();
  final _links = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      final mode = await _service.getActiveMode(uid);
      final data = await _service.get(uid, mode);
      if (!mounted) return;
      _mode = mode; _apply(data, rebuild: false);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _apply(AurenProfileModeData d, {bool rebuild = true}) {
    _headline.text = d.headline; _bio.text = d.bio;
    _skills.text = d.skills.join(', '); _interests.text = d.interests.join(', ');
    _goals.text = d.goals.join(', '); _languages.text = d.languages.join(', ');
    _services.text = d.services.join(', '); _achievements.text = d.achievements.join(', ');
    _links.text = d.links.join(', '); _discoverable = d.discoverable; _showContact = d.showContact;
    if (rebuild) setState(() {});
  }

  Future<void> _changeMode(AurenProfileMode mode) async {
    final uid = _auth.currentUserId; if (uid == null || _saving) return;
    setState(() { _mode = mode; _loading = true; });
    try { await _service.setActiveMode(uid, mode); _apply(await _service.get(uid, mode)); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<String> _split(String v) => v.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();

  String _summary(AurenProfileModeData d) {
    final focus = d.mode == AurenProfileMode.business ? d.services : (d.skills.isNotEmpty ? d.skills : d.interests);
    final f = focus.take(3).join('، ');
    if (f.isEmpty && d.goals.isEmpty) return 'أكمل بياناتك، وسيستخدم AUREN هذه المعلومات لبناء عرض مناسب للسياق.';
    final target = d.goals.take(2).join('، ');
    return '${d.mode.label}: ${f.isEmpty ? 'ملف متكيف' : f}${target.isEmpty ? '' : ' • الهدف: $target'}';
  }

  Future<void> _analyzeAdaptiveMode() async {
    final uid = _auth.currentUserId;
    if (uid == null || _loading) return;
    setState(() => _adaptiveResult = null);
    final data = await _service.get(uid, _mode);
    final result = _adaptive.suggest(
      currentMode: _mode,
      context: _autoContext ? AurenProfileContext.unknown : _context,
      profile: data,
      intent: [_headline.text, _bio.text, _skills.text, _interests.text, _goals.text, _services.text].join(' '),
    );
    if (mounted) setState(() => _adaptiveResult = result);
  }

  Future<void> _applyAdaptiveMode() async {
    final result = _adaptiveResult;
    if (result == null || result.mode == _mode) return;
    await _changeMode(result.mode);
    if (mounted) setState(() => _adaptiveResult = null);
  }

  Future<void> _save() async {
    final uid = _auth.currentUserId; if (uid == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _service.save(uid: uid, mode: _mode, headline: _headline.text, bio: _bio.text,
        skills: _split(_skills.text), interests: _split(_interests.text), links: _split(_links.text),
        goals: _split(_goals.text), languages: _split(_languages.text), services: _split(_services.text),
        achievements: _split(_achievements.text), discoverable: _discoverable, showContact: _showContact);
      await _service.setActiveMode(uid, _mode);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ AI Profile والوضع النشط.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Widget _field(TextEditingController c, String label, {String? hint, int maxLines = 1, int? maxLength}) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, maxLines: maxLines, maxLength: maxLength,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder())));

  @override Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(title: const Text('AI Profile'), actions: [IconButton(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : StreamBuilder<AurenProfileModeData>(
        stream: _service.watch(uid, _mode), builder: (context, snap) {
          final data = snap.data ?? AurenProfileModeData.empty(_mode);
          return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 32), children: [
            const Text('AI Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6), const Text('ملف واحد يتكيّف مع السياق بدل إنشاء حسابات منفصلة.'),
            const SizedBox(height: 18),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.auto_awesome), SizedBox(width: 8), Text('Profile Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: AurenProfileMode.values.map((m) => ChoiceChip(label: Text(m.label), selected: _mode == m, onSelected: (_) => _changeMode(m))).toList()),
              const SizedBox(height: 10), Text(_mode.description),
            ]))),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.auto_awesome), SizedBox(width: 8), Text('Adaptive Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    const Text('AUREN يفهم السياق ويقترح الوضع المناسب، لكن القرار النهائي لك دائماً.'),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto context'),
                      subtitle: const Text('دع AUREN يستنتج السياق من بيانات الملف عند التحليل.'),
                      value: _autoContext,
                      onChanged: (v) => setState(() { _autoContext = v; _adaptiveResult = null; }),
                    ),
                    if (!_autoContext)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AurenProfileContext.values.where((c) => c != AurenProfileContext.unknown).map((c) => ChoiceChip(
                          label: Text(c.label),
                          selected: _context == c,
                          onSelected: (_) => setState(() { _context = c; _adaptiveResult = null; }),
                        )).toList(),
                      ),
                    const SizedBox(height: 10),
                    if (_adaptiveResult == null)
                      OutlinedButton.icon(onPressed: _analyzeAdaptiveMode, icon: const Icon(Icons.psychology_outlined), label: const Text('حلّل السياق الحالي'))
                    else ...[
                      Text('الاقتراح: ' + _adaptiveResult!.mode.label + ' • ' + _adaptiveResult!.confidence.toString() + '%', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_adaptiveResult!.reason),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (_adaptiveResult!.mode != _mode)
                          FilledButton.icon(onPressed: _applyAdaptiveMode, icon: const Icon(Icons.check), label: Text('استخدم ' + _adaptiveResult!.mode.label)),
                        TextButton(onPressed: () => setState(() => _adaptiveResult = null), child: const Text('ليس الآن')),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_mode == AurenProfileMode.creator) ...[
              Card(child: ListTile(
                leading: const Icon(Icons.video_camera_front_rounded),
                title: const Text('Creator Studio'),
                subtitle: const Text('أنشئ وانشر وتابع أداء محتواك.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenCreatorStudioScreen())),
              )),
              const SizedBox(height: 8),
            ],
            const Text('AUREN AI View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8), Text(_summary(data)),
              const SizedBox(height: 12),
              const Text('AUREN يعرض المعلومات المناسبة للسياق؛ لا ينشئ شخصية أو معلومة غير موجودة في ملفك.'),
            ]))),
            _field(_headline, 'Headline', hint: 'مثال: مصمم ومنشئ منتجات رقمية', maxLength: 120),
            _field(_bio, 'Bio', hint: 'عرّف بنفسك باختصار', maxLines: 4, maxLength: 800),
            _field(_skills, 'Skills', hint: 'Flutter, Design, Business'),
            _field(_interests, 'Interests', hint: 'Music, Travel, Sports'),
            _field(_goals, 'Goals', hint: 'بناء مشروع، إيجاد شريك، تعلم مهارة'),
            _field(_languages, 'Languages', hint: 'العربية, English'),
            if (_mode == AurenProfileMode.creator || _mode == AurenProfileMode.business)
              _field(_services, _mode == AurenProfileMode.creator ? 'What I create' : 'Services / Products'),
            if (_mode != AurenProfileMode.personal) _field(_achievements, 'Achievements', hint: 'مشروع، شهادة، إنجاز...'),
            _field(_links, 'Links', hint: 'ضع الروابط مفصولة بفواصل'),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Discoverable'), value: _discoverable,
              subtitle: const Text('استخدم هذا الوضع في البحث والمطابقة والاكتشاف.'), onChanged: (v) => setState(() => _discoverable = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show contact'), value: _showContact,
              subtitle: const Text('تحكم في إظهار وسيلة التواصل العامة في هذا الوضع.'), onChanged: (v) => setState(() => _showContact = v)),
            const SizedBox(height: 8), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving…' : 'Save AI Profile')),
          ]);
        }),
    );
  }

  @override void dispose() {
    _headline.dispose(); _bio.dispose(); _skills.dispose(); _interests.dispose(); _goals.dispose(); _languages.dispose();
    _services.dispose(); _achievements.dispose(); _links.dispose(); super.dispose();
  }
}