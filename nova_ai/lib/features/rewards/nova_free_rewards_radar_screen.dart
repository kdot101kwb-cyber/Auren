import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NovaFreeRewardsRadarScreen extends StatelessWidget {
  const NovaFreeRewardsRadarScreen({super.key});

  static const _items = <_RewardPlatform>[
    _RewardPlatform(
      name: 'Blum',
      category: 'نقاط مجانية',
      status: 'تجربة مجانية بحذر',
      detail: 'يمكن جمع Blum Points كل 8 ساعات. النقاط ليست USDT، ولا يوجد ضمان رسمي بأنها ستتحول إلى توكن أو رصيد قابل للسحب.',
      automation: 'لا نفترض وجود API يسمح بالبوت؛ الاستخدام اليدوي فقط حتى يثبت الإذن الرسمي.',
      url: 'https://t.me/blumcrypto',
      label: 'النقاط غير قابلة للسحب حالياً',
      safe: true,
    ),
    _RewardPlatform(
      name: 'Catizen',
      category: 'لعبة تيليجرام',
      status: 'يدوي فقط',
      detail: 'CATI توكن موجود، لكن اللعب لا يصدر CATI مباشرة؛ التوزيع مرتبط بفعاليات Airdrop ومعايير المساهمة.',
      automation: 'شروط الخدمة تمنع الوصول الآلي/البوتات دون اتفاق كتابي منفصل؛ لا نشغّل NOVA عليه.',
      url: 'https://catizen.ai/',
      label: 'البوت الخارجي غير مسموح افتراضياً',
      safe: false,
    ),
    _RewardPlatform(
      name: 'Major',
      category: 'نقاط ومكافآت',
      status: 'مراقبة فقط',
      detail: 'توجد نقاط ومكافآت مرتبطة بمواسم ومنتجات المنصة؛ لا يوجد إثبات على دخل يومي ثابت أو سحب USDT تلقائي.',
      automation: 'لا تشغيل آلي قبل وجود API وإذن واضحين.',
      url: 'https://major.tg/',
      label: 'لا يوجد دخل يومي مضمون',
      safe: true,
    ),
    _RewardPlatform(
      name: 'CryptoTab',
      category: 'تعدين متصفح',
      status: 'مستبعد من خطة الدخل',
      detail: 'الأسئلة الرسمية تذكر تعدين XMR وتحويله إلى BTC، والسحب BTC فقط. التعدين يتطلب بقاء نافذة المتصفح مفتوحة؛ ليس تعدين USDT مجانياً بالخلفية.',
      automation: 'لا نستهلك بيانات أو بطارية الهاتف في الخلفية على أساس عائد غير مثبت.',
      url: 'https://cryptotab.com/',
      label: 'ليس USDT — عائد ضعيف/مخاطر سحب',
      safe: false,
    ),
    _RewardPlatform(
      name: 'PlayNXC',
      category: 'ألعاب ومكافآت',
      status: 'يحتاج اختبار أهلية السودان',
      detail: 'تُذكر مكافآت TRX وغيرها مع حد سحب وشروط نشاط للحساب. لم يتم تأكيد قبول السودان أو نجاح السحب من السودان.',
      automation: 'لا بوت إلا إذا سمحت الشروط أو وفرت المنصة API رسمياً.',
      url: 'https://playnxc.com/',
      label: 'السودان والسحب غير مؤكدين',
      safe: true,
    ),
    _RewardPlatform(
      name: 'HaloArena',
      category: 'ساحة وكلاء AI',
      status: 'اختبار تقني فقط',
      detail: 'CP/HP نقاط تجريبية خارج السلسلة وليست USDT ولا رصيداً قابلاً للسحب، ولا يوجد دخل مؤكد.',
      automation: 'مصمم لوكلاء AI؛ نلتزم بواجهة API وتعليمات المنصة فقط.',
      url: 'https://haloarena.ai/',
      label: 'لا توجد أرباح قابلة للسحب مثبتة',
      safe: true,
    ),
  ];

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط المنصة')),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF155E59), Color(0xFF202039)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.radar, color: Color(0xFF7DE2D1), size: 32),
                SizedBox(height: 10),
                Text('NOVA — رادار المكافآت المجانية',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('نبحث عن مكافآت بلا إيداع، ونفصل النقاط عن العملات القابلة للسحب. لا نعتبر أي منصة مصدر دخل قبل إثبات أهلية السودان ونجاح السحب.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _RuleTile(
            title: 'شروط قبول الفرصة',
            body: 'بلا رسوم أو إيداع • السودان مسموح • شروط البوت واضحة • مكافأة قابلة للتحويل • وسيلة سحب تعمل فعلياً.',
          ),
          const _RuleTile(
            title: 'حماية المحفظة',
            body: 'لا تدخل عبارة الاسترداد أو المفتاح الخاص في NOVA أو أي بوت. عنوان الاستقبال فقط عند الحاجة، ولا تحويلات أو رهانات أو مشتريات دون موافقتك.',
          ),
          const SizedBox(height: 8),
          ..._items.map((item) => _PlatformCard(
                item: item,
                onOpen: () => _open(item.url, context),
              )),
          const SizedBox(height: 8),
          const _RuleTile(
            title: 'متى نعتبرها دخلاً حقيقياً؟',
            body: 'بعد التحقق من شروط البلد الحالية، والحد الأدنى والرسوم والشبكة، ثم نجاح سحب تجريبي إلى محفظتك. قبل ذلك تظهر الفرصة بحالة «غير مثبتة» ولا تدخل توقعات الدخل.',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'الحالة: دليل مراجعة أولي مبني على الشروط والمعلومات المتاحة بتاريخ 2 نوفمبر 2026. لم يتم إنشاء حسابات أو تشغيل بوتات أو إجراء سحوبات.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      );
}

class _RewardPlatform {
  final String name;
  final String category;
  final String status;
  final String detail;
  final String automation;
  final String url;
  final String label;
  final bool safe;

  const _RewardPlatform({
    required this.name,
    required this.category,
    required this.status,
    required this.detail,
    required this.automation,
    required this.url,
    required this.label,
    required this.safe,
  });
}

class _PlatformCard extends StatelessWidget {
  final _RewardPlatform item;
  final VoidCallback onOpen;

  const _PlatformCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Chip(label: Text(item.category)),
                ],
              ),
              Text(item.status, style: const TextStyle(color: Color(0xFF7DE2D1))),
              const SizedBox(height: 8),
              Text(item.detail, textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Text('الأتمتة: ${item.automation}', textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(item.safe ? Icons.info_outline : Icons.warning_amber_rounded,
                      color: item.safe ? Colors.lightBlueAccent : Colors.orangeAccent),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.label, textDirection: TextDirection.rtl)),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('المصدر الرسمي'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String body;

  const _RuleTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF7DE2D1)),
          title: Text(title, textDirection: TextDirection.rtl),
          subtitle: Text(body, textDirection: TextDirection.rtl),
        ),
      );
}
