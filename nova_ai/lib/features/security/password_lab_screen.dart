import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Safe recovery links and consent-based, non-invasive security checks.
class PasswordLabScreen extends StatefulWidget {
  const PasswordLabScreen({super.key});

  @override
  State<PasswordLabScreen> createState() => _PasswordLabScreenState();
}

class _PasswordLabScreenState extends State<PasswordLabScreen> {
  final _urlController = TextEditingController();
  bool _authorized = false;
  bool _checking = false;
  String? _result;
  List<String> _findings = const [];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _openRecovery(String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الاسترداد. تحقق من اتصال الإنترنت.')),
      );
    }
  }

  bool _isPublicHttpsUrl(Uri uri) {
    if (uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    final parts = host.split('.');
    final isIpv4 = parts.length == 4 && parts.every((part) {
      final number = int.tryParse(part);
      return number != null && number >= 0 && number <= 255;
    });
    if (!host.contains('.') || host == 'localhost' || host.endsWith('.local') ||
        host.endsWith('.internal') || isIpv4 || host.contains(':')) {
      return false;
    }
    return true;
  }

  Future<void> _checkWebsite() async {
    final uri = Uri.tryParse(_urlController.text.trim());
    if (uri == null || !_isPublicHttpsUrl(uri)) {
      setState(() {
        _result = 'أدخل عنوان HTTPS لموقع عام تملكه أو لديك تصريح بفحصه.';
        _findings = const [];
      });
      return;
    }
    if (!_authorized) {
      setState(() {
        _result = 'أكد أولاً أنك تملك الموقع أو لديك إذن صريح لفحصه.';
        _findings = const [];
      });
      return;
    }

    setState(() {
      _checking = true;
      _result = null;
      _findings = const [];
    });
    final client = http.Client();
    try {
      final request = http.Request('HEAD', uri)
        ..followRedirects = false
        ..maxRedirects = 0;
      final response = await client.send(request).timeout(const Duration(seconds: 10));
      final headers = response.headers.map((key, value) => MapEntry(key.toLowerCase(), value));
      final findings = <String>[];
      if (!headers.containsKey('strict-transport-security')) findings.add('لم يظهر ترويس HSTS في الاستجابة.');
      if (!headers.containsKey('content-security-policy')) findings.add('لم يظهر Content-Security-Policy.');
      if (!headers.containsKey('x-content-type-options')) findings.add('لم يظهر X-Content-Type-Options.');
      if (!headers.containsKey('referrer-policy')) findings.add('لم يظهر Referrer-Policy.');
      if (response.statusCode >= 300 && response.statusCode < 400) {
        findings.add('الموقع أعاد إعادة توجيه؛ لم يتبع الفحص التحويل تلقائياً.');
      }
      if (findings.isEmpty) findings.add('ظهرت ترويسات الأمان الأساسية التي يفحصها هذا الاختبار.');
      if (!mounted) return;
      setState(() {
        _result = 'اكتمل فحص HEAD غير التدميري. رمز HTTP: ' + response.statusCode.toString() + '. هذا فحص أولي للترويسات فقط، وليس اختبار اختراق كاملاً.';
        _findings = findings;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = 'تعذر الوصول إلى الموقع خلال 10 ثوانٍ. قد يمنع الخادم طلب HEAD أو لا يوجد اتصال.';
        _findings = const [];
      });
    } finally {
      client.close();
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA Password Lab'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(22),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('استرداد الحسابات • أمان Wi-Fi • فحص المواقع'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionHeading(icon: Icons.key, title: 'استرداد الحسابات'),
                const SizedBox(height: 8),
                const Text('يفتح صفحات الاسترداد الرسمية فقط. لا يطلب NOVA كلمة مرورك ولا يتجاوز تسجيل الدخول.'),
                const SizedBox(height: 12),
                _RecoveryButton(label: 'Google', onTap: () => _openRecovery('https://accounts.google.com/signin/recovery')),
                _RecoveryButton(label: 'Facebook', onTap: () => _openRecovery('https://www.facebook.com/login/identify/')),
                _RecoveryButton(label: 'Microsoft', onTap: () => _openRecovery('https://account.live.com/password/reset')),
                _RecoveryButton(label: 'Apple', onTap: () => _openRecovery('https://iforgot.apple.com/')),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionHeading(icon: Icons.wifi, title: 'فحص أمان Wi-Fi'),
                const SizedBox(height: 8),
                const Text('قائمة تحقق محلية؛ لا يحاول الاتصال بالشبكات أو كشف كلمات مرورها. افحص إعدادات الراوتر الذي تملكه:'),
                const SizedBox(height: 8),
                const _CheckItem(text: 'استخدم WPA2-AES أو WPA3، وتجنب WEP وفتح الشبكة دون كلمة مرور.'),
                const _CheckItem(text: 'عطّل WPS إن لم تكن تحتاجه.'),
                const _CheckItem(text: 'غيّر كلمة مرور لوحة إدارة الراوتر الافتراضية وحدّث البرنامج الثابت.'),
                const _CheckItem(text: 'استخدم كلمة مرور Wi-Fi فريدة، وأنشئ شبكة ضيوف للأجهزة غير الموثوقة.'),
                const SizedBox(height: 8),
                const Text('ملاحظة: قراءة الشبكات القريبة فعلياً تحتاج تكامل Android أصلي وصلاحيات يوافق عليها المستخدم؛ هذا الإصدار لا يدّعي تنفيذ مسح لاسلكي.', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionHeading(icon: Icons.shield_outlined, title: 'فحص أمان موقع مصرح به'),
                const SizedBox(height: 8),
                const Text('يفحص ترويسات HTTP الأساسية بطلب HEAD واحد عبر HTTPS. لا يجرب كلمات مرور ولا يستغل ثغرات ولا يتجاوز المصادقة.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'عنوان HTTPS للموقع',
                    hintText: 'https://example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _authorized,
                  onChanged: (value) => setState(() => _authorized = value ?? false),
                  title: const Text('أملك هذا الموقع أو لدي إذن صريح لفحصه.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _checking ? null : _checkWebsite,
                  icon: _checking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.manage_search),
                  label: Text(_checking ? 'جارٍ الفحص...' : 'فحص الترويسات'),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(_result!),
                  ..._findings.map((finding) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.info_outline),
                    title: Text(finding),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('حماية المستخدم أولاً: لا تدخل كلمات مرورك أو رموز التحقق داخل أدوات الفحص.', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
      ]);
}

class _RecoveryButton extends StatelessWidget {
  const _RecoveryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.open_in_new),
          label: Text('استرداد حساب $label'),
        ),
      );
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
