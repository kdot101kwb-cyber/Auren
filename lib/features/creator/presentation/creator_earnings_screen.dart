import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/creator/creator_studio_repository.dart';

class AurenCreatorEarningsScreen extends StatelessWidget {
  const AurenCreatorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Sign in required')));
    final repo = AurenCreatorStudioRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Earnings')),
      body: StreamBuilder<List<AurenCreatorEarning>>(
        stream: repo.watchEarnings(uid),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('تعذر تحميل الأرباح: ${snap.error}'));
          final items = snap.data ?? const <AurenCreatorEarning>[];
          final pending = items.where((e) => e.status == 'pending_settlement').fold<int>(0, (a, e) => a + e.amountMinor);
          final settled = items.where((e) => e.status == 'settled').fold<int>(0, (a, e) => a + e.amountMinor);
          final currency = items.isNotEmpty ? items.first.currency : '---';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const Text('Creator Earnings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('سجل الأرباح الناتج من دعم الجمهور. هذه الشاشة لا تعني أن الأموال تم تحويلها أو تسويتها فعلياً.'),
              const SizedBox(height: 16),
              Row(children: [
                _stat('Pending', _money(pending, currency), Icons.hourglass_top_rounded),
                _stat('Settled', _money(settled, currency), Icons.check_circle_outline),
              ]),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد أرباح مسجلة حتى الآن.')))
              else
                ...items.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on_outlined),
                    title: Text(_money(e.amountMinor, e.currency)),
                    subtitle: Text('${e.type} • ${e.status}'),
                    trailing: Text(_date(e.createdAt)),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  static String _money(int minor, String currency) {
    return '${(minor / 100).toStringAsFixed(2)} ${currency.isEmpty ? '' : currency}';
  }

  static String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon), const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label),
      ]),
    )),
  );
}
