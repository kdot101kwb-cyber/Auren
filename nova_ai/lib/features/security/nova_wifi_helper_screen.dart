import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

/// Safe Wi-Fi assistance for the personal NOVA app.
/// Android owns discovery and authentication; NOVA never attempts to crack keys.
class NovaWifiHelperScreen extends StatelessWidget {
  const NovaWifiHelperScreen({super.key});

  Future<void> _openWifiSettings(BuildContext context) async {
    try {
      const intent = AndroidIntent(action: 'android.settings.WIFI_SETTINGS');
      await intent.launch();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح إعدادات Wi-Fi. افتح إعدادات الهاتف يدوياً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مساعد Wi-Fi في NOVA')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.wifi_find, size: 64),
            const SizedBox(height: 12),
            const Text(
              'الاتصال بالشبكات بأمان',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'يفتح NOVA إعدادات Android الرسمية لتختار شبكة متاحة وتدخل كلمة المرور التي تملك حق استخدامها.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openWifiSettings(context),
              icon: const Icon(Icons.settings),
              label: const Text('فتح إعدادات Wi-Fi'),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.key),
                title: Text('نسيت كلمة مرور شبكتك؟'),
                subtitle: Text('راجع ملصق الراوتر أو تطبيق مزود الخدمة أو إعدادات الراوتر الذي تملكه.'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('الحماية أولاً'),
                subtitle: Text('لا يكسر NOVA كلمات المرور ولا يتجاوز حماية الشبكات المقفولة.'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.public),
                title: Text('الشبكات العامة'),
                subtitle: Text('اختر الشبكات العامة المصرح بها وتجنب إدخال معلومات حساسة على شبكات غير موثوقة.'),
              ),
            ),
          ],
        ),
      );
}
