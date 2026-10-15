import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenCountryBankRegulatorsScreen extends StatefulWidget {
  const AurenCountryBankRegulatorsScreen({super.key});

  @override
  State<AurenCountryBankRegulatorsScreen> createState() => _AurenCountryBankRegulatorsScreenState();
}

class _AurenCountryBankRegulatorsScreenState extends State<AurenCountryBankRegulatorsScreen> {
  String _query = '';
  String _region = 'الكل';

  static const List<Map<String, String>> _sources = [
    {'country':'السودان','countryEn':'Sudan','region':'أفريقيا','authority':'بنك السودان المركزي','url':'https://cbos.gov.sd/ar/node/24142','source':'قائمة المصارف والمؤسسات المالية المرخص لها','level':'صفحة قائمة رسمية'},
    {'country':'كينيا','countryEn':'Kenya','region':'أفريقيا','authority':'Central Bank of Kenya','url':'https://www.centralbank.go.ke/bank-supervision/regulated-banks/','source':'Regulated Banks','level':'سجل رقابي مباشر'},
    {'country':'نيجيريا','countryEn':'Nigeria','region':'أفريقيا','authority':'Central Bank of Nigeria','url':'https://www.cbn.gov.ng/','source':'الموقع الرقابي الرسمي؛ ابحث عن قائمة البنوك المرخصة','level':'بوابة الجهة الرقابية'},
    {'country':'غانا','countryEn':'Ghana','region':'أفريقيا','authority':'Bank of Ghana','url':'https://www.bog.gov.gh/','source':'الموقع الرقابي الرسمي؛ البنوك والمؤسسات المرخصة','level':'بوابة الجهة الرقابية'},
    {'country':'جنوب أفريقيا','countryEn':'South Africa','region':'أفريقيا','authority':'South African Reserve Bank / Prudential Authority','url':'https://www.resbank.co.za/','source':'الجهة الرقابية المصرفية الرسمية','level':'بوابة الجهة الرقابية'},
    {'country':'أوغندا','countryEn':'Uganda','region':'أفريقيا','authority':'Bank of Uganda','url':'https://www.bou.or.ug/','source':'الموقع الرسمي للبنك والرقابة المصرفية','level':'بوابة الجهة الرقابية'},
    {'country':'تنزانيا','countryEn':'Tanzania','region':'أفريقيا','authority':'Bank of Tanzania','url':'https://www.bot.go.tz/','source':'الموقع الرسمي والرقابة المصرفية','level':'بوابة الجهة الرقابية'},
    {'country':'رواندا','countryEn':'Rwanda','region':'أفريقيا','authority':'National Bank of Rwanda','url':'https://www.bnr.rw/','source':'الموقع الرسمي والجهات المالية الخاضعة للرقابة','level':'بوابة الجهة الرقابية'},
    {'country':'المغرب','countryEn':'Morocco','region':'أفريقيا','authority':'Bank Al-Maghrib','url':'https://www.bkam.ma/','source':'الموقع الرسمي والقطاع المصرفي','level':'بوابة الجهة الرقابية'},
    {'country':'مصر','countryEn':'Egypt','region':'أفريقيا','authority':'Central Bank of Egypt','url':'https://www.cbe.org.eg/','source':'الموقع الرسمي للرقابة المصرفية','level':'بوابة الجهة الرقابية'},
    {'country':'الإمارات العربية المتحدة','countryEn':'United Arab Emirates','region':'الشرق الأوسط','authority':'Central Bank of the UAE','url':'https://centralbank.ae/en/licensing','source':'CBUAE Register — Financial Institutions','level':'سجل ترخيص مباشر'},
    {'country':'السعودية','countryEn':'Saudi Arabia','region':'الشرق الأوسط','authority':'Saudi Central Bank (SAMA)','url':'https://www.sama.gov.sa/en-US/Pages/default.aspx','source':'الموقع الرسمي؛ البنوك المرخصة','level':'بوابة الجهة الرقابية'},
    {'country':'المملكة المتحدة','countryEn':'United Kingdom','region':'أوروبا','authority':'Financial Conduct Authority','url':'https://register.fca.org.uk/','source':'Financial Services Register — تحقق من المؤسسة والترخيص','level':'سجل رقابي مباشر'},
    {'country':'الاتحاد الأوروبي','countryEn':'European Union','region':'أوروبا','authority':'European Central Bank / National Supervisors','url':'https://www.bankingsupervision.europa.eu/about/organisation/national-supervisors/html/index.en.html','source':'قائمة السلطات الوطنية للرقابة المصرفية','level':'دليل الجهات الرقابية'},
    {'country':'الولايات المتحدة','countryEn':'United States','region':'أمريكا الشمالية','authority':'FDIC','url':'https://banks.data.fdic.gov/bankfind-suite/bankfind','source':'BankFind Suite — البحث عن البنوك والمؤسسات المؤمّنة','level':'أداة بحث رسمية'},
    {'country':'كندا','countryEn':'Canada','region':'أمريكا الشمالية','authority':'Office of the Superintendent of Financial Institutions','url':'https://www.osfi-bsif.gc.ca/en/supervision/financial-institutions','source':'قائمة المؤسسات المالية الخاضعة للإشراف','level':'صفحة رقابية رسمية'},
    {'country':'سريلانكا','countryEn':'Sri Lanka','region':'آسيا','authority':'Central Bank of Sri Lanka','url':'https://www.cbsl.gov.lk/en/node/2931','source':'Licensed Commercial Banks','level':'قائمة رسمية مباشرة'},
    {'country':'الهند','countryEn':'India','region':'آسيا','authority':'Reserve Bank of India','url':'https://www.rbi.org.in/','source':'الموقع الرسمي؛ قوائم البنوك المجدولة والمرخصة','level':'بوابة الجهة الرقابية'},
    {'country':'سنغافورة','countryEn':'Singapore','region':'آسيا','authority':'Monetary Authority of Singapore','url':'https://www.mas.gov.sg/','source':'Financial Institutions Directory','level':'بوابة الجهة الرقابية'},
    {'country':'أستراليا','countryEn':'Australia','region':'أوقيانوسيا','authority':'Australian Prudential Regulation Authority','url':'https://www.apra.gov.au/register-of-authorised-deposit-taking-institutions','source':'Register of authorised deposit-taking institutions','level':'سجل رقابي مباشر'},
    {'country':'باربادوس','countryEn':'Barbados','region':'الكاريبي','authority':'Central Bank of Barbados','url':'https://www.centralbank.org.bb/financial-stability-and-financial-regulation/licensed-financial-institutions','source':'Licensed Financial Institutions','level':'قائمة رسمية مباشرة'},
  ];

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الموقع الرسمي الآن.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sources.where((item) {
      final text = [item['country'], item['countryEn'], item['authority'], item['source'], item['region']].join(' ').toLowerCase();
      return (_query.isEmpty || text.contains(_query.toLowerCase())) &&
          (_region == 'الكل' || item['region'] == _region);
    }).toList();
    final regions = ['الكل', ..._sources.map((e) => e['region']!).toSet().toList()..sort()];

    return Scaffold(
      appBar: AppBar(title: const Text('البنوك المرخصة حسب الدولة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'دليل للوصول إلى الجهات الرقابية وسجلات البنوك حسب الدولة. لا نعتبر وجود رابط دليلاً على أن كل بنك نشط أو مرخص حالياً. افتح السجل الرسمي وتحقق من اسم المؤسسة ونوع الترخيص وتاريخ التحديث قبل إرسال أموال أو فتح حساب.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث بالدولة أو الجهة الرقابية',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder()),
            items: regions.map((value) => DropdownMenuItem(
              value: value,
              child: Text(value == 'الكل' ? 'كل المناطق' : value),
            )).toList(),
            onChanged: (value) => setState(() => _region = value ?? 'الكل'),
          ),
          const SizedBox(height: 12),
          Text('عدد الجهات: ${rows.length}', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...rows.map((item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.verified_user_outlined)),
              title: Text(item['country']!),
              subtitle: Text('${item['authority']}\n${item['level']} • ${item['source']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.open_in_new),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      runSpacing: 12,
                      children: [
                        Text(item['country']!, style: Theme.of(ctx).textTheme.titleLarge),
                        Text('الجهة الرقابية: ${item['authority']}'),
                        Text('نوع المصدر: ${item['level']}'),
                        Text('السجل/المصدر: ${item['source']}'),
                        const Text('تأكد من أن السجل يخص الدولة المطلوبة ومن حالة الترخيص الحالية؛ قد تختلف تراخيص البنوك عن تراخيص التمويل أو الدفع الإلكتروني.'),
                        FilledButton.icon(
                          onPressed: () { Navigator.pop(ctx); _open(item['url']!); },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('فتح المصدر الرسمي'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
