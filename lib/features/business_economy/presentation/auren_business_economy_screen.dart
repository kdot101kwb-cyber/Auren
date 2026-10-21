import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../business/presentation/business_screen.dart';
import '../../global_directory/presentation/auren_business_navigator_screen.dart';
import '../../global_directory/presentation/auren_supplier_discovery_screen.dart';
import '../../global_directory/presentation/auren_trade_deal_screen.dart';
import '../../personal_ai/presentation/business_growth_screen.dart';
import '../domain/business_economy_logic.dart';

/// Entry point that composes existing business foundations without duplicating
/// the supplier-offer comparison workflow. Match briefs and growth notes stay
/// on-device; no outreach, purchase, payment, or trade commitment is triggered.
class AurenBusinessEconomyScreen extends StatelessWidget {
  const AurenBusinessEconomyScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = <_BusinessEconomyItem>[
      _BusinessEconomyItem(
        icon: Icons.storefront_outlined,
        title: 'Local Business OS',
        subtitle: 'ملفات الأعمال والخدمات والعروض',
        onTap: () => _open(context, const AurenBusinessScreen()),
      ),
      _BusinessEconomyItem(
        icon: Icons.travel_explore_outlined,
        title: 'Business Discovery',
        subtitle: 'اكتشاف الشركات والمصادر حسب النشاط',
        onTap: () => _open(context, const AurenSupplierDiscoveryScreen()),
      ),
      _BusinessEconomyItem(
        icon: Icons.compare_arrows_rounded,
        title: 'Buyer–Seller Matching',
        subtitle: 'جهّز موجز مطابقة محلياً دون إرسال طلب',
        onTap: () => _open(context, const AurenBuyerSellerMatchDraftScreen()),
      ),
      _BusinessEconomyItem(
        icon: Icons.public_outlined,
        title: 'Trade & Export Hub',
        subtitle: 'نظّم فرصة تجارية أو خطة تصدير كمسودة',
        onTap: () => _open(context, const AurenBusinessNavigatorScreen()),
      ),
      _BusinessEconomyItem(
        icon: Icons.trending_up_rounded,
        title: 'Business Growth Planner',
        subtitle: 'احفظ هدفك ومجموعة العملاء والخطوة التالية',
        onTap: () => _open(context, const AurenBusinessGrowthPlannerScreen()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Business & Economy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.business_center_outlined, size: 34),
                  SizedBox(height: 10),
                  Text('من الفكرة إلى فرصة واضحة',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('نسخة اقتصادية تعمل مع الخدمات الموجودة. المطابقة والخطط مسودات؛ لا رسائل أو معاملات تجارية تلقائية.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Card(
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: item.onTap,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'ملاحظة: أدلة الشركات والمصادر الخارجية ليست توصية أو ضماناً. تحقّق من الهوية والتراخيص والشروط قبل أي تعامل.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BusinessEconomyItem {
  const _BusinessEconomyItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// A matching brief is intentionally local-only; submitting it does not
/// publish a request or contact counterparties.
class AurenBuyerSellerMatchDraftScreen extends StatefulWidget {
  const AurenBuyerSellerMatchDraftScreen({super.key});

  @override
  State<AurenBuyerSellerMatchDraftScreen> createState() =>
      _AurenBuyerSellerMatchDraftScreenState();
}

class _AurenBuyerSellerMatchDraftScreenState
    extends State<AurenBuyerSellerMatchDraftScreen> {
  static const _storageKey = 'auren_business_match_draft_v1';
  final _need = TextEditingController();
  final _offer = TextEditingController();
  final _buyerLocation = TextEditingController();
  final _sellerLocation = TextEditingController();
  final _buyerCategory = TextEditingController();
  final _sellerCategory = TextEditingController();
  String _status = 'الموجز محفوظ على هذا الجهاز فقط.';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _need.dispose();
    _offer.dispose();
    _buyerLocation.dispose();
    _sellerLocation.dispose();
    _buyerCategory.dispose();
    _sellerCategory.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _need.text = prefs.getString('${_storageKey}_need') ?? '';
      _offer.text = prefs.getString('${_storageKey}_offer') ?? '';
      _buyerLocation.text = prefs.getString('${_storageKey}_buyer_location') ?? '';
      _sellerLocation.text = prefs.getString('${_storageKey}_seller_location') ?? '';
      _buyerCategory.text = prefs.getString('${_storageKey}_buyer_category') ?? '';
      _sellerCategory.text = prefs.getString('${_storageKey}_seller_category') ?? '';
    } catch (_) {
      if (mounted) setState(() => _status = 'التخزين المحلي غير متاح الآن.');
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    if (_need.text.trim().isEmpty || _offer.text.trim().isEmpty) {
      setState(() => _status = 'أدخل احتياج المشتري وعرض البائع أولاً.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_storageKey}_need', _need.text.trim());
    await prefs.setString('${_storageKey}_offer', _offer.text.trim());
    await prefs.setString('${_storageKey}_buyer_location', _buyerLocation.text.trim());
    await prefs.setString('${_storageKey}_seller_location', _sellerLocation.text.trim());
    await prefs.setString('${_storageKey}_buyer_category', _buyerCategory.text.trim());
    await prefs.setString('${_storageKey}_seller_category', _sellerCategory.text.trim());
    if (mounted) setState(() => _status = 'تم حفظ المسودة على هذا الجهاز؛ لم يُرسل أي طلب.');
  }

  @override
  Widget build(BuildContext context) {
    final result = AurenBusinessEconomyLogic.scoreMatch(
      AurenBusinessMatchInput(
        buyerNeed: _need.text,
        sellerOffer: _offer.text,
        buyerLocation: _buyerLocation.text,
        sellerLocation: _sellerLocation.text,
        buyerCategory: _buyerCategory.text,
        sellerCategory: _sellerCategory.text,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer–Seller Matching')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('مطابقة إرشادية فقط — لا تتواصل مع أي طرف ولا تنشئ التزاماً تجارياً.'),
          const SizedBox(height: 12),
          _field(_need, 'احتياج المشتري *'),
          _field(_offer, 'عرض البائع *'),
          _field(_buyerCategory, 'نشاط/فئة المشتري'),
          _field(_sellerCategory, 'نشاط/فئة البائع'),
          _field(_buyerLocation, 'موقع المشتري'),
          _field(_sellerLocation, 'موقع البائع'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مؤشر التوافق: ${result.score} / 100',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(result.reasons.isEmpty
                      ? 'أدخل بيانات أكثر للحصول على مؤشر أولي.'
                      : result.reasons.join(' • ')),
                  const SizedBox(height: 6),
                  const Text('هذا المؤشر تقريبي وغير موثّق، ولا يمثل ضماناً للجودة أو الملاءمة.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loaded ? _save : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ المسودة محلياً'),
          ),
          const SizedBox(height: 8),
          Text(_status),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          minLines: 1,
          maxLines: 3,
        ),
      );
}

/// Minimal local-first growth planner; this MVP stores only the user's plan
/// on-device and does not message customers or create financial projections.
class AurenBusinessGrowthPlannerScreen extends StatefulWidget {
  const AurenBusinessGrowthPlannerScreen({super.key});

  @override
  State<AurenBusinessGrowthPlannerScreen> createState() =>
      _AurenBusinessGrowthPlannerScreenState();
}

class _AurenBusinessGrowthPlannerScreenState
    extends State<AurenBusinessGrowthPlannerScreen> {
  static const _prefix = 'auren_business_growth_plan_v1';
  final _goal = TextEditingController();
  final _customers = TextEditingController();
  final _nextAction = TextEditingController();
  bool _loaded = false;
  String _status = 'خطتك تبقى على هذا الجهاز فقط.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _goal.dispose();
    _customers.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _goal.text = prefs.getString('${_prefix}_goal') ?? '';
      _customers.text = prefs.getString('${_prefix}_customers') ?? '';
      _nextAction.text = prefs.getString('${_prefix}_action') ?? '';
    } catch (_) {
      _status = 'التخزين المحلي غير متاح الآن.';
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final steps = AurenBusinessEconomyLogic.buildGrowthSteps(
      goal: _goal.text,
      customerGroup: _customers.text,
      nextAction: _nextAction.text,
    );
    if (steps.isEmpty) {
      setState(() => _status = 'أدخل هدفاً أو خطوة واحدة على الأقل.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}_goal', _goal.text.trim());
    await prefs.setString('${_prefix}_customers', _customers.text.trim());
    await prefs.setString('${_prefix}_action', _nextAction.text.trim());
    if (mounted) setState(() => _status = 'تم حفظ الخطة محلياً.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Business Growth Planner')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('خطة بسيطة للمشاريع الصغيرة، تعمل دون الحاجة لاتصال دائم.'),
            const SizedBox(height: 12),
            _field(_goal, 'هدف قابل للقياس'),
            _field(_customers, 'مجموعة العملاء المستهدفة'),
            _field(_nextAction, 'الخطوة العملية التالية'),
            FilledButton.icon(
              onPressed: _loaded ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الخطة'),
            ),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      );

  Widget _field(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          minLines: 1,
          maxLines: 3,
        ),
      );
}
