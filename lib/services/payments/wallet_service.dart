import 'package:cloud_firestore/cloud_firestore.dart';

class AurenWallet {
  final String uid, currency, status;
  final int balanceMinor;
  final Map<String,int> balancesMinor;
  const AurenWallet({required this.uid, required this.currency, required this.balanceMinor, required this.balancesMinor, required this.status});
  factory AurenWallet.fromMap(String uid, Map<String,dynamic> d) {
    final balances = <String,int>{}; final raw=d['balancesMinor'];
    if(raw is Map) for(final e in raw.entries) if(e.value is int) balances[e.key.toString().toUpperCase()]=e.value as int;
    final base=d['currency']?.toString().toUpperCase()??'USD';
    final balance=d['balanceMinor'] is int?d['balanceMinor'] as int:(balances[base]??0); balances.putIfAbsent(base,()=>balance);
    return AurenWallet(uid:uid,currency:base,balanceMinor:balance,balancesMinor:Map.unmodifiable(balances),status:d['status']?.toString()??'active');
  }
}

class AurenExchangeRate {
  final String base, quote; final double rate; final DateTime? updatedAt;
  const AurenExchangeRate({required this.base,required this.quote,required this.rate,this.updatedAt});
}

class AurenWalletService {
  final FirebaseFirestore db;
  AurenWalletService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  DocumentReference<Map<String,dynamic>> _wallet(String uid)=>db.collection('wallets').doc(uid);
  CollectionReference<Map<String,dynamic>> _tx(String uid)=>_wallet(uid).collection('transactions');
  Stream<AurenWallet?> watch(String uid)=>_wallet(uid).snapshots().map((d)=>d.exists&&d.data()!=null?AurenWallet.fromMap(uid,d.data()!):null);
  Stream<List<Map<String,dynamic>>> watchTransactions(String uid)=>_tx(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
  Future<void> initialize({required String uid,required String currency})async{final c=currency.trim().toUpperCase();if(uid.trim().isEmpty)throw ArgumentError('المستخدم مطلوب');if(!RegExp(r'^[A-Z]{3}$').hasMatch(c))throw ArgumentError('العملة غير صالحة');final ref=_wallet(uid);if((await ref.get()).exists)return;await ref.set({'uid':uid,'currency':c,'balanceMinor':0,'balancesMinor':{c:0},'status':'active','createdAt':FieldValue.serverTimestamp()});}
  Future<void> addCurrency({required String uid,required String currency})async{final c=currency.trim().toUpperCase();if(!RegExp(r'^[A-Z]{3}$').hasMatch(c))throw ArgumentError('العملة غير صالحة');await _wallet(uid).update({'balancesMinor.$c':FieldValue.increment(0),'updatedAt':FieldValue.serverTimestamp()});}
  Future<void> setSpendingLimit({required String uid,required int limitMinor})async{if(limitMinor<0)throw ArgumentError('الحد غير صالح');await _wallet(uid).update({'spendingLimitMinor':limitMinor,'updatedAt':FieldValue.serverTimestamp()});}
  Future<AurenExchangeRate?> getRate({required String base,required String quote})async{final b=base.toUpperCase(),q=quote.toUpperCase();if(b==q)return AurenExchangeRate(base:b,quote:q,rate:1);final d=await db.collection('exchange_rates').doc('${b}_$q').get();if(!d.exists)return null;final r=d.data()?['rate'];if(r is! num||r<=0)return null;final ts=d.data()?['updatedAt'];return AurenExchangeRate(base:b,quote:q,rate:r.toDouble(),updatedAt:ts is Timestamp?ts.toDate():null);}
}