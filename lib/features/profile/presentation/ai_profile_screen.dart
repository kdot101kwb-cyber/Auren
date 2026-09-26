import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/profile_mode_service.dart';

class AurenAiProfileScreen extends StatefulWidget {
  const AurenAiProfileScreen({super.key});
  @override State<AurenAiProfileScreen> createState() => _AurenAiProfileScreenState();
}

class _AurenAiProfileScreenState extends State<AurenAiProfileScreen> {
  final _auth = FirebaseAurenAuthService();
  final _service = AurenProfileModeService();
  AurenProfileMode _mode = AurenProfileMode.personal;
  bool _discoverable = true, _saving = false;
  final _headline = TextEditingController(), _bio = TextEditingController();
  final _skills = TextEditingController(), _interests = TextEditingController(), _links = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    final data = await _service.get(uid, _mode);
    if (mounted) _apply(data);
  }

  void _apply(AurenProfileModeData d) {
    _headline.text = d.headline; _bio.text = d.bio;
    _skills.text = d.skills.join(', '); _interests.text = d.interests.join(', ');
    _links.text = d.links.join(', '); _discoverable = d.discoverable;
    setState(() {});
  }

  Future<void> _changeMode(AurenProfileMode mode) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    setState(() => _mode = mode);
    final data = await _service.get(uid, mode);
    if (mounted) _apply(data);
  }

  List<String> _split(String v) => v.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList();

  String _summary(AurenProfileModeData d) {
    final focus = d.skills.isNotEmpty ? d.skills.take(3).join('، ') :
        (d.interests.isNotEmpty ? d.interests.take(3).join('، ') : 'اهتماماتك وأهدافك');
    switch (d.mode) {
      case AurenProfileMode.personal: return 'ملف شخصي يركز على التواصل والاهتمامات: $focus.';
      case AurenProfileMode.creator: return 'ملف Creator يبرز المحتوى والمشاريع الإبداعية: $focus.';
      case AurenProfileMode.professional: return 'ملف مهني يبرز المهارات والخبرة والفرص: $focus.';
      case AurenProfileMode.business: return 'ملف Business يبرز الخدمات والمنتجات وفرص النمو: $focus.';
    }
  }

  Future<void> _save() async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _service.save(uid: uid, mode: _mode, headline: _headline.text, bio: _bio.text,
        skills: _split(_skills.text), interests: _split(_interests.text),
        links: _split(_links.text), discoverable: _discoverable);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ AI Profile.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override Widget build(BuildContext context) {
    final uid = _auth.currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    return Scaffold(
      appBar: AppBar(title: const Text('AI Profile')),
      body: StreamBuilder<AurenProfileModeData>(
        stream: _service.watch(uid, _mode),
        builder: (context, snapshot) {
          final data = snapshot.data ?? AurenProfileModeData.empty(_mode);
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('Profile Modes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('AUREN يغيّر طريقة عرض ملفك حسب السياق — بدون إنشاء حسابات منفصلة.'),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: AurenProfileMode.values.map((m) => ChoiceChip(
                label: Text(m.label), selected: _mode == m, onSelected: (_) => _changeMode(m),
              )).toList()),
              const SizedBox(height: 12),
              Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                title: Text('${_mode.label} AI Profile'), subtitle: Text(_mode.description))),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AI Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6), Text(_summary(data)),
                ],
              ))),
              TextField(controller: _headline, maxLength: 120, decoration: const InputDecoration(labelText: 'Headline')),
              TextField(controller: _bio, maxLength: 800, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio')),
              TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Skills', hintText: 'Flutter, Design, Business')),
              TextField(controller: _interests, decoration: const InputDecoration(labelText: 'Interests', hintText: 'Music, Travel, Sports')),
              TextField(controller: _links, decoration: const InputDecoration(labelText: 'Links', hintText: 'ضع الروابط مفصولة بفواصل')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Discoverable'),
                subtitle: const Text('اسمح لـAUREN باستخدام هذا الوضع في الاكتشاف والمطابقة.'),
                value: _discoverable, onChanged: (v) => setState(() => _discoverable = v)),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save profile mode')),
            ],
          );
        },
      ),
    );
  }

  @override void dispose() {
    _headline.dispose(); _bio.dispose(); _skills.dispose(); _interests.dispose(); _links.dispose(); super.dispose();
  }
}
