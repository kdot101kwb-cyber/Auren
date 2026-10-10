import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AurenSudanBanksScreen extends StatefulWidget {
  const AurenSudanBanksScreen({super.key});
  @override
  State<AurenSudanBanksScreen> createState() => _AurenSudanBanksScreenState();
}

class _AurenSudanBanksScreenState extends State<AurenSudanBanksScreen> {
  late final Future<Map<String, dynamic>> _catalog = _load();
  String _query = '';

  Future<Map<String, dynamic>> _load() async => jsonDecode(
    await rootBundle.loadString('assets/sudan_banks_cbos_v1.json'),
  ) as Map<String, dynamic>;

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح موقع بنك السودان المركزي الآن.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البنوك في السودان')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('تعذر تحميل القائمة الرسمية. حاول لاحقاً.'));
        }
        final catalog = snapshot.data!;
        final banks = (catalog['banks'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .where((bank) => (bank['name']?.toString() ?? '')
                .toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('قائمة استرشادية مبنية على صفحة «البنوك العاملة بالسودان» المنشورة لدى بنك السودان المركزي. القائمة لا تؤكد أن كل فرع يعمل حالياً؛ تحقّق من أحدث الإعلانات ومن الترخيص وتوفر الخدمة قبل التعامل.'),
          )),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن بنك بالاسم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('عدد الأسماء في سجل المصدر: ${banks.length}',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...banks.map((bank) => Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.account_balance)),
            title: Text(bank['name']?.toString() ?? 'بنك'),
            subtitle: const Text('المصدر: بنك السودان المركزي • يلزم التحقق من الحالة الحالية'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (ctx) => SafeArea(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(runSpacing: 12, children: [
                  Text(bank['name']?.toString() ?? 'بنك',
                    style: Theme.of(ctx).textTheme.titleLarge),
                  const Text('الإدراج في القائمة الرسمية لا يثبت أن كل الفروع أو الخدمات متاحة حالياً.'),
                  const Text('افحص الترخيص والتحديثات وبيانات التواصل في موقع الجهة الرقابية قبل إرسال أموال أو مستندات.'),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _open(catalog['directory_url']?.toString() ?? '');
                    },
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('تحقق عبر بنك السودان المركزي'),
                  ),
                ]),
              )),
            ),
          ))),
          const SizedBox(height: 12),
          const Text('المصدر الرسمي: بنك السودان المركزي. لا نعرض هنا أرقام حسابات أو أسعار أو روابط تواصل غير متحققة.',
            style: TextStyle(fontSize: 12)),
        ]);
      },
    ),
  );
}
