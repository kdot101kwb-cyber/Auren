import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/agent_wallet.dart';
class AurenAgentWalletRepository {
 final FirebaseFirestore _db; AurenAgentWalletRepository({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;
 Stream<AurenAgentWallet?> watch(String uid)=>_db.collection('users').doc(uid).collection('wallet').doc('primary').snapshots().map((s)=>s.exists?AurenAgentWallet.fromMap(s.data()!):null);
 Stream<List<Map<String,dynamic>>> watchTransactions(String uid)=>_db.collection('users').doc(uid).collection('wallet_transactions').orderBy('createdAt',descending:true).limit(30).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
}
