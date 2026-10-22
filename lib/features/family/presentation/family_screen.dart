import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/family/family_pot_repository.dart';
import '../../../services/family/auren_family_wallet_repository.dart';
import '../../../services/family/auren_family_wallet_insights.dart';

class AurenFamilyScreen extends StatefulWidget {
  const AurenFamilyScreen({super.key});
  @override State<AurenFamilyScreen> createState() => _AurenFamilyScreenState();
}
class _AurenFamilyScreenState extends State<AurenFamilyScreen> {
  final _repo = FamilyPotRepository();
  final _familyWallet = AurenFamilyWalletRepository();
  final _walletTitle = TextEditingController();
  final _walletAmount = TextEditingController();
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _currency = 'USD';
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  @override void dispose() { _name.dispose(); _relation.dispose(); _title.dispose(); _amount.dispose(); _walletTitle.dispose(); _walletAmount.dispose(); super.dispose(); }
  Future<void> _member() async { final uid=_uid; if(uid==null)return; await _repo.addMember(uid:uid,name:_name.text,relation:_relation.text); _name.clear(); _relation.clear(); if(mounted)Navigator.pop(context); }
  Future<void> _pot() async { final uid=_uid; final amount=int.tryParse(_amount.text); if(uid==null||amount==null)return; await _repo.addPotEntry(uid:uid,title:_title.text,amountMinor:amount,currency:_currency); _title.clear(); _amount.clear(); if(mounted)Navigator.pop(context); }
  Future<void> _recordFamilyWalletEntry(String uid, String kind) async {
    final amount = int.tryParse(_walletAmount.text.trim());
    try {
      if (amount == null) throw ArgumentError('أدخل المبلغ بالأصغر وحدة.');
      await _familyWallet.recordEntry(
        uid: uid,
        title: _walletTitle.text,
        amountMinor: amount,
        currency: _currency,
        kind: kind,
      );
      _walletTitle.clear();
      _walletAmount.clear();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  void _addFamilyWalletEntry(String uid) {
    _walletTitle.clear();
    _walletAmount.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تسجيل حركة في محفظة الأسرة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _walletTitle,
              decoration: const InputDecoration(labelText: 'الوصف'),
              maxLength: 160,
            ),
            TextField(
              controller: _walletAmount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ بالأصغر وحدة (مثلاً سنتات)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'العملة'),
              items: const ['USD', 'SDG', 'EUR']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'USD'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _recordFamilyWalletEntry(uid, 'expense'),
                  child: const Text('تسجيل مصروف'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _recordFamilyWalletEntry(uid, 'income'),
                  child: const Text('تسجيل دخل'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _addMember() => showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,16+MediaQuery.viewInsetsOf(context).bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:_name,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:_relation,decoration:const InputDecoration(labelText:'صلة القرابة')),const SizedBox(height:12),FilledButton(onPressed:_member,child:const Text('حفظ'))])));
  void _addPot() => showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(16,16,16,16+MediaQuery.viewInsetsOf(context).bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:_title,decoration:const InputDecoration(labelText:'الوصف')),TextField(controller:_amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ بالأصغر وحدة')),DropdownButtonFormField<String>(initialValue:_currency,items:const ['USD','SDG','EUR'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>_currency=v??'USD')),const SizedBox(height:12),FilledButton(onPressed:_pot,child:const Text('حفظ'))])));
  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام مساحة الأسرة.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AUREN Family')),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add_circle_outline),
        onSelected: (v) => v == 'member' ? _addMember() : _addPot(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'member', child: Text('إضافة فرد')),
          PopupMenuItem(value: 'pot', child: Text('إضافة للصندوق')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(child: ListTile(
            leading: Icon(Icons.family_restroom),
            title: Text('Family Hub'),
            subtitle: Text('أفراد الأسرة والأهداف المشتركة وصندوق الأسرة.'),
          )),
          const SizedBox(height: 12),
          const Text('محفظة الأسرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<AurenFamilyWallet?>(
            stream: _familyWallet.watch(uid),
            builder: (context, walletSnapshot) {
              if (walletSnapshot.hasError) {
                return const Card(child: ListTile(title: Text('تعذر تحميل محفظة الأسرة.')));
              }
              final wallet = walletSnapshot.data;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wallet == null) ...[
                        const Text('محفظة تخطيطية لتسجيل دخل الأسرة ومصروفاتها. لا تنفّذ تحويلات فعلية.'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await _familyWallet.initialize(uid: uid, currency: _currency);
                            } catch (error) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$error')),
                              );
                            }
                          },
                          child: const Text('إنشاء محفظة الأسرة'),
                        ),
                      ] else ...[
                        ...wallet.balancesMinor.entries.map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                          title: Text('الرصيد المتاح • ${entry.key}'),
                          trailing: Text('${(entry.value / 100).toStringAsFixed(2)} ${entry.key}'),
                        )),
                        OutlinedButton.icon(
                          onPressed: () => _addFamilyWalletEntry(uid),
                          icon: const Icon(Icons.add),
                          label: const Text('تسجيل دخل أو مصروف'),
                        ),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _familyWallet.watchEntries(uid),
                          builder: (context, entriesSnapshot) {
                            final entries = entriesSnapshot.data ?? const <Map<String, dynamic>>[];
                            if (entriesSnapshot.hasError) {
                              return const ListTile(title: Text('تعذر تحميل سجل المحفظة.'));
                            }
                            if (entries.isEmpty) {
                              return const ListTile(title: Text('لا توجد حركات مسجلة بعد.'));
                            }
                            return Column(
                              children: entries.take(5).map((entry) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(entry['kind'] == 'income'
                                  ? Icons.south_west : Icons.north_east),
                                title: Text(entry['title'] as String? ?? ''),
                                subtitle: Text(entry['kind'] == 'income' ? 'دخل' : 'مصروف'),
                                trailing: Text('${(((entry['amountMinor'] as num?)?.toInt() ?? 0) / 100).toStringAsFixed(2)} ${entry['currency'] ?? ''}'),
                              )).toList(),
                            );
                          },
                        ),
                        const Text('سجل يدوي للتخطيط فقط؛ لا توجد تحويلات أو مدفوعات فعلية.',
                          style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('أفراد الأسرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<List<Map<String,dynamic>>>(
            stream: _repo.watchMembers(uid),
            builder: (_, s) {
              final x = s.data ?? const <Map<String,dynamic>>[];
              if (s.hasError) return const ListTile(title: Text('تعذر تحميل أفراد الأسرة.'));
              if (x.isEmpty) return const ListTile(title: Text('لم تتم إضافة أفراد بعد.'));
              return Column(
                children: x.map((m) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(m['name'] as String? ?? ''),
                    subtitle: Text(m['relation'] as String? ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _repo.deleteMember(uid, m['id'] as String),
                    ),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Family Pot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          StreamBuilder<List<Map<String,dynamic>>>(
            stream: _repo.watchPot(uid),
            builder: (_, s) {
              final x = s.data ?? const <Map<String,dynamic>>[];
              if (s.hasError) return const ListTile(title: Text('تعذر تحميل الصندوق.'));
              if (x.isEmpty) return const ListTile(title: Text('لا توجد حركات في الصندوق بعد.'));
              return Column(
                children: x.map((m) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.savings_outlined),
                    title: Text(m['title'] as String? ?? ''),
                    subtitle: Text('${m['amountMinor'] ?? 0} ${m['currency'] ?? ''}'),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}