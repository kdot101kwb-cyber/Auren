import 'package:flutter/material.dart';
import '../../business/presentation/business_screen.dart';
import '../../personal_ai/presentation/supplier_finder_screen.dart';

class AurenStartBusinessScreen extends StatefulWidget {
  const AurenStartBusinessScreen({super.key});
  @override
  State<AurenStartBusinessScreen> createState() => _AurenStartBusinessScreenState();
}

class _AurenStartBusinessScreenState extends State<AurenStartBusinessScreen> {
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _budget = TextEditingController();
  final _idea = TextEditingController();
  String _kind = 'تجارة وبيع';
  String _stage = 'فكرة فقط';
  bool _showPlan = false;
  final Set<int> _completedSteps = <int>{};

  static const _kinds = [
    'تجارة وبيع', 'مصنع وإنتاج', 'زراعة وثروة حيوانية',
    'تقنية وخدمات رقمية', 'خدمات محلية', 'استيراد وتصدير',
  ];
  static const _stages = ['فكرة فقط', 'أبحث عن الموردين', 'أجهّز التمويل', 'نشاط قائم وأريد التوسع'];

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    _budget.dispose();
    _idea.dispose();
    super.dispose();
  }

  List<String> _buildPlan() => [
    'تحقق من الطلب والمنافسين في ${_city.text.trim().isEmpty ? 'المدينة المستهدفة' : _city.text.trim()}، ولا تعتمد على توقعات غير موثقة.',
    'اكتب قائمة المنتجات أو الخدمات والتكاليف الأساسية، ثم قارن أكثر من عرض سعر من موردين مستقلين.',
    'راجع جهة تسجيل الأعمال والجهات الضريبية والجمارك الرسمية في ${_country.text.trim()} قبل دفع رسوم أو توقيع عقد.',
    'قارن شروط الحسابات التجارية وتمويل المنشآت من البنوك المرخصة في الدولة؛ ميّز بين القرض والمنحة والاستثمار.',
    'أنشئ صفحة نشاط في AUREN لعرض المعلومات التي تملك حق نشرها، ثم أضف المنتجات والخدمات وبيانات التواصل.',
    if (_kind == 'مصنع وإنتاج') 'تحقق من متطلبات الموقع الصناعي والسلامة والبيئة والطاقة والعمالة وتراخيص الإنتاج.',
    if (_kind == 'زراعة وثروة حيوانية') 'تحقق من توفر المياه والمدخلات والموسمية والخدمات البيطرية والتراخيص الزراعية.',
    if (_kind == 'استيراد وتصدير') 'تحقق من رموز HS ومتطلبات الاستيراد والتصدير وشهادات المنشأ والجمارك في طرفي التجارة.',
    if (_stage == 'أبحث عن الموردين') 'ابدأ بمقارنة الموردين واطلب عروض أسعار مكتوبة تتضمن المواصفات والحد الأدنى للطلب والشحن.',
    if (_stage == 'أجهّز التمويل') 'جهّز ملخص المشروع وتوقعات التدفق النقدي واستخدام الأموال والضمانات المطلوبة قبل التقديم.',
    if (_stage == 'نشاط قائم وأريد التوسع') 'راجع المبيعات والهامش والتدفق النقدي والطاقة التشغيلية قبل اختيار سوق أو منتج جديد.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Start a Business')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary.withValues(alpha: .24),
                theme.colorScheme.tertiary.withValues(alpha: .14),
              ]),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.rocket_launch_outlined, size: 36),
              SizedBox(height: 12),
              Text('من الفكرة إلى خطة قابلة للتنفيذ', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('نظّم الخطوات والأسئلة التي تحتاج إلى التحقق منها. هذه خطة أولية وليست دراسة جدوى أو استشارة قانونية أو موافقة تمويل.'),
            ]),
          ),
          const SizedBox(height: 18),
          TextField(controller: _idea, maxLines: 2, decoration: const InputDecoration(labelText: 'فكرة المشروع أو المنتج', hintText: 'مثال: مصنع ملابس أو متجر مواد غذائية', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'نوع المشروع', border: OutlineInputBorder()),
            items: _kinds.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 12),
          TextField(controller: _country, decoration: const InputDecoration(labelText: 'الدولة التي ستبدأ فيها', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'المدينة (اختياري)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _budget, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الميزانية والعملة (اختياري)', hintText: 'مثال: 5000 USD', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stage,
            decoration: const InputDecoration(labelText: 'مرحلة المشروع', border: OutlineInputBorder()),
            items: _stages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _stage = v ?? _stage),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(() => _showPlan = true),
            icon: const Icon(Icons.checklist),
            label: const Text('أنشئ خطة الخطوات الأولية'),
          ),
          if (_showPlan) ...[
            const SizedBox(height: 22),
            Text('خطة البداية', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (_idea.text.trim().isNotEmpty) ListTile(leading: const Icon(Icons.lightbulb_outline), title: const Text('فكرة المشروع'), subtitle: Text(_idea.text.trim())),
            if (_budget.text.trim().isNotEmpty) ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('الميزانية المبدئية'), subtitle: Text(_budget.text.trim())),
            ..._buildPlan().asMap().entries.map((entry) => Card(
              child: CheckboxListTile(
                value: _completedSteps.contains(entry.key),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _completedSteps.add(entry.key);
                  } else {
                    _completedSteps.remove(entry.key);
                  }
                }),
                title: Text(entry.value),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenBusinessScreen())),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('استكشف صفحات الشركات والأنشطة'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AurenSupplierFinderScreen())),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('افتح أداة البحث عن الموردين'),
            ),
            const SizedBox(height: 8),
            Text('الخطوة التالية: تحقق من الإجراءات الحكومية والمصادر المالية الرسمية في الدولة المختارة. لا تدفع رسوم تقديم عبر روابط غير رسمية.', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
