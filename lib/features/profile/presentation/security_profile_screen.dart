import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/profile_mode_service.dart';

/// Privacy controls for each AUREN profile mode.
class AurenSecurityProfileScreen extends StatefulWidget {
  const AurenSecurityProfileScreen({super.key});

  @override
  State<AurenSecurityProfileScreen> createState() => _AurenSecurityProfileScreenState();
}

class _AurenSecurityProfileScreenState extends State<AurenSecurityProfileScreen> {
  final AurenProfileModeService _service = AurenProfileModeService();
  final Map<AurenProfileMode, AurenProfileModeData> _values = {};
  bool _loading = true;
  AurenProfileMode? _savingMode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAurenAuthService().currentUserId;
    if (uid == null) {
      setState(() { _loading = false; _error = 'سجّل الدخول أولاً لفتح إعدادات الخصوصية.'; });
      return;
    }
    try {
      final entries = await Future.wait(AurenProfileMode.values.map((mode) async =>
          MapEntry(mode, await _service.get(uid, mode))));
      if (!mounted) return;
      setState(() {
        _values
          ..clear()
          ..addEntries(entries);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذر تحميل إعدادات الخصوصية. حاول مرة أخرى.'; });
    }
  }

  Future<void> _update(AurenProfileMode mode, {bool? discoverable, bool? showContact}) async {
    final uid = FirebaseAurenAuthService().currentUserId;
    final current = _values[mode];
    if (uid == null || current == null || _savingMode != null) return;
    final nextDiscoverable = discoverable ?? current.discoverable;
    final nextShowContact = showContact ?? current.showContact;
    setState(() { _savingMode = mode; _error = null; });
    try {
      await _service.updatePrivacy(
        uid: uid,
        mode: mode,
        discoverable: nextDiscoverable,
        showContact: nextShowContact,
      );
      if (!mounted) return;
      setState(() {
        _values[mode] = current.copyWithDiscoverable(nextDiscoverable);
        _values[mode] = AurenProfileModeData(
          mode: current.mode,
          headline: current.headline,
          bio: current.bio,
          skills: current.skills,
          interests: current.interests,
          links: current.links,
          goals: current.goals,
          languages: current.languages,
          services: current.services,
          achievements: current.achievements,
          discoverable: nextDiscoverable,
          showContact: nextShowContact,
          updatedAt: current.updatedAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الخصوصية.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'ما قدرنا نحفظ التغيير. تحقق من الاتصال وحاول مرة أخرى.'; });
    } finally {
      if (mounted) setState(() { _savingMode = null; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Security Profile'),
      leading: IconButton(
        tooltip: 'رجوع',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.maybePop(context),
      ),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null && _values.isEmpty
        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Icon(Icons.shield_outlined, size: 32),
                  SizedBox(height: 8),
                  Text('إنت المتحكم في ظهورك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('كل وضع للملف الشخصي عنده إعدادات مستقلة. إيقاف الظهور يحذف النسخة العامة ولا يحذف بياناتك الخاصة.'),
                ]),
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            for (final mode in AurenProfileMode.values)
              _modeCard(mode),
            const SizedBox(height: 12),
            const Text('ملاحظة: إعدادات الظهور لا تجعل معلوماتك الخاصة عامة؛ الروابط الخاصة تبقى خارج النسخة المنشورة.', style: TextStyle(fontSize: 12)),
          ],
        ),
  );

  Widget _modeCard(AurenProfileMode mode) {
    final value = _values[mode] ?? AurenProfileModeData.empty(mode);
    final saving = _savingMode == mode;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          ListTile(
            leading: Icon(_iconFor(mode)),
            title: Text(mode.label),
            subtitle: Text(mode.description),
            trailing: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.public_outlined),
            title: const Text('إظهار الملف في الاكتشاف'),
            subtitle: Text(value.discoverable ? 'ملفك ممكن يظهر للآخرين.' : 'ملفك مخفي عن الاكتشاف.'),
            value: value.discoverable,
            onChanged: saving || _savingMode != null ? null : (v) => _update(mode, discoverable: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contact_mail_outlined),
            title: const Text('السماح بإظهار وسيلة التواصل'),
            subtitle: const Text('يتحكم في خيار التواصل العام المدعوم في هذا الوضع.'),
            value: value.showContact,
            onChanged: saving || _savingMode != null ? null : (v) => _update(mode, showContact: v),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AurenProfileMode mode) {
    switch (mode) {
      case AurenProfileMode.personal: return Icons.person_outline;
      case AurenProfileMode.creator: return Icons.auto_awesome_outlined;
      case AurenProfileMode.professional: return Icons.work_outline;
      case AurenProfileMode.business: return Icons.storefront_outlined;
    }
  }
}
