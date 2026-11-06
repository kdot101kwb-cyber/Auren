import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _walletAccent = Color(0xFF9B87FF);
const _walletStateKey = 'nova.wallet.manual-balances.v1';

class NovaWalletTrackingScreen extends StatefulWidget {
  const NovaWalletTrackingScreen({super.key});

  @override
  State<NovaWalletTrackingScreen> createState() => _NovaWalletTrackingScreenState();
}

class _NovaWalletTrackingScreenState extends State<NovaWalletTrackingScreen> {
  final _bravoController = TextEditingController();
  final _myCashiController = TextEditingController();
  bool _loading = true;
  String? _savedAt;

  static const _providers = <_WalletProvider>[
    _WalletProvider(
      id: 'bravo',
      name: 'Bravo',
      description: 'محفظة إلكترونية — السودان',
      url: 'https://play.google.com/store/apps/details?id=istinara.bravocash',
    ),
    _WalletProvider(
      id: 'mycashi',
      name: 'MyCashi',
      description: 'محفظة إلكترونية — السودان',
      url: 'https://play.google.com/store/apps/details?id=com.alsoug.mycashi',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    _bravoController.dispose();
    _myCashiController.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bravoController.text = prefs.getString('${_walletStateKey}.bravo') ?? '';
      _myCashiController.text = prefs.getString('${_walletStateKey}.mycashi') ?? '';
      final timestamp = prefs.getString('${_walletStateKey}.updatedAt');
      if (mounted) setState(() { _savedAt = timestamp; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveBalances() async {
    final bravo = _bravoController.text.trim();
    final myCashi = _myCashiController.text.trim();
    for (final value in [bravo, myCashi]) {
      if (value.isNotEmpty && (double.tryParse(value.replaceAll(',', '')) == null ||
          double.parse(value.replaceAll(',', '')) < 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل رصيداً رقمياً موجباً أو اترك الحقل فارغاً.')),
        );
        return;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_walletStateKey}.bravo', bravo);
      await prefs.setString('${_walletStateKey}.mycashi', myCashi);
      final now = DateTime.now().toIso8601String();
      await prefs.setString('${_walletStateKey}.updatedAt', now);
      if (!mounted) return;
      setState(() => _savedAt = now);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الأرصدة التي أدخلتها على هذا الجهاز فقط.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ المحلي.')),
      );
    }
  }

  Future<void> _openProvider(_WalletProvider provider) async {
    final uri = Uri.parse(provider.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط التطبيق.')),
      );
    }
  }

  String _formatDate(String? value) {
    if (value == null) return 'لم يُحفظ بعد';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'وقت الحفظ غير معروف';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محافظي — Bravo وMyCashi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                      Icon(Icons.account_balance_wallet_outlined, size: 32, color: _walletAccent),
                      SizedBox(height: 10),
                      Text('متابعة يدوية آمنة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('أدخل الرصيد الظاهر داخل كل تطبيق. NOVA لا يسجل الدخول إلى المحافظ ولا ينفّذ تحويلات.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final provider in _providers)
                  _providerCard(provider),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saveBalances,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ الأرصدة على هذا الجهاز'),
                ),
                const SizedBox(height: 8),
                Text('آخر حفظ: ${_formatDate(_savedAt)}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'تنبيه الخصوصية: الأرقام تُحفظ محلياً على الجهاز ولا تُرسل إلى خادم. هذه الأرقام مدخلة يدوياً وليست أرصدة متحقَّقاً منها. لا تدخل كلمة المرور أو رمز OTP أو PIN هنا.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _providerCard(_WalletProvider provider) {
    final controller = provider.id == 'bravo' ? _bravoController : _myCashiController;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: _walletAccent),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(provider.description, style: Theme.of(context).textTheme.bodySmall),
              ])),
              TextButton(onPressed: () => _openProvider(provider), child: const Text('فتح التطبيق')),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الرصيد الذي أدخلته يدوياً (SDG)',
                hintText: 'مثال: 25000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletProvider {
  final String id;
  final String name;
  final String description;
  final String url;
  const _WalletProvider({required this.id, required this.name, required this.description, required this.url});
}
