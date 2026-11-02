import 'package:flutter/material.dart';

import 'nova_tor_research.dart';

class NovaTorResearchScreen extends StatefulWidget {
  const NovaTorResearchScreen({super.key});

  @override
  State<NovaTorResearchScreen> createState() => _NovaTorResearchScreenState();
}

class _NovaTorResearchScreenState extends State<NovaTorResearchScreen> {
  final _query = TextEditingController();
  bool _checking = false;
  bool _searching = false;
  bool? _proxyListening;
  bool? _torVerified;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openOrbot() async {
    try {
      await NovaTorResearch.openOrbot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('افتح Orbot واضغط Start، ثم ارجع إلى NOVA للتحقق.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orbot غير مثبت أو تعذر فتحه. ثبّته من المصدر الرسمي.')),
      );
    }
  }

  Future<void> _verify() async {
    setState(() {
      _checking = true;
      _error = null;
      _torVerified = null;
    });
    final listening = await NovaTorResearch.isProxyListening();
    final verified = listening && await NovaTorResearch.verifyTor();
    if (!mounted) return;
    setState(() {
      _proxyListening = listening;
      _torVerified = verified;
      _checking = false;
    });
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'اكتب موضوع البحث أولاً.');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
    });
    try {
      if (!await NovaTorResearch.verifyTor()) {
        throw StateError('لم يتم تأكيد اتصال Tor. لم يُرسل طلب البحث.');
      }
      final html = await NovaTorResearch.searchHtml(query);
      if (!mounted) return;
      setState(() => _result = html);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'تعذر البحث عبر Tor: $error');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('بحث NOVA عبر Tor')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'طلبات البحث هنا تمر حصراً عبر Orbot على 127.0.0.1:8118. '
                  'لا يوجد رجوع تلقائي إلى الإنترنت العادي. يتطلب البحث تثبيت Orbot وتشغيله.',
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _openOrbot,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('فتح Orbot'),
            ),
            OutlinedButton.icon(
              onPressed: _checking ? null : _verify,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(_checking ? 'جارٍ التحقق...' : 'التحقق من اتصال Tor'),
            ),
            if (_proxyListening != null)
              ListTile(
                leading: Icon(Icons.circle, color: _proxyListening! ? Colors.green : Colors.red),
                title: Text(_proxyListening! ? 'منفذ Orbot يستجيب' : 'منفذ Orbot غير متاح'),
                subtitle: const Text('127.0.0.1:8118'),
              ),
            if (_torVerified != null)
              ListTile(
                leading: Icon(Icons.circle, color: _torVerified! ? Colors.green : Colors.red),
                title: Text(_torVerified! ? 'تم تأكيد الخروج عبر Tor' : 'لم يتم تأكيد Tor'),
                subtitle: const Text('check.torproject.org/api/ip'),
              ),
            const Divider(),
            TextField(
              controller: _query,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'موضوع البحث',
                hintText: 'مثال: فرص تطبيقات الذكاء الاصطناعي مفتوحة المصدر',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _searching ? null : _search,
              icon: const Icon(Icons.travel_explore),
              label: Text(_searching ? 'جارٍ البحث عبر Tor...' : 'ابحث عبر Tor'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.orangeAccent)),
              ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              const Text('استجابة محرك البحث (HTML)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(_result!, maxLines: 80),
            ],
            const SizedBox(height: 12),
            const Text(
              'Tor لا يضمن إخفاء الهوية بالكامل. لا تدخل بيانات شخصية أو كلمات مرور. '
              'هذه النسخة تعرض استجابة محرك البحث الخام؛ تحليل النتائج وعرضها كبطاقات مرحلة لاحقة.',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
}
