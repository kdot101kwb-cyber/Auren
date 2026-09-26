import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/creator/creator_studio_repository.dart';

class AurenCreatorEarningsScreen extends StatefulWidget {
  const AurenCreatorEarningsScreen({super.key});
  @override State<AurenCreatorEarningsScreen> createState() => _AurenCreatorEarningsScreenState();
}

class _AurenCreatorEarningsScreenState extends State<AurenCreatorEarningsScreen> {
  final _amount = TextEditingController();
  final _destination = TextEditingController();
  String _currency = 'USD';
  String _method = 'manual';
  bool _sending = false;
  @override void dispose(){ _amount.dispose(); _destination.dispose(); super.dispose(); }

  Future<void> _withdraw() async {
    final uid=FirebaseAuth.instance.currentUser?.uid; if(uid==null||_sending)return;
    final major=double.tryParse(_amount.text.trim()); final minor=major==null?(0):(major*100).round();
    if(minor<=0||_destination.text.trim().isEmpty)return;
    setState(()=>_sending=true);
    try { await AurenCreatorStudioRepository().requestWithdrawal(creatorUid:uid,amountMinor:minor,currency:_currency,method:_method,destination:_destination.text);
      _amount.clear(); _destination.clear(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب السحب للمراجعة.')));
    } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إرسال الطلب: $e'))); }
    finally{if(mounted)setState(()=>_sending=false);}
  }

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
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('طلب سحب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('متاح فقط للأرباح التي أصبحت settled. التنفيذ المالي الفعلي يحتاج مزود دفع مرتبط لاحقاً.'),
                const SizedBox(height: 10),
                TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal:true), decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'المبلغ')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value:_currency, decoration: const InputDecoration(border: OutlineInputBorder(), labelText:'العملة'), items: const [DropdownMenuItem(value:'USD',child:Text('USD')),DropdownMenuItem(value:'AED',child:Text('AED')),DropdownMenuItem(value:'SDG',child:Text('SDG'))], onChanged:(v)=>setState(()=>_currency=v??'USD'))),
                  const SizedBox(width:8),
                  Expanded(child: DropdownButtonFormField<String>(value:_method, decoration: const InputDecoration(border: OutlineInputBorder(), labelText:'الطريقة'), items: const [DropdownMenuItem(value:'manual',child:Text('Manual')),DropdownMenuItem(value:'bank',child:Text('Bank')),DropdownMenuItem(value:'mobile_money',child:Text('Mobile Money'))], onChanged:(v)=>setState(()=>_method=v??'manual'))),
                ]),
                const SizedBox(height: 8),
                TextField(controller:_destination, maxLength:300, decoration: const InputDecoration(border: OutlineInputBorder(), labelText:'بيانات الاستلام')),
                const SizedBox(height: 8),
                SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_sending?null:_withdraw,icon:const Icon(Icons.send_rounded),label:Text(_sending?'جاري الإرسال...':'إرسال طلب السحب'))),
              ])),
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
