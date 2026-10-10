import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// First usable step of AUREN Business Navigator.
/// This screen creates an informational plan only; it does not submit registrations,
/// guarantee funding, or send messages on the user's behalf.
class AurenBusinessNavigatorScreen extends StatefulWidget {
  const AurenBusinessNavigatorScreen({super.key});

  @override
  State<AurenBusinessNavigatorScreen> createState() =>
      _AurenBusinessNavigatorScreenState();
}

class _AurenBusinessNavigatorScreenState
    extends State<AurenBusinessNavigatorScreen> {
  final _ideaController = TextEditingController();
  final _budgetController = TextEditingController();
  String _country = 'السودان';
  String _activity = 'تجارة';
  bool _planCreated = false;

  static const Map<String, Map<String, String>> _officialStartingPoints = {
    'السودان': {
      'registration': 'https://www.moj.gov.sd/posts/post/64',
      'tax': 'https://www.mof.gov.sd/',
      'customs': 'https://customs.gov.sd/',
      'investment': 'https://invest.gov.sd/',
    },
    'كينيا': {
      'registration': 'https://brs.go.ke/',
      'tax': 'https://www.kra.go.ke/',
      'customs': 'https://www.kra.go.ke/',
      'investment': 'https://www.investkenya.go.ke/',
    },
    'نيجيريا': {
      'registration': 'https://www.cac.gov.ng/',
      'tax': 'https://www.firs.gov.ng/',
      'customs': 'https://customs.gov.ng/',
      'investment': 'https://www.nipc.gov.ng/',
    },
    'مصر': {
      'registration': 'https://www.gafi.gov.eg/',
      'tax': 'https://www.eta.gov.eg/',
      'customs': 'https://www.customs.gov.eg/',
      'investment': 'https://www.gafi.gov.eg/',
    },
    'الإمارات العربية المتحدة': {
      'registration': 'https://u.ae/en/information-and-services/business',
      'tax': 'https://tax.gov.ae/',
      'customs': 'https://u.ae/en/information-and-services/finance-and-investment',
      'investment': 'https://u.ae/en/information-and-services/business',
    },
    'المملكة المتحدة': {
      'registration': 'https://www.gov.uk/set-up-business',
      'tax': 'https://www.gov.uk/government/organisations/hm-revenue-customs',
      'customs': 'https://www.gov.uk/trade-tariff',
      'investment': 'https://www.gov.uk/business-finance-support',
    },
    'الولايات المتحدة': {
      'registration': 'https://www.sba.gov/business-guide/launch-your-business',
      'tax': 'https://www.irs.gov/businesses',
      'customs': 'https://www.cbp.gov/trade',
      'investment': 'https://www.sba.gov/funding-programs',
    },
    'كندا': {
      'registration': 'https://www.canada.ca/en/services/business/start.html',
      'tax': 'https://www.canada.ca/en/revenue-agency/services/tax/businesses.html',
      'customs': 'https://www.cbsa-asfc.gc.ca/import/menu-eng.html',
      'investment': 'https://www.canada.ca/en/services/business/grants.html',
    },
  };

  @override
  void dispose() {
    _ideaController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  List<String> get _steps {
    final idea = _ideaController.text.trim();
    final steps = <String>[
      'حدّد العميل المستهدف والمشكلة التي سيحلّها المشروع.',
      'اختبر الطلب بمحادثة 5–10 عملاء محتملين قبل الالتزام بمصاريف كبيرة.',
      'اكتب قائمة بالتكاليف الأولية والمصاريف الشهرية ومصدر رأس المال.',
      'تحقق من تسجيل النشاط والضرائب والتراخيص من الجهات الرسمية أدناه.',
    ];
    if (_activity == 'استيراد وتصدير' || _activity == 'تصنيع') {
      steps.add('تحقق من متطلبات الجمارك والمواصفات والتصاريح الخاصة بالمنتج.');
    }
    if (_activity == 'تقنية وخدمات رقمية') {
      steps.add('جهّز نموذجاً أولياً بسيطاً وحدّد طريقة حماية بيانات العملاء.');
    }
    steps.add('قارن الموردين أو الشركاء المحتملين واطلب عروض أسعار مكتوبة.');
    steps.add('حدّد هدفاً قابلاً للقياس لأول 30 يوماً وراجع النتائج أسبوعياً.');
    if (idea.isNotEmpty) {
      steps.insert(0, 'الفكرة المسجلة: $idea');
    }
    return steps;
  }

  Future<void> _openSource(String key) async {
    final url = _officialStartingPoints[_country]?[key];
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sources = _officialStartingPoints[_country]!;
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Business Navigator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF34206F), Color(0xFF176A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text(
                  'من الفكرة إلى أول خطوة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'أنشئ خطة بداية أولية، ثم افتح المصادر الرسمية المناسبة لبلدك.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('عن مشروعك', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _ideaController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'فكرة المشروع',
              hintText: 'مثال: متجر ملابس أو مصنع صغير',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_planCreated) setState(() {});
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _country,
            decoration: const InputDecoration(
              labelText: 'الدولة المستهدفة',
              border: OutlineInputBorder(),
            ),
            items: _officialStartingPoints.keys
                .map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _country = value;
                  _planCreated = false;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _activity,
            decoration: const InputDecoration(
              labelText: 'نوع النشاط',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'تجارة', child: Text('تجارة')),
              DropdownMenuItem(value: 'تصنيع', child: Text('تصنيع')),
              DropdownMenuItem(value: 'استيراد وتصدير', child: Text('استيراد وتصدير')),
              DropdownMenuItem(value: 'زراعة', child: Text('زراعة')),
              DropdownMenuItem(value: 'تقنية وخدمات رقمية', child: Text('تقنية وخدمات رقمية')),
              DropdownMenuItem(value: 'خدمات', child: Text('خدمات')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _activity = value;
                  _planCreated = false;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'الميزانية التقريبية (اختياري)',
              hintText: 'مثال: 500 دولار أو 2 مليون جنيه',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => setState(() => _planCreated = true),
            icon: const Icon(Icons.checklist_rounded),
            label: const Text('أنشئ خطة البداية'),
          ),
          if (_planCreated) ...[
            const SizedBox(height: 24),
            Text('خطة البداية المقترحة', style: theme.textTheme.titleLarge),
            if (_budgetController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text('الميزانية التي أدخلتها: ${_budgetController.text.trim()}'),
              ),
            const SizedBox(height: 8),
            ..._steps.asMap().entries.map((entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                )),
            const SizedBox(height: 18),
            Text('مصادر رسمية للبدء', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _sourceTile('تسجيل الأعمال', Icons.business_center_outlined,
                () => _openSource('registration')),
            _sourceTile('الضرائب', Icons.receipt_long_outlined,
                () => _openSource('tax')),
            _sourceTile('الجمارك والتجارة', Icons.local_shipping_outlined,
                () => _openSource('customs')),
            _sourceTile('الاستثمار والتمويل', Icons.account_balance_outlined,
                () => _openSource('investment')),
            const SizedBox(height: 12),
            const Text(
              'تنبيه: هذه خطة إرشادية أولية وليست استشارة قانونية أو مالية. الروابط نقاط بداية رسمية وقد تتغير الإجراءات والرسوم وشروط الأهلية. تأكد من الجهة المختصة قبل الدفع أو تقديم المستندات.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sourceTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: const Text('فتح الموقع الرسمي'),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: onTap,
      ),
    );
  }
}
