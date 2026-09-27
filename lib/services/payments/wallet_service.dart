import 'package:cloud_firestore/cloud_firestore.dart';

class AurenWallet {
  final String uid,currency,status;
  final int balanceMinor;
  const AurenWallet({required this.uid,required this.currency,required this.balanceMinor,required this.status});
  factory AurenWallet.fromMap(String uid,Map<String,dynamic> d)=>AurenWallet(uid:uid,currency:d['currency']?.toString()??'USD',balanceMinor:d['balanceMinor'] is int?d['balanceMinor'] as int:0,status:d['status']?.toString()??'active');
}

class AurenWalletService {
  final FirebaseFirestore db;
  AurenWalletService({FirebaseFirestore? firestore}):db=firestore??FirebaseFirestore.instance;
  DocumentReference<Map<String,dynamic>> _wallet(String uid)=>db.collection('wallets').doc(uid);
  CollectionReference<Map<String,dynamic>> _tx(String uid)=>_wallet(uid).collection('transactions');

  Stream<AurenWallet?> watch(String uid)=>_wallet(uid).snapshots().map((d)=>d.exists&&d.data()!=null?AurenWallet.fromMap(uid,d.data()!):null);
  Stream<List<Map<String,dynamic>>> watchTransactions(String uid)=>_tx(uid).orderBy('createdAt',descending:true).limit(100).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());

  Future<void> initialize({required String uid,required String currency})async{
    if(uid.trim().isEmpty)throw ArgumentError('المستخدم مطلوب');
    if(currency.trim().length!=3)throw ArgumentError('العملة يجب أن تكون ISO من 3 أحرف');
    final ref=_wallet(uid); final snap=await ref.get();
    if(snap.exists)return;
    await ref.set({'uid':uid,'currency':currency.trim().toUpperCase(),'balanceMinor':0,'status':'active','createdAt':FieldValue.serverTimestamp()});
  }

  Future<void> setSpendingLimit({required String uid,required int limitMinor})async{
    if(limitMinor<0)throw ArgumentError('الحد غير صالح');
    await _wallet(uid).update({'spendingLimitMinor':limitMinor,'updatedAt':FieldValue.serverTimestamp()});
  }
}
