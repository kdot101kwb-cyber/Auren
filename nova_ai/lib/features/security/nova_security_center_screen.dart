import 'package:flutter/material.dart';

/// Security guidance and planned specialist roles for NOVA/AUREN.
/// These are role definitions in the UI, not live AI agents or a device antivirus.
class NovaSecurityCenterScreen extends StatelessWidget {
  const NovaSecurityCenterScreen({super.key});

  static const _specialists = <_SecuritySpecialist>[
    _SecuritySpecialist(
      name: 'رئيس الأمن السيبراني',
      focus: 'يراجع المخاطر ويرتب الأولويات ويطلب موافقة المستخدم على التغييرات الحساسة.',
      icon: Icons.security,
    ),
    _SecuritySpecialist(
      name: 'خبير أمن التطبيقات والكود',
      focus: 'يراجع Flutter وواجهات API والاعتماديات بحثاً عن ثغرات، ويقترح إصلاحات قابلة للاختبار.',
      icon: Icons.code,
    ),
    _SecuritySpecialist(
      name: 'خبير Firebase والخادم',
      focus: 'يراجع قواعد Firestore وAuthentication وCloud Functions والتحقق من الملكية ومعدلات الطلبات.',
      icon: Icons.cloud_outlined,
    ),
    _SecuritySpecialist(
      name: 'خبير الخصوصية وحماية البيانات',
      focus: 'يقلل جمع البيانات، ويمنع تسريب الأسرار، ويراجع السجلات والاحتفاظ بالبيانات وصلاحيات التطبيقات.',
      icon: Icons.privacy_tip_outlined,
    ),
    _SecuritySpecialist(
      name: 'خبير سلامة الجهاز والملفات',
      focus: 'يساعد في تقييم الملفات والروابط المشبوهة وإرشادات Play Protect؛ لا يدّعي فحص الجهاز من داخل هذه الصفحة.',
      icon: Icons.phonelink_lock,
    ),
    _SecuritySpecialist(
      name: 'خبير الاستجابة للحوادث',
      focus: 'يضع خطوات احتواء الاختراق، وإلغاء الجلسات، وتدوير المفاتيح، وحفظ الأدلة ومراجعة سجل النشاط.',
      icon: Icons.emergency_outlined,
    ),
    _SecuritySpecialist(
      name: 'مراجع دفاعي مستقل',
      focus: 'يحاول اكتشاف إساءة الاستخدام في بيئة مصرح بها فقط، ولا ينفذ اختراقاً أو اختباراً خارج النطاق المسموح.',
      icon: Icons.policy_outlined,
    ),
    _SecuritySpecialist(
      name: 'خبير السلامة والمخاطر',
      focus: 'يراجع مخاطر الأتمتة والمحتوى والقرارات، ويوقف الإجراءات عالية الأثر لحين موافقة المستخدم.',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

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
      detail: 'التحقق من ملكية المهمة، وموافقة مرتبطة ببصمة المحتوى، وحدود إرسال الطلبات تحتاج اختبارات مستمرة في CI.',
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
      appBar: AppBar(title: const Text('مركز الأمن والحماية والسلامة')),
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
                Text('فريق أدوار متخصص يغطي أمن التطبيقات والخادم والخصوصية وسلامة الجهاز والاستجابة للحوادث. كل إجراء عالي الخطورة يبقى تحت موافقتك.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('فريق خبراء الأمن والسلامة', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'هذه أدوار متخصصة معرفة داخل التطبيق وليست دليلاً على أن نماذج AI مستقلة تعمل بالفعل. تشغيلها يتطلب ربط محركات AI وخدمات فحص موثوقة واختبارها.',
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          for (final specialist in _specialists)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(specialist.icon),
                title: Text(specialist.name, textDirection: TextDirection.rtl),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(specialist.focus, textDirection: TextDirection.rtl),
                ),
                trailing: const Icon(Icons.pending_outlined),
              ),
            ),
          const SizedBox(height: 14),
          const Text('ضوابط الحماية الحالية', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('حالة الفحص'),
              subtitle: Text('فحوصات المستودع تُنفذ عبر GitHub Actions عند تفعيل سير العمل. فحص الهاتف والملفات يحتاج أداة موثوقة على الجهاز.'),
            ),
          ),
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
            'تنبيه: هذه الصفحة ليست مضاد فيروسات ولا تفحص كل ملفات الهاتف. لا تمنح NOVA صلاحيات Accessibility أو VPN أو إدارة الجهاز إلا لميزة محددة ومراجعة أمنياً. لا تُنفذ اختبارات أمنية إلا على أنظمة تملكها أو لديك تصريح واضح لاختبارها.',
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _SecuritySpecialist {
  const _SecuritySpecialist({required this.name, required this.focus, required this.icon});
  final String name;
  final String focus;
  final IconData icon;
}

class _SecurityCheck {
  const _SecurityCheck({required this.title, required this.detail, required this.icon});
  final String title;
  final String detail;
  final IconData icon;
}
