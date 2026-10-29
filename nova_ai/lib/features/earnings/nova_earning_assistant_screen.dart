import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'earning_platforms.dart';

const _earningChecksKey = 'nova.earning_assistant.checked.v1';

class NovaEarningAssistantScreen extends StatefulWidget {
  const NovaEarningAssistantScreen({super.key});

  @override
  State<NovaEarningAssistantScreen> createState() => _NovaEarningAssistantScreenState();
}

class _NovaEarningAssistantScreenState extends State<NovaEarningAssistantScreen> {
  final _query = TextEditingController();
  final Set<String> _checked = <String>{};
  bool _cryptoOnly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_earningChecksKey) ?? const <String>[];
      if (!mounted) return;
      setState(() {
        _checked
          ..clear()
          ..addAll(saved);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setChecked(EarningPlatform platform, bool value) async {
    setState(() {
      if (value) {
        _checked.add(platform.id);
      } else {
        _checked.remove(platform.id);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_earningChecksKey, _checked.toList()..sort());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ حالة الفحص على الهاتف.')),
      );
    }
  }

  Future<void> _open(EarningPlatform platform) async {
    final uri = Uri.tryParse(platform.url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط الرسمي.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final platforms = filterEarningPlatforms(
      query: _query.text,
      cryptoOnly: _cryptoOnly,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('بوت مساعد الدخل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF382B70), Color(0xFF202039)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 30, color: Color(0xFF9B87FF)),
                SizedBox(height: 8),
                Text('NOVA — مساعد فرص الدخل', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('يرتب 10 منصات، يفتح المصادر الرسمية، ويسجل فحص التسجيل والسحب حتى لا تضيع وقتك. هذه النسخة لا تسجل حسابات ولا تنفذ المهام نيابة عنك بعد.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'ابحث عن منصة أو نوع مهمة',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _cryptoOnly,
            onChanged: (value) => setState(() => _cryptoOnly = value),
            title: const Text('اعرض خيارات الكريبتو المعلنة فقط'),
            subtitle: const Text('هذا لا يعني أن USDT أو السودان مؤكدان.'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'قاعدة NOVA: لا رسوم بداية، لا VPN لتجاوز حظر بلد، لا مشاركة لكلمات المرور أو عبارة استرداد Trust Wallet، ولا نعتبر المنصة مؤكدة قبل أن يظهر خيار السحب في حسابك. لا يوجد دخل مضمون.',
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: Text('فحصك: ${_checked.length} من ${earningPlatforms.length}')),
              if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 6),
          ...platforms.map((platform) {
            final crypto = platform.payoutStatus != EarningPayoutStatus.noDirectCryptoEvidence;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(child: Icon(crypto ? Icons.currency_exchange : Icons.work_outline)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(platform.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                        IconButton(
                          tooltip: 'فتح الموقع الرسمي',
                          onPressed: () => _open(platform),
                          icon: const Icon(Icons.open_in_new),
                        ),
                      ],
                    ),
                    Text(platform.workType),
                    const SizedBox(height: 8),
                    Text('السحب: ${platform.payoutNote}'),
                    const SizedBox(height: 6),
                    Text('السودان: ${platform.sudanNote}', style: const TextStyle(color: Colors.amberAccent)),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _checked.contains(platform.id),
                      onChanged: (value) => _setChecked(platform, value ?? false),
                      title: const Text('فحصت التسجيل وخيار السحب بنفسي'),
                      subtitle: const Text('ضع العلامة فقط بعد أن ترى الخيار داخل حسابك.'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => _open(platform),
                        child: const Text('فتح المصدر'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
