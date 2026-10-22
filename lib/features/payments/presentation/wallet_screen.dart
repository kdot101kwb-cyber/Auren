import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/payments/auren_money_insights.dart';
import '../../../services/payments/wallet_service.dart';

class AurenWalletScreen extends StatefulWidget {
  const AurenWalletScreen({super.key});
  @override
  State<AurenWalletScreen> createState() => _AurenWalletScreenState();
}

class _AurenWalletScreenState extends State<AurenWalletScreen> {
  final service = AurenWalletService();
  final insights = const AurenMoneyInsights();
  final currency = TextEditingController(text: 'USD');

  @override
  void dispose() {
    currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Wallet')),
      body: StreamBuilder<AurenWallet?>(
        stream: service.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل المحفظة: ${snapshot.error}'));
          }
          final wallet = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(wallet == null ? 'المحفظة غير مفعّلة' : wallet.currency),
                  subtitle: Text(wallet == null
                      ? 'أنشئ محفظتك للبدء'
                      : 'الرصيد: ${(wallet.balanceMinor / 100).toStringAsFixed(2)} ${wallet.currency}'),
                ),
              ),
              if (wallet == null)
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await service.initialize(uid: uid, currency: currency.text);
                      if (mounted) setState(() {});
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$error')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء المحفظة'),
                ),
              if (wallet != null) ...[
                ListTile(
                  title: const Text('العملات'),
                  subtitle: Text(wallet.balancesMinor.keys.join(' • ')),
                  trailing: TextButton(
                    onPressed: () => _currency(context, uid),
                    child: const Text('إضافة'),
                  ),
                ),
                ListTile(
                  title: const Text('حد الإنفاق'),
                  subtitle: const Text('حماية إضافية قبل ربط بوابات الدفع'),
                  trailing: TextButton(
                    onPressed: () => _limit(context, uid),
                    child: const Text('تعديل'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text('المعاملات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.watchTransactions(uid),
                builder: (context, transactionSnapshot) {
                  final items = transactionSnapshot.data ?? const [];
                  if (transactionSnapshot.hasError) {
                    return const Card(
                      child: ListTile(title: Text('تعذر تحميل المعاملات حالياً.')),
                    );
                  }
                  final normalized = items.map((item) {
                    final copy = Map<String, dynamic>.from(item);
                    final date = copy['createdAt'];
                    if (date != null && date is! DateTime && date is! String) {
                      try {
                        final converted = (date as dynamic).toDate();
                        if (converted is DateTime) copy['createdAt'] = converted;
                      } catch (_) {
                        // The insight helper safely ignores unknown date values.
                      }
                    }
                    return copy;
                  }).toList();
                  final spend = insights.monthlySpendByCurrency(normalized);
                  final categories = insights.monthlySpendByCategory(normalized);
                  final trend = insights.monthlySpendTrendByCurrency(normalized);
                  final recurring = insights.recurringExpenseCandidates(normalized);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.insights_outlined),
                                  SizedBox(width: 8),
                                  Text('ذكاء AUREN المالي',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('تحليل محلي للمعاملات المتاحة؛ لا ينفّذ أي دفعات.'),
                              const SizedBox(height: 8),
                              if (spend.isEmpty)
                                const Text('أضف معاملات مصنّفة كمصروفات لعرض ملخص الشهر.')
                              else
                                ...spend.entries.map((entry) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('مصروفات هذا الشهر • ${entry.key}'),
                                      trailing: Text('${entry.value} ${entry.key}'),
                                    )),

                              if (trend.isNotEmpty) ...[
                                const Divider(),
                                const Text('مقارنة بالشهر السابق', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...trend.entries.map((entry) {
                                  final delta = entry.value['deltaMinor'] ?? 0;
                                  final direction = delta > 0 ? 'زيادة' : delta < 0 ? 'انخفاض' : 'دون تغيير';
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.key),
                                    subtitle: Text('السابق ${entry.value['previousMinor']} • الحالي ${entry.value['currentMinor']} ${entry.key}'),
                                    trailing: Text('$direction ${delta.abs()}'),
                                  );
                                }),
                              ],
                              if (categories.isNotEmpty) ...[
                                const Divider(),
                                const Text('التصنيف الشهري للمصروفات', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...categories.entries.expand((currencyEntry) => [
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('العملة: ${currencyEntry.key}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  ...currencyEntry.value.entries.map((categoryEntry) => ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(left: 16),
                                    title: Text(categoryEntry.key),
                                    trailing: Text('${categoryEntry.value} ${currencyEntry.key}'),
                                  )),
                                ]),
                              ],
                              if (recurring.isNotEmpty) ...[
                                const Divider(),
                                const Text('مصروفات متكررة محتملة',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                ...recurring.take(5).map((candidate) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(candidate['label'] as String),
                                      subtitle: Text(
                                        '${candidate['occurrences']} معاملات • متوسط ${candidate['averageAmountMinor']} ${candidate['currency']}',
                                      ),
                                      trailing: const Icon(Icons.repeat),
                                    )),
                                const Text(
                                  'هذه اقتراحات آلية وليست اشتراكات مؤكدة.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('لا توجد معاملات بعد.'),
                          ),
                        )
                      else
                        ...items.map((item) => Card(
                              child: ListTile(
                                title: Text(item['type']?.toString() ?? 'Transaction'),
                                subtitle: Text(item['currency']?.toString() ?? ''),
                                trailing: Text(item['amountMinor']?.toString() ?? '0'),
                              ),
                            )),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _currency(BuildContext context, String uid) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عملة'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'EUR'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      try {
        await service.addCurrency(uid: uid, currency: controller.text);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
    controller.dispose();
  }

  Future<void> _limit(BuildContext context, String uid) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حد الإنفاق'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'بالوحدة الصغرى للعملة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      final value = int.tryParse(controller.text.trim());
      if (value != null) {
        try {
          await service.setSpendingLimit(uid: uid, limitMinor: value);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      }
    }
    controller.dispose();
  }
}
