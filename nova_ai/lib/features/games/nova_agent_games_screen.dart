import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// NOVA's agent-game control surface.
///
/// This first delivery is deliberately an onboarding and safety layer. It does
/// not claim to run an autonomous agent from Android or to generate withdrawable
/// rewards. A supported runner and a user-created HaloArena connection are still
/// required before live play can be enabled.
class NovaAgentGamesScreen extends StatelessWidget {
  const NovaAgentGamesScreen({super.key});

  static const _haloArenaUrl = 'https://haloarena.ai/';
  static const _termsUrl = 'https://haloarena.ai/terms';
  static const _setupPrompt = '''
NOVA game-agent operating brief:
1. Use only the official HaloArena API and the current game rules endpoint.
2. Read the live game state and legal_actions before every move.
3. Submit only one legal action when is_your_turn is true.
4. Respect rate limits, matchmaking state, and the platform's fair-play rules.
5. Never request, store, transmit, or reveal wallet seed phrases or private keys.
6. Do not spend funds, place bets, buy tokens, or sign financial transactions.
7. Report match results and CP/HP separately from withdrawable money.
8. Stop and report if rules, eligibility, fees, or reward terms are unclear.
''';

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  Future<void> _copyPrompt(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _setupPrompt));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ تعليمات وكيل NOVA')),
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
                colors: [Color(0xFF34265F), Color(0xFF142D3B)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smart_toy_outlined, size: 34, color: Color(0xFFB8A7FF)),
                SizedBox(height: 10),
                Text('NOVA — وكيل الألعاب الذكي',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('الهدف: وكيل AI يقرأ حالة اللعبة ويختار الحركة القانونية وينفذها، بينما تتابع أنت النتائج.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _statusCard(
            icon: Icons.check_circle_outline,
            color: Colors.greenAccent,
            title: 'تم اختيار منصة الاختبار',
            detail: 'HaloArena تسمح لوكلاء AI باللعب عبر API رسمي وأفعال قانونية يحددها الخادم.',
          ),
          _statusCard(
            icon: Icons.hourglass_top,
            color: Colors.orangeAccent,
            title: 'تشغيل الوكيل: غير مفعّل بعد',
            detail: 'يتطلب إنشاء Agent من حسابك، ثم ربطه ببيئة تشغيل مدعومة مثل OpenClaw أو Hermes. تطبيق Android وحده لا يشغّل watcher حالياً.',
          ),
          _statusCard(
            icon: Icons.info_outline,
            color: Colors.orangeAccent,
            title: 'الأرباح: غير مثبتة',
            detail: 'رصيد CP/HP في HaloArena نقاط ترتيب تجريبية خارج البلوكشين، وليست USDT ولا تضمن مكافأة مالية.',
          ),
          const SizedBox(height: 10),
          const Text('منصة الاختبار الأولى',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HaloArena', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('ساحة ألعاب استراتيجية لوكلاء الذكاء الاصطناعي. الوكيل يلعب؛ أنت تراقب المباريات وتراجع القرارات.'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _open(context, _haloArenaUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('فتح HaloArena'),
                      ),
                      TextButton(
                        onPressed: () => _open(context, _termsUrl),
                        child: const Text('شروط الاستخدام'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('تعليمات الوكيل الآمن',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const Text('انسخ هذه التعليمات عند إعداد وكيلك في بيئة التشغيل. لا تتضمن أي مفتاح محفظة أو سر.'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SelectableText(_setupPrompt),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: () => _copyPrompt(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ تعليمات الوكيل'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('قواعد الحماية',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• لا إيداع ولا مراهنات ولا شراء نقاط.'),
                  Text('• لا تخزين لعبارة استرداد Trust Wallet أو المفتاح الخاص.'),
                  Text('• لا تجاوز لحظر السودان أو قيود المنصة.'),
                  Text('• لا تشغيل بوت إلا عبر API ومسار تسمح به قواعد اللعبة.'),
                  Text('• لا نحتسب النقاط دخلاً حتى يثبت السحب الفعلي إلى محفظتك.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('الخطوة التالية: ربط Runner آمن ثم اختبار مباراة مجانية واحدة. لا يتم تفعيل اللعب أو أي معاملة مالية تلقائياً من هذه الشاشة.',
              style: TextStyle(color: Colors.white70)),
        ],
      );

  static Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) =>
      Card(
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(detail),
          ),
          isThreeLine: true,
        ),
      );
}
