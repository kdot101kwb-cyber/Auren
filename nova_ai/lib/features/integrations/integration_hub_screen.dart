import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _violet = Color(0xFF9B87FF);
const _surface = Color(0xFF191925);

/// Searchable catalog of app-building tools. Links do not imply live integration.
class IntegrationHubScreen extends StatefulWidget {
  const IntegrationHubScreen({super.key});
  @override
  State<IntegrationHubScreen> createState() => _IntegrationHubScreenState();
}

class _IntegrationHubScreenState extends State<IntegrationHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _groups = <_IntegrationGroup>[
    _IntegrationGroup('التخطيط وكتابة الكود', Icons.code_rounded, [
      _Integration('Flutter', 'إطار بناء تطبيقات Android وiOS والويب من قاعدة كود واحدة.', 'مجاني ومفتوح المصدر؛ يلزم تثبيته في بيئة البناء', 'https://flutter.dev/'),
      _Integration('Dart', 'لغة البرمجة الأساسية لتطبيق NOVA وFlutter.', 'مجاني ومفتوح المصدر', 'https://dart.dev/'),
      _Integration('Android Studio', 'أدوات Android SDK والمحاكي وتصحيح أخطاء تطبيقات Android.', 'مجاني؛ يحتاج جهازاً أو بيئة بناء مناسبة', 'https://developer.android.com/studio'),
      _Integration('GitHub Copilot Free', 'مساعدة برمجية وإكمال كود بحدود مجانية حسب الخطة المتاحة.', 'خدمة خارجية؛ الحدود تتغير وليست API مدمجة في NOVA', 'https://github.com/features/copilot'),
      _Integration('Google Antigravity', 'بيئة تطوير بمساعدة وكلاء ذكاء اصطناعي.', 'خدمة خارجية؛ تحقق من توفر الخطة لحسابك', 'https://antigravity.google/'),
      _Integration('Cline', 'وكيل برمجي مفتوح المصدر للمساعدة في تعديل المشروع وتشغيل الأوامر.', 'البرنامج مجاني؛ مزود النموذج أو الحوسبة قد يكلف', 'https://cline.bot/'),
      _Integration('OpenCode', 'وكيل برمجي مفتوح المصدر مع اختيار مزود النموذج.', 'البرنامج مجاني؛ تكلفة النموذج تعتمد على المزود أو التشغيل المحلي', 'https://opencode.ai/'),
      _Integration('Continue', 'مساعد برمجي مفتوح المصدر لبيئات التطوير ويدعم نماذج متعددة.', 'البرنامج مجاني؛ النموذج قد تكون له تكلفة', 'https://www.continue.dev/'),
      _Integration('Aider', 'وكيل برمجي يعمل مع Git لمراجعة التغييرات وتحرير الملفات.', 'مفتوح المصدر؛ يعتمد على نموذج متاح لك', 'https://aider.chat/'),
      _Integration('Replit', 'بيئة برمجة سحابية لبناء نماذج أولية ومشروعات ويب.', 'الخطة المجانية وحدودها تتغير؛ ليس بديلاً مضموناً للبناء المحلي', 'https://replit.com/'),
      _Integration('Firebase Studio', 'بيئة تطوير سحابية لإنشاء النماذج الأولية والتطبيقات.', 'تحقق من الإتاحة وحدود الاستخدام الحالية', 'https://firebase.studio/'),
      _Integration('FlutterFlow', 'بناء واجهات Flutter بصرياً وتسريع النماذج الأولية.', 'خطة مجانية بحدود؛ التصدير والميزات يعتمدان على الخطة', 'https://flutterflow.io/'),
    ]),
    _IntegrationGroup('التصميم وتجربة المستخدم', Icons.design_services_outlined, [
      _Integration('Figma', 'تصميم الشاشات والنماذج ومكونات الواجهة.', 'الخطة المجانية محدودة؛ المحرر لا يندمج داخل NOVA بمجرد فتح الرابط', 'https://www.figma.com/'),
      _Integration('Penpot', 'بديل تصميم مفتوح المصدر لواجهات المستخدم والنماذج الأولية.', 'مفتوح المصدر؛ خيارات الاستضافة متاحة', 'https://penpot.app/'),
      _Integration('Material Design', 'إرشادات ومكونات لتصميم Android متسق وسهل الاستخدام.', 'مرجع مجاني', 'https://m3.material.io/'),
    ]),
    _IntegrationGroup('الخلفية وقواعد البيانات', Icons.storage_outlined, [
      _Integration('Firebase', 'مصادقة وقاعدة بيانات ووظائف سحابية وإشعارات.', 'NOVA يحتاج إعداد SDK وأسرار الخادم قبل تفعيل الميزات الحية', 'https://firebase.google.com/docs/flutter/setup'),
      _Integration('Supabase', 'قاعدة بيانات PostgreSQL ومصادقة وواجهات API.', 'خطة مجانية بحدود؛ يتطلب ربطاً واختبارات', 'https://supabase.com/'),
      _Integration('Appwrite', 'خدمات خلفية مفتوحة المصدر للمصادقة وقواعد البيانات والملفات.', 'خدمة مستضافة أو ذاتية الاستضافة؛ راعِ تكلفة التشغيل', 'https://appwrite.io/'),
      _Integration('PocketBase', 'خلفية صغيرة ذاتية الاستضافة للنماذج الأولية.', 'مفتوح المصدر؛ يلزم خادم ونسخ احتياطي وأمان', 'https://pocketbase.io/'),
      _Integration('Postman', 'اختبار API وتوثيق الطلبات والاستجابات.', 'خطة مجانية بحدود؛ توجد بدائل محلية', 'https://www.postman.com/'),
      _Integration('Bruno', 'عميل API مفتوح المصدر يعمل مع ملفات طلبات داخل Git.', 'مفتوح المصدر', 'https://www.usebruno.com/'),
    ]),
    _IntegrationGroup('الاختبارات والأمان', Icons.verified_user_outlined, [
      _Integration('Flutter Test', 'اختبارات الوحدات والواجهات داخل مشروع Flutter.', 'مدمج مع Flutter؛ لا يحتاج اشتراكاً', 'https://docs.flutter.dev/testing'),
      _Integration('Maestro', 'اختبارات واجهات تطبيقات الهاتف عبر تدفقات YAML.', 'أداة مفتوحة المصدر مع خيارات إضافية', 'https://maestro.mobile.dev/'),
      _Integration('Playwright', 'اختبارات آلية لتطبيقات الويب والمتصفحات.', 'مفتوح المصدر', 'https://playwright.dev/'),
      _Integration('OWASP ZAP', 'فحص أمني لتطبيقات الويب التي تملك تصريحاً لاختبارها.', 'مفتوح المصدر؛ استخدمه فقط على أنظمة مصرح بها', 'https://www.zaproxy.org/'),
      _Integration('Sentry', 'رصد الأعطال والأخطاء بعد إعداد المشروع.', 'الخطة المجانية وحدودها تتغير؛ يتطلب SDK', 'https://sentry.io/'),
    ]),
    _IntegrationGroup('Git وCI والبناء والتوزيع', Icons.rocket_launch_outlined, [
      _Integration('GitHub Actions', 'تشغيل التحليل والاختبارات وبناء APK ومتابعة artifacts.', 'Workflow موجود بالمستودع؛ تحقق من نتائج التشغيل الفعلية', 'https://github.com/kdot101kwb-cyber/Auren/actions'),
      _Integration('CircleCI', 'تشغيل اختبارات البناء ضمن خط CI.', 'ملف إعداد موجود؛ حالة اتصال المشروع ونجاحه تحتاج تحققاً من حساب CircleCI', 'https://circleci.com/'),
      _Integration('GitLab CI/CD', 'خط أنابيب بديل للبناء والاختبارات والنشر.', 'ملف إعداد موجود؛ يلزم مشروع GitLab وصلاحياته لتشغيله', 'https://docs.gitlab.com/ee/ci/'),
      _Integration('Codemagic', 'بناء تطبيقات Flutter وAndroid في السحابة.', 'حدود الخطة والفوترة قد تتغير؛ لا تفترض بناءً مجانياً بلا حدود', 'https://codemagic.io/'),
      _Integration('Fastlane', 'أتمتة مهام تجهيز الإصدارات والتوقيع والنشر.', 'مفتوح المصدر؛ احفظ مفاتيح التوقيع بأمان', 'https://fastlane.tools/'),
      _Integration('Docker', 'توحيد بيئات البناء والخدمات الخلفية.', 'يعتمد على بيئة تشغيل؛ راجع الخطط الحالية', 'https://www.docker.com/'),
      _Integration('NOVA Free Builder Runner', 'Workflow لبناء بعض أنواع مشاريع Flutter والويب ورفع المخرجات كـ artifact.', 'يتطلب تشغيل GitHub Actions؛ لا يولّد التطبيق تلقائياً ولا ينفذ مهام Firestore', 'https://github.com/kdot101kwb-cyber/Auren/actions/workflows/nova-free-builder.yml'),
    ]),
    _IntegrationGroup('الصور والفيديو والصوت والألعاب', Icons.movie_creation_outlined, [
      _Integration('Remotion', 'إنشاء فيديوهات برمجياً من React وقوالب قابلة لإعادة الاستخدام.', 'المشروع يحتوي على worker أولي؛ يحتاج اختبار بناء وتصيير فعلي', 'https://www.remotion.dev/'),
      _Integration('Blender', 'إنشاء نماذج ثلاثية الأبعاد وتحريك ومؤثرات.', 'مجاني ومفتوح المصدر؛ يتطلب جهازاً مناسباً للتصيير', 'https://www.blender.org/'),
      _Integration('GIMP', 'تحرير الصور والرسومات النقطية.', 'مجاني ومفتوح المصدر', 'https://www.gimp.org/'),
      _Integration('Inkscape', 'رسم شعارات ورسومات متجهية.', 'مجاني ومفتوح المصدر', 'https://inkscape.org/'),
      _Integration('Audacity', 'تسجيل الصوت وتحريره وتنظيفه.', 'مجاني ومفتوح المصدر', 'https://www.audacityteam.org/'),
      _Integration('Godot', 'محرك ألعاب مفتوح المصدر للألعاب ثنائية وثلاثية الأبعاد.', 'مجاني ومفتوح المصدر؛ البناء يحتاج بيئة مناسبة', 'https://godotengine.org/'),
      _Integration('GDevelop', 'إنشاء ألعاب ثنائية الأبعاد بأدوات مرئية.', 'خطة مجانية بحدود؛ تحقق من قيود التصدير الحالية', 'https://gdevelop.io/'),
      _Integration('ComfyUI', 'مسارات مرئية لتوليد الصور والوسائط بنماذج محلية أو متصلة.', 'مفتوح المصدر؛ النماذج تحتاج مساحة وذاكرة وقدرة معالجة', 'https://github.com/comfyanonymous/ComfyUI'),
      _Integration('Hugging Face', 'استكشاف النماذج والمجموعات وأدوات الذكاء الاصطناعي.', 'توجد موارد مجانية بحدود؛ تحقق من ترخيص كل نموذج', 'https://huggingface.co/'),
    ]),
    _IntegrationGroup('البحث والنشر والتشغيل', Icons.travel_explore_outlined, [
      _Integration('Web Search API', 'مصادر بحث تساعد NOVA على اكتشاف الفرص والتحقق من المعلومات.', 'يلزم اختيار مزود؛ قد توجد حصص أو تكاليف', 'https://brave.com/search/api/'),
      _Integration('n8n', 'أتمتة تدفقات العمل وربط الخدمات.', 'الاستضافة الذاتية تحتاج خادماً؛ المستضافة لها حدود', 'https://n8n.io/'),
      _Integration('Canva', 'تصميم منشورات وصور مصغرة وأصول تسويقية.', 'الخطة المجانية محدودة؛ الربط البرمجي يحتاج تكاملاً منفصلاً', 'https://www.canva.com/'),
      _Integration('YouTube Data API', 'إدارة بعض بيانات القناة والفيديو حسب الصلاحيات والسياسات.', 'يتطلب OAuth وحصة API؛ لا يُفعّل النشر بمجرد فتح الرابط', 'https://developers.google.com/youtube/v3'),
      _Integration('Meta / Instagram APIs', 'إدارة ونشر وتحليلات للحسابات المؤهلة والمصرح بها.', 'يتطلب إعداد تطبيق ومراجعة وصلاحيات مناسبة', 'https://developers.facebook.com/docs/'),
      _Integration('TikTok for Developers', 'تكاملات للنشر أو قراءة البيانات حسب المنتجات والصلاحيات.', 'يتطلب تفويضاً ومراجعة؛ ليس كل حساب مؤهلاً', 'https://developers.tiktok.com/'),
      _Integration('X Developer Platform', 'واجهات API بحسب المنتج ومستوى الوصول.', 'الوصول والحصص قد تكون مدفوعة أو محدودة', 'https://developer.x.com/'),
      _Integration('Telegram Bot API', 'تنبيهات حالة البناء والمهام والفرص.', 'يحتاج رمزاً سرياً محفوظاً بالخادم', 'https://core.telegram.org/bots/api'),
    ]),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رابط الخدمة غير صالح')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح صفحة الخدمة')));
    }
  }

  List<_IntegrationGroup> get _visibleGroups {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _groups;
    return _groups.map((group) {
      final items = group.items.where((item) =>
        item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query) ||
        item.status.toLowerCase().contains(query) ||
        group.title.toLowerCase().contains(query),
      ).toList();
      return _IntegrationGroup(group.title, group.icon, items);
    }).where((group) => group.items.isNotEmpty).toList();
  }

  int get _visibleCount => _visibleGroups.fold<int>(0, (sum, group) => sum + group.items.length);
  int get _totalCount => _groups.fold<int>(0, (sum, group) => sum + group.items.length);

  @override
  Widget build(BuildContext context) {
    final groups = _visibleGroups;
    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
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
              Text('مركز بناء التطبيقات في NOVA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('كتالوج قابل للبحث لأدوات التخطيط والبرمجة والتصميم والخلفية والاختبارات والبناء والوسائط والنشر. الهدف أن تبدأ وتتابع عملك من NOVA قدر الإمكان، مع توضيح ما هو رابط خارجي وما هو متصل فعلاً.'),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث عن أداة: Flutter، اختبار، فيديو، قاعدة بيانات...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: _query.isEmpty ? null : IconButton(
                tooltip: 'مسح البحث',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_visibleCount أداة ظاهرة من $_totalCount أداة', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          const Card(child: Padding(padding: EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Expanded(child: Text('هذا الكتالوج يجمع الأدوات وروابطها داخل NOVA، لكنه لا يدمج برامج الطرف الثالث داخل التطبيق ولا يعني أنها متصلة. بعض الأدوات تتطلب كمبيوتراً أو خادماً أو حساباً أو حصة مدفوعة. الخطوة التالية لعمل حقيقي من NOVA هي ربط GitHub بشكل آمن، ثم تشغيل الاختبارات والبناء وعرض النتائج هنا.')),
          ]))),
          for (final group in groups) ...[
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
                      const Icon(Icons.open_in_new, color: Colors.orangeAccent),
                      const SizedBox(width: 9),
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      const Chip(label: Text('رابط خارجي')),
                    ]),
                    const SizedBox(height: 6),
                    Text(item.description),
                    const SizedBox(height: 7),
                    Text(item.status, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                      onPressed: () => _open(context, item.url),
                      icon: const Icon(Icons.launch, size: 17),
                      label: const Text('فتح الأداة أو التوثيق'),
                    )),
                  ]),
                ),
              ),
          ],
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('ما لقيت أداة مطابقة. جرّب كلمة أقصر أو اسم الخدمة بالإنجليزية.')),
            ),
          const SizedBox(height: 16),
          const Text('قواعد الربط الآمن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('• مفاتيح API وOAuth تحفظ بالخادم أو مدير أسرار، وليس داخل التطبيق.\n• كل تكامل يحتاج صلاحيات أقل ما يمكن واختبار اتصال واضحاً.\n• لا نشر ولا رسائل ولا شراء ولا إنفاق إعلاني دون إذن منفصل.\n• لا نعرض الخدمة على أنها متصلة إلا بعد نجاح اختبار حي موثق.\n• الأولوية العملية: GitHub + CI + سجل مهام + نتائج الاختبارات + تنزيل APK من داخل NOVA.'),
        ],
          ),
        ),
      ),
    );
  }
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
