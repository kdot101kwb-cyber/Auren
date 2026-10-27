import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _walletAccent = Color(0xFF9B87FF);
const _walletStateKey = 'nova.wallet.manual-balances.v2';

class NovaWalletTrackingScreen extends StatefulWidget {
  const NovaWalletTrackingScreen({super.key});

  @override
  State<NovaWalletTrackingScreen> createState() => _NovaWalletTrackingScreenState();
}

class _NovaWalletTrackingScreenState extends State<NovaWalletTrackingScreen> {
  final _controllers = <String, TextEditingController>{
    'bravo': TextEditingController(),
    'mycashi': TextEditingController(),
    'trust_wallet': TextEditingController(),
    'paypal': TextEditingController(),
  };
  bool _loading = true;
  String? _savedAt;

  static const _providers = <_WalletProvider>[
    _WalletProvider(
      id: 'bravo',
      name: 'Bravo',
      description: 'محفظة إلكترونية — السودان',
      balanceLabel: 'الرصيد اليدوي (SDG)',
      hint: 'مثال: 25000',
      url: 'https://play.google.com/store/apps/details?id=istinara.bravocash',
    ),
    _WalletProvider(
      id: 'mycashi',
      name: 'MyCashi',
      description: 'محفظة إلكترونية — السودان',
      balanceLabel: 'الرصيد اليدوي (SDG)',
      hint: 'مثال: 25000',
      url: 'https://play.google.com/store/apps/details?id=com.alsoug.mycashi',
      ),
    _WalletProvider(
      id: 'trust_wallet',
      name: 'Trust Wallet',
      description: 'محفظة أصول رقمية — إدخال يدوي فقط',
      balanceLabel: 'الرصيد التقديري (USDT أو أصل واحد تختاره)',
      hint: 'مثال: 12.50 USDT',
      url: 'https://trustwallet.com/',
    ),
    _WalletProvider(
      id: 'paypal',
      name: 'PayPal',
      description: 'حساب مدفوعات — التوفر والسحب يعتمدان على البلد والحساب',
      balanceLabel: 'الرصيد اليدوي (USD)',
      hint: 'مثال: 15.00',
      url: 'https://www.paypal.com/',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBalances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final provider in _providers) {
        _controllers[provider.id]!.text =
            prefs.getString('$_walletStateKey.${provider.id}') ?? '';
      }
      final timestamp = prefs.getString('$_walletStateKey.updatedAt');
      if (mounted) {
        setState(() {
          _savedAt = timestamp;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveBalances() async {
    for (final provider in _providers) {
      final value = _controllers[provider.id]!.text.trim();
      if (value.isNotEmpty) {
        final numericPart = value.replaceAll(',', '').split(RegExp(r'\s+')).first;
        final parsed = double.tryParse(numericPart);
        if (parsed == null || !parsed.isFinite || parsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('راجع قيمة رصيد ${provider.name}. أدخل رقماً صالحاً أو اتركه فارغاً.')),
          );
          return;
        }
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final provider in _providers) {
        await prefs.setString(
          '$_walletStateKey.${provider.id}',
          _controllers[provider.id]!.text.trim(),
        );
      }
      final now = DateTime.now().toIso8601String();
      await prefs.setString('$_walletStateKey.updatedAt', now);
      if (!mounted) return;
      setState(() => _savedAt = now);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإدخالات محلياً على هذا الجهاز فقط.')),
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
        const SnackBar(content: Text('تعذر فتح رابط الخدمة.')),
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
      appBar: AppBar(title: const Text('المحافظ والأرصدة — NOVA')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                      Icon(Icons.account_balance_wallet_outlined, size: 32, color: _walletAccent),
                      SizedBox(height: 10),
                      Text('مركز المحافظ الموحد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Bravo وMyCashi وTrust Wallet وPayPal في مكان واحد. سجّل الأرصدة يدوياً الآن؛ الربط الحقيقي يحتاج واجهات رسمية متاحة واختبارات.'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final provider in _providers) _providerCard(provider),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saveBalances,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ الإدخالات على هذا الجهاز'),
                ),
                const SizedBox(height: 8),
                Text('آخر حفظ: ${_formatDate(_savedAt)}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'الخصوصية والحدود: الأرقام مدخلة يدوياً وتُحفظ محلياً ولا تُرسل إلى خادم. ليست أرصدة مؤكدة أو مزامنة مباشرة. لا تدخل كلمات المرور أو PIN أو رموز الاسترداد أو OTP. Trust Wallet لا يطلب منك NOVA عبارة الاسترداد مطلقاً. PayPal قد يقيّد الاستلام أو السحب حسب البلد ونوع الحساب؛ تحقق من حسابك الرسمي قبل الاعتماد عليه.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _providerCard(_WalletProvider provider) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(provider.description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              TextButton(onPressed: () => _openProvider(provider), child: const Text('فتح')),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _controllers[provider.id],
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: provider.balanceLabel,
                hintText: provider.hint,
                border: const OutlineInputBorder(),
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
  final String balanceLabel;
  final String hint;
  final String url;

  const _WalletProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.balanceLabel,
    required this.hint,
    required this.url,
  });
}
