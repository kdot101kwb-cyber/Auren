import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/agent_message.dart';
class AurenAgentMessageRepository {
 final FirebaseFirestore _db; AurenAgentMessageRepository({FirebaseFirestore? db}):_db=db??FirebaseFirestore.instance;
 Stream<List<Map<String,dynamic>>> watchInbox(String uid)=>_db.collection('agent_messages').where('recipientUid',isEqualTo:uid).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
 Stream<List<Map<String,dynamic>>> watchSent(String uid)=>_db.collection('agent_messages').where('senderUid',isEqualTo:uid).orderBy('createdAt',descending:true).limit(50).snapshots().map((s)=>s.docs.map((d)=>{'id':d.id,...d.data()}).toList());
}
