import 'package:flutter/material.dart';

/// Security guidance and visible status for NOVA/AUREN.
/// This screen does not claim to scan the Android device for malware.
class NovaSecurityCenterScreen extends StatelessWidget {
  const NovaSecurityCenterScreen({super.key});

  static const _checks = <_SecurityCheck>[
    _SecurityCheck(
      title: 'حماية الحساب والجلسات',
      detail: 'استخدم كلمة مرور فريدة، فعّل التحقق بخطوتين في الحسابات المرتبطة، وسجّل الخروج من الأجهزة غير المعروفة.',
      icon: Icons.verified_user_outlined,
    ),
    _SecurityCheck(
      title: 'فحص التطبيقات والملفات',
      detail: 'فعّل Google Play Protect من متجر Play، ولا تثبّت APK مجهول المصدر أو تفتح ملفات وروابط مشبوهة.',
      icon: Icons.shield_outlined,
    ),
    _SecurityCheck(
      title: 'حماية مفاتيح الخدمات',
      detail: 'لا تضع مفاتيح API أو مفاتيح الخدمة داخل التطبيق أو GitHub. خزّن الأسرار على الخادم ودوّر أي مفتاح يُشتبه بتسريبه.',
      icon: Icons.key_outlined,
    ),
    _SecurityCheck(
      title: 'مقاومة إساءة استخدام المهام',
      detail: 'التحقق من ملكية المهمة، موافقة مرتبطة ببصمة المحتوى، وحدود إرسال الطلبات تُختبر في CI.',
      icon: Icons.rule_outlined,
    ),
    _SecurityCheck(
      title: 'فحص الكود والاعتماديات',
      detail: 'تُشغّل فحوصات CI للكود والاعتماديات والإعدادات. نتيجة الفحص لا تعني أن الهاتف نفسه خالٍ من الفيروسات.',
      icon: Icons.manage_search_outlined,
    ),
    _SecurityCheck(
      title: 'الاستجابة للحوادث',
      detail: 'عند الاشتباه باختراق: أوقف المهام الحساسة، ألغِ الجلسات، غيّر كلمات المرور ودوّر المفاتيح، ثم راجع سجل النشاط.',
      icon: Icons.emergency_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مركز الحماية والأمان')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security, size: 34),
                SizedBox(height: 10),
                Text('درع NOVA + AUREN', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('حماية متعددة الطبقات: الحساب، الجهاز، البيانات، الخادم، والمهام. لا يوجد فحص مضاد فيروسات محلي مدمج في هذه الشاشة.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('حالة الفحص'),
              subtitle: Text('فحوصات المستودع تُنفذ عبر GitHub Actions. فحص الهاتف والملفات يحتاج أداة موثوقة على الجهاز.'),
            ),
          ),
          const SizedBox(height: 8),
          for (final check in _checks)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(check.icon),
                title: Text(check.title, textDirection: TextDirection.rtl),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(check.detail, textDirection: TextDirection.rtl),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'تنبيه: NOVA لا يستطيع فحص كل ملفات الهاتف أو إزالة الفيروسات تلقائياً بهذه الصفحة. لا تمنحه صلاحيات Accessibility أو VPN أو إدارة الجهاز إلا إذا كانت هناك ميزة محددة ومراجعة أمنياً تحتاجها.',
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _SecurityCheck {
  const _SecurityCheck({required this.title, required this.detail, required this.icon});
  final String title;
  final String detail;
  final IconData icon;
}
