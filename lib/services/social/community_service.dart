import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AurenCommunity {
  final String id, ownerId, name, description, topic, visibility;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  const AurenCommunity({required this.id,required this.ownerId,required this.name,required this.description,required this.topic,required this.visibility,required this.memberIds,required this.memberCount,required this.createdAt});
  factory AurenCommunity.fromDoc(DocumentSnapshot<Map<String,dynamic>> d){
    final m=d.data()??{};
    return AurenCommunity(id:d.id,ownerId:(m['ownerId']??'') as String,name:(m['name']??'') as String,description:(m['description']??'') as String,topic:(m['topic']??'') as String,visibility:(m['visibility']??'public') as String,memberIds:List<String>.from(m['memberIds']??const []),memberCount:(m['memberCount']??0) as int,createdAt:(m['createdAt'] as Timestamp?)?.toDate()??DateTime.fromMillisecondsSinceEpoch(0));
  }
}
class AurenCommunityService {
  final FirebaseFirestore _db; final FirebaseAuth _auth;
  AurenCommunityService({FirebaseFirestore? db,FirebaseAuth? auth}):_db=db??FirebaseFirestore.instance,_auth=auth??FirebaseAuth.instance;
  String get uid=>_auth.currentUser?.uid??(throw StateError('Sign in required'));
  Stream<List<AurenCommunity>> watchPublic({String query=''}){final q=query.trim().toLowerCase();return _db.collection('communities').where('visibility',isEqualTo:'public').orderBy('memberCount',descending:true).limit(50).snapshots().map((s){final all=s.docs.map(AurenCommunity.fromDoc);if(q.isEmpty)return all.toList();return all.where((c)=>(c.name+' '+c.description+' '+c.topic).toLowerCase().contains(q)).toList();});}
  Future<String> create({required String name,required String description,required String topic}) async{
    final n=name.trim(),d=description.trim(),t=topic.trim();if(n.isEmpty||n.length>80)throw ArgumentError('Community name must be 1–80 characters.');if(d.length>500||t.length>80)throw ArgumentError('Community text is too long.');
    final ref=_db.collection('communities').doc();await ref.set({'ownerId':uid,'name':n,'description':d,'topic':t,'visibility':'public','memberIds':[uid],'memberCount':1,'createdAt':FieldValue.serverTimestamp()});return ref.id;
  }
  Future<void> join(String id) async{final ref=_db.collection('communities').doc(id);await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)throw StateError('Community not found.');final data=snap.data()!;final members=List<String>.from(data['memberIds']??const []);if(members.contains(uid))return;if(members.length>=10000)throw StateError('Community is full.');members.add(uid);tx.update(ref,{'memberIds':members,'memberCount':members.length});});}
  Future<void> leave(String id) async{final ref=_db.collection('communities').doc(id);await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)return;final data=snap.data()!;if(data['ownerId']==uid)throw StateError('Owner cannot leave their community.');final members=List<String>.from(data['memberIds']??const []);if(!members.remove(uid))return;tx.update(ref,{'memberIds':members,'memberCount':members.length});});}
}
