import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _violet = Color(0xFF9B87FF);
const _surface = Color(0xFF191925);

class IntegrationHubScreen extends StatelessWidget {
  const IntegrationHubScreen({super.key});

  static const _groups = <_IntegrationGroup>[
    _IntegrationGroup('تطوير التطبيقات مجاناً', Icons.code_rounded, [
      _Integration('GitHub Copilot Free', 'إكمال الكود ومحادثة برمجية بحدود مجانية؛ مناسب للعمل على مستودع AUREN.', 'خدمة خارجية؛ يلزم فتحها وتسجيل الدخول، وليست مدمجة كـ API داخل NOVA', 'https://github.com/features/copilot'),
      _Integration('Google Antigravity', 'بيئة تطوير بوكلاء ذكاء اصطناعي لبناء الميزات وفحص المشاريع ضمن حدود الاستخدام المتاحة.', 'خدمة خارجية؛ تحقق من إتاحة الخطة المجانية لحسابك', 'https://antigravity.google/'),
      _Integration('Cline', 'وكيل برمجي مفتوح المصدر لتعديل الملفات وتشغيل الاختبارات بموافقتك.', 'البرنامج مجاني؛ مزود النموذج قد يفرض تكلفة، ويمكن استخدام نموذج محلي', 'https://cline.bot/'),
      _Integration('OpenCode', 'وكيل برمجي مفتوح المصدر يدعم اختيار مزود النموذج.', 'البرنامج مجاني؛ تكلفة النموذج تعتمد على المزود أو التشغيل المحلي', 'https://opencode.ai/'),
      _Integration('NOVA Free Builder Runner', 'يفحص Flutter أو الويب أو صفحة HTML ثابتة ويبني المخرجات ويرفعها كـ artifact عبر GitHub Actions.', 'أُضيف workflow يدوي؛ لا يولّد الكود ولا يستهلك طابور مهام Firestore تلقائياً', 'https://github.com/kdot101kwb-cyber/Auren/actions/workflows/nova-free-builder.yml'),
      _Integration('دليل الإعداد المجاني', 'خطوات الاستخدام وحدود المجانية وسياسة تقليل أخطاء الكود.', 'توثيق داخل المستودع', 'https://github.com/kdot101kwb-cyber/Auren/blob/feat/nova-ai-android-app/nova_ai/docs/free_ai_coding_setup.md'),
    ]),
    _IntegrationGroup('القيادة والتنفيذ', Icons.account_tree_outlined, [
      _Integration('AUREN AI Gateway', 'توجيه الطلبات لمزودي الذكاء الاصطناعي مع بدائل وحدود تكلفة.', 'Backend موجود جزئياً؛ ربط تطبيق NOVA لم يكتمل', 'https://github.com/kdot101kwb-cyber/Auren/blob/feat/nova-ai-android-app/functions/index.js'),
      _Integration('GitHub Actions', 'مهام التطوير والاختبارات والبناء ومتابعة نتائج CI.', 'مخطط للتكامل داخل التطبيق', 'https://github.com/kdot101kwb-cyber/Auren'),
      _Integration('Firebase', 'المصادقة، قاعدة البيانات، المهام، سجل التدقيق والتنبيهات.', 'وظائف خلفية موجودة؛ NOVA بلا Firebase SDK حالياً', 'https://firebase.google.com/docs/flutter/setup'),
    ]),
    _IntegrationGroup('البحث والفرص', Icons.travel_explore_outlined, [
      _Integration('Web Search API', 'بحث ويب موثق بالمصادر والتواريخ لاكتشاف الفرص والتحقق منها.', 'مطلوب اختيار مزود وإضافة سر بالخادم', 'https://brave.com/search/api/'),
      _Integration('Opportunity Monitor', 'ترتيب الفرص وتنبيه المستخدم عند ظهور إشارة قوية وحديثة.', 'محرك الخلفية موجود؛ مصدر البيانات وواجهة التنبيهات ناقصان', 'https://github.com/kdot101kwb-cyber/Auren/blob/feat/nova-ai-android-app/nova_ai/docs/proactive_opportunity_monitor.md'),
    ]),
    _IntegrationGroup('إنشاء المحتوى', Icons.movie_creation_outlined, [
      _Integration('Canva', 'تصميم أصول تسويقية وقوالب وصور مصغرة.', 'لم يتم التحقق من اتصال API', 'https://www.canva.com/developers/'),
      _Integration('Image / Video Providers', 'توليد ملفات صور وفيديو فعلية من وصف المستخدم.', 'لا يوجد محرك توليد متصل في NOVA حالياً', 'https://replicate.com/'),
    ]),
    _IntegrationGroup('النشر والتواصل', Icons.campaign_outlined, [
      _Integration('Buffer', 'جدولة المنشورات على القنوات المدعومة بعد تفويض الحساب.', 'غير مربوط؛ يلزم OAuth واختبار نشر', 'https://buffer.com/developers/api'),
      _Integration('Meta / Instagram', 'نشر وتحليلات الحسابات المهنية المصرح بها.', 'غير مربوط؛ الأهلية ومراجعة التطبيق مطلوبة', 'https://developers.facebook.com/docs/'),
      _Integration('TikTok / YouTube / X', 'نشر وتحليلات حسب صلاحيات API لكل منصة.', 'كل منصة تحتاج تكاملاً وتفويضاً مستقلاً', 'https://developers.google.com/youtube/v3'),
      _Integration('Telegram Bot', 'تنبيهات الفرص وحالة المهام والنتائج.', 'غير مربوط؛ يحتاج رمزاً سرياً بالخادم', 'https://core.telegram.org/bots/api'),
    ]),
    _IntegrationGroup('التشغيل والمال', Icons.account_balance_wallet_outlined, [
      _Integration('n8n Automation', 'ربط الخدمات في مسارات تشغيل وإعادة محاولات موثوقة.', 'غير مربوط؛ يتطلب استضافة ومصادقة', 'https://n8n.io/'),
      _Integration('Revenue & Cost Tracking', 'تسجيل التكاليف والإيرادات والربح الفعلي لكل حملة.', 'المخطط موجود جزئياً؛ لا توجد بيانات مالية متصلة', 'https://github.com/kdot101kwb-cyber/Auren'),
      _Integration('Email / Drive', 'حفظ المخرجات وإرسال تقارير التنفيذ بعد منح الصلاحية.', 'غير مربوط', 'https://developers.google.com/workspace'),
    ]),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة الإعداد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.hub_outlined, color: _violet, size: 32),
          SizedBox(height: 10),
          Text('مركز ربط NOVA AI', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('كل خدمات AUREN والبحث والإنشاء والنشر والأتمتة تمر عبر مركز تكاملات واحد. الحالات هنا توضح الوضع المعروف في المستودع، ولا تدّعي أن أي حساب اتصل دون تحقق.'),
        ]),
      ),
      const SizedBox(height: 14),
      const Card(child: Padding(padding: EdgeInsets.all(14), child: Row(children: [
        Icon(Icons.info_outline, color: Colors.orangeAccent),
        SizedBox(width: 10),
        Expanded(child: Text('حالة البداية: NOVA Flutter لا يحتوي حالياً على Firebase Auth / Firestore / Functions. لذلك لا يمكن تفعيل الاتصال الحي من هذه الشاشة قبل إضافة SDK وإعداد Firebase وأسرار الخادم.')),
      ]))),
      for (final group in _groups) ...[
        const SizedBox(height: 18),
        Row(children: [
          Icon(group.icon, color: _violet),
          const SizedBox(width: 8),
          Expanded(child: Text(group.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        for (final item in group.items)
          Card(
            color: _surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.link_off, color: Colors.orangeAccent),
                  const SizedBox(width: 9),
                  Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const Chip(label: Text('غير متحقق')),
                ]),
                const SizedBox(height: 6),
                Text(item.description, textDirection: TextDirection.rtl),
                const SizedBox(height: 7),
                Text(item.status, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12), textDirection: TextDirection.rtl),
                Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                  onPressed: () => _open(context, item.url),
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text('مواصفات / إعداد الخدمة'),
                )),
              ]),
            ),
          ),
      ],
      const SizedBox(height: 16),
      const Text('قواعد الربط', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('• مفاتيح API وOAuth تحفظ في Secret Manager أو إعدادات الخادم فقط.\n• كل موفر له حالة اتصال واختبار وصلاحيات وتكلفة وحدود استخدام.\n• لا نشر ولا رسائل ولا شراء ولا إنفاق إعلاني دون إذن منفصل.\n• لا تُعرض الخدمة على أنها متصلة إلا بعد نجاح اختبار حي موثق.'),
    ],
  );
}

class _IntegrationGroup {
  final String title;
  final IconData icon;
  final List<_Integration> items;
  const _IntegrationGroup(this.title, this.icon, this.items);
}

class _Integration {
  final String name;
  final String description;
  final String status;
  final String url;
  const _Integration(this.name, this.description, this.status, this.url);
}
